
from datetime import datetime, timezone

from sqlalchemy.orm import Session

from models.subject import Subject
from models.teacher_assignment import TeacherAssignment
from models.teacher_material import TeacherMaterial
from models.material_share import MaterialShare
from models.teacher_material_request import TeacherMaterialRequest
from models.user import User, UserAcademicPath
from schemas.teacher_material_request import TeacherMaterialRequestCreate, TeacherMaterialRequestResolve
from services.notification import create_notification


def utc_now():
    return datetime.now(timezone.utc)


def _current_academic_year():
    today = utc_now()
    return today.year if today.month >= 9 else today.year - 1


def _teachers_for_subject(db, subject_id):
    """Verified active teachers, for the current academic year when specified."""
    year = str(_current_academic_year())
    teachers = db.query(User).join(TeacherAssignment,
        TeacherAssignment.user_id == User.id).filter(
        TeacherAssignment.subject_id == subject_id,
        TeacherAssignment.verification_status == 'verified',
        TeacherAssignment.is_current.is_(True), User.is_active.is_(True),
        User.role == 'teacher').distinct().all()
    valid = []
    for teacher in teachers:
        assignments = [a for a in teacher.teacher_assignments if a.subject_id == subject_id
            and a.verification_status == 'verified' and a.is_current]
        if any(a.offering_id is None or (a.offering is not None
                and a.offering.is_active and (not a.offering.academic_year
                    or a.offering.academic_year.startswith(year))) for a in assignments):
            valid.append(teacher)
    return valid


def available_subjects(db, student):
    """Course subjects are selectable even when they do not yet have materials."""
    paths = db.query(UserAcademicPath).filter(UserAcademicPath.user_id == student.id,
        UserAcademicPath.status == 'enrolled').all()
    result = {}
    for path in paths:
        subjects = db.query(Subject).filter(Subject.is_active.is_(True),
            Subject.university_code == path.university_code,
            Subject.department_code == path.department_code,
            Subject.course_code == path.course_code).order_by(Subject.study_year, Subject.name).all()
        if not subjects:
            subjects = db.query(Subject).filter(Subject.is_active.is_(True),
                Subject.university == path.university,
                Subject.department == path.department,
                Subject.course == path.course).order_by(Subject.study_year, Subject.name).all()
        for subject in subjects:
            teachers = _teachers_for_subject(db, subject.id)
            result[subject.id] = {'subject_id': subject.id, 'subject_name': subject.name,
                'study_year': subject.study_year, 'university': subject.university,
                'department': subject.department, 'course': subject.course,
                'recipient_kind': 'teachers' if teachers else 'studentlab',
                'teachers': [{'id': t.id, 'name': f'{t.first_name} {t.last_name}'.strip()}
                    for t in teachers]}
    return sorted(result.values(), key=lambda x: (x['course'], x['study_year'] or 0, x['subject_name']))


def create_request(db:Session,student:User,data:TeacherMaterialRequestCreate):
    subject=db.query(Subject).filter(Subject.id==data.subject_id,Subject.is_active.is_(True)).first()
    if subject is None:
        raise ValueError("Materia non trovata.")
    if subject.id not in {row['subject_id'] for row in available_subjects(db, student)}:
        raise ValueError('Puoi richiedere materiale solo per una materia del tuo corso.')
    teachers = _teachers_for_subject(db, subject.id)
    teacher_id=data.teacher_user_id
    if teacher_id is not None:
        if teacher_id not in {teacher.id for teacher in teachers}:
            raise ValueError("Docente non disponibile per questa materia.")
    requested_kind = (data.recipient_kind or 'auto')
    if requested_kind == 'studentlab':
        if teacher_id is not None:
            raise ValueError("Una richiesta a StudentLab non può indicare un docente.")
        recipient_kind = 'studentlab'
    elif requested_kind == 'teachers':
        if not teachers:
            raise ValueError("Questa materia non ha docenti registrati: invia la richiesta a StudentLab.")
        recipient_kind = 'teachers'
    else:
        recipient_kind = 'teachers' if teachers else 'studentlab'
    record=TeacherMaterialRequest(student_user_id=student.id,subject_id=data.subject_id,teacher_user_id=teacher_id,recipient_kind=recipient_kind,topic=(data.topic.strip() if data.topic else None),message=data.message.strip(),status="pending")
    db.add(record)
    db.flush()
    target_ids=[teacher_id] if teacher_id is not None else [teacher.id for teacher in teachers]
    if recipient_kind == 'studentlab':
        target_ids=[row[0] for row in db.query(User.id).filter(User.role.in_(['admin', 'creator']),
            User.is_active.is_(True)).all()]
    # StudentLab receives every teacher request as a fallback, even while a teacher is working on it.
    if recipient_kind == 'teachers':
        admins=[row[0] for row in db.query(User.id).filter(
            User.role.in_(['admin','creator']), User.is_active.is_(True)).all()]
        target_ids=list(set(target_ids + admins))
    for target in target_ids:
        create_notification(db,user_id=target,notification_type="teacher_material_request",title="Nuova richiesta di materiale",message=f"Uno studente ha richiesto materiale per {subject.name}.",actor_user_id=student.id,resource_type="teacher_material_request",resource_id=record.id,action_type="teacher_material_request",action_resource_id=record.id,action_status="pending",commit=False)
    db.commit()
    db.refresh(record)
    return record


def resolve_request(db:Session,teacher:User,request_id:int,data:TeacherMaterialRequestResolve):
    record=db.query(TeacherMaterialRequest).filter(TeacherMaterialRequest.id==request_id).with_for_update().first()
    if record is None:
        raise ValueError("Richiesta non trovata.")
    if record.recipient_kind != 'teachers':
        raise PermissionError('La richiesta è indirizzata a StudentLab.')
    assignment=db.query(TeacherAssignment).filter(TeacherAssignment.user_id==teacher.id,TeacherAssignment.subject_id==record.subject_id,TeacherAssignment.verification_status=="verified",TeacherAssignment.is_current.is_(True)).first()
    if assignment is None:
        raise PermissionError("Non puoi gestire questa richiesta.")
    if record.teacher_user_id is not None and record.teacher_user_id != teacher.id:
        raise PermissionError("Questa richiesta è indirizzata a un altro docente.")
    if record.status!="pending":
        return record
    if record.teacher_declined_at is not None:
        raise PermissionError("StudentLab ha preso in carico questa richiesta.")
    if data.action=="fulfilled":
        if data.fulfilled_share_id is None:
            raise ValueError("Condividi privatamente il file con lo studente prima di soddisfare la richiesta.")
        share = db.query(MaterialShare).filter(
            MaterialShare.id == data.fulfilled_share_id,
            MaterialShare.sender_user_id == teacher.id,
            MaterialShare.recipient_user_id == record.student_user_id,
            MaterialShare.subject_id == record.subject_id,
            MaterialShare.status.in_(["pending", "accepted", "delivered"]),
        ).first()
        if share is None:
            raise ValueError("Questa condivisione privata non appartiene alla richiesta.")
        record.status="fulfilled"
        record.fulfilled_share_id=share.id
    else:
        record.teacher_declined_at=utc_now()
        record.updated_at=record.teacher_declined_at
        admin_ids=[row[0] for row in db.query(User.id).filter(
            User.role.in_(['admin','creator']), User.is_active.is_(True)).all()]
        for admin_id in admin_ids:
            create_notification(db,user_id=admin_id,notification_type="teacher_material_request",
                title="Richiesta da prendere in carico",message=f"Il docente non può fornire materiale per {record.subject.name}.",
                actor_user_id=teacher.id,resource_type="teacher_material_request",
                resource_id=record.id,commit=False)
        create_notification(db,user_id=record.student_user_id,
            notification_type="teacher_material_request_update",
            title="StudentLab sta seguendo la tua richiesta",
            message="Il docente non può fornire il materiale; StudentLab può intervenire per il tuo corso.",
            actor_user_id=teacher.id,resource_type="teacher_material_request",
            resource_id=record.id,commit=False)
        db.commit()
        db.refresh(record)
        return record
    record.resolved_by=teacher.id
    record.resolved_at=utc_now()
    record.updated_at=utc_now()
    create_notification(db,user_id=record.student_user_id,notification_type="teacher_material_request_resolved",title="Richiesta materiale aggiornata",message=("Il docente ha condiviso privatamente il materiale che avevi richiesto." if record.status=="fulfilled" else "La richiesta di materiale è stata chiusa dal docente."),actor_user_id=teacher.id,resource_type="teacher_material_request",resource_id=record.id,action_type=None,action_resource_id=None,action_status="none",commit=False)
    db.commit()
    db.refresh(record)
    return record


from datetime import datetime, timezone

from sqlalchemy.orm import Session

from models.subject import Subject
from models.teacher_assignment import TeacherAssignment
from models.teacher_material import TeacherMaterial
from models.teacher_material_request import TeacherMaterialRequest
from models.user import User
from schemas.teacher_material_request import TeacherMaterialRequestCreate, TeacherMaterialRequestResolve
from services.notification import create_notification


def utc_now():
    return datetime.now(timezone.utc)


def create_request(db:Session,student:User,data:TeacherMaterialRequestCreate):
    subject=db.query(Subject).filter(Subject.id==data.subject_id,Subject.is_active.is_(True)).first()
    if subject is None:
        raise ValueError("Materia non trovata.")
    teacher_id=data.teacher_user_id
    if teacher_id is not None:
        assignment=db.query(TeacherAssignment).filter(TeacherAssignment.user_id==teacher_id,TeacherAssignment.subject_id==data.subject_id,TeacherAssignment.verification_status=="verified",TeacherAssignment.is_current.is_(True)).first()
        if assignment is None:
            raise ValueError("Docente non disponibile per questa materia.")
    record=TeacherMaterialRequest(student_user_id=student.id,subject_id=data.subject_id,teacher_user_id=teacher_id,topic=(data.topic.strip() if data.topic else None),message=data.message.strip(),status="pending")
    db.add(record)
    db.flush()
    target_ids=[]
    if teacher_id is not None:
        target_ids=[teacher_id]
    else:
        target_ids=[row[0] for row in db.query(TeacherAssignment.user_id).filter(TeacherAssignment.subject_id==data.subject_id,TeacherAssignment.verification_status=="verified",TeacherAssignment.is_current.is_(True)).distinct().all()]
    for target in target_ids:
        create_notification(db,user_id=target,notification_type="teacher_material_request",title="Nuova richiesta di materiale",message=f"Uno studente ha richiesto materiale per {subject.name}.",actor_user_id=student.id,resource_type="teacher_material_request",resource_id=record.id,action_type="teacher_material_request",action_resource_id=record.id,action_status="pending",commit=False)
    db.commit()
    db.refresh(record)
    return record


def resolve_request(db:Session,teacher:User,request_id:int,data:TeacherMaterialRequestResolve):
    record=db.query(TeacherMaterialRequest).filter(TeacherMaterialRequest.id==request_id).first()
    if record is None:
        raise ValueError("Richiesta non trovata.")
    assignment=db.query(TeacherAssignment).filter(TeacherAssignment.user_id==teacher.id,TeacherAssignment.subject_id==record.subject_id,TeacherAssignment.verification_status=="verified",TeacherAssignment.is_current.is_(True)).first()
    if assignment is None:
        raise PermissionError("Non puoi gestire questa richiesta.")
    if record.teacher_user_id is not None and record.teacher_user_id != teacher.id:
        raise PermissionError("Questa richiesta è indirizzata a un altro docente.")
    if record.status!="pending":
        return record
    if data.action=="fulfilled":
        if data.fulfilled_material_id is None:
            raise ValueError("Seleziona il materiale pubblicato.")
        material=db.query(TeacherMaterial).filter(TeacherMaterial.id==data.fulfilled_material_id,TeacherMaterial.uploaded_by==teacher.id,TeacherMaterial.subject_id==record.subject_id,TeacherMaterial.status=="active").first()
        if material is None:
            raise ValueError("Materiale docente non trovato.")
        record.status="fulfilled"
        record.fulfilled_material_id=material.id
    else:
        record.status="rejected"
    record.resolved_by=teacher.id
    record.resolved_at=utc_now()
    record.updated_at=utc_now()
    create_notification(db,user_id=record.student_user_id,notification_type="teacher_material_request_resolved",title="Richiesta materiale aggiornata",message=("Il docente ha pubblicato un materiale per la tua richiesta." if record.status=="fulfilled" else "La richiesta di materiale è stata chiusa dal docente."),actor_user_id=teacher.id,resource_type="teacher_material_request",resource_id=record.id,action_type=None,action_resource_id=None,action_status="none",commit=False)
    db.commit()
    db.refresh(record)
    return record

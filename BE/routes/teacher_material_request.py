
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from core.database import get_db
from core.security import get_current_user, get_verified_teacher_user, get_admin_user
from models.teacher_material_request import TeacherMaterialRequest
from models.user import User
from schemas.teacher_material_request import TeacherMaterialRequestCreate, TeacherMaterialRequestResolve, TeacherMaterialRequestResponse
from services.teacher_material_request import create_request, resolve_request, available_subjects, utc_now
from services.notification import create_notification

router=APIRouter(prefix="/teacher-material-requests",tags=["teacher-material-requests"])


class StudentLabReply(BaseModel):
    message: str = Field(min_length=1, max_length=3000)
    action: str = Field(pattern='^(fulfilled|rejected)$')


@router.get('/options')
def options(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    return available_subjects(db, current_user)


@router.get('/studentlab')
def studentlab_inbox(current_user: User = Depends(get_admin_user), db: Session = Depends(get_db)):
    rows = db.query(TeacherMaterialRequest).filter(TeacherMaterialRequest.recipient_kind == 'studentlab').order_by(
        TeacherMaterialRequest.created_at.desc()).limit(200).all()
    return [{'id': row.id, 'student_user_id': row.student_user_id,
        'student_name': f'{row.student.first_name} {row.student.last_name}'.strip(),
        'subject_id': row.subject_id, 'subject_name': row.subject.name,
        'topic': row.topic, 'message': row.message, 'status': row.status,
        'staff_response': row.staff_response, 'created_at': row.created_at} for row in rows]


@router.post('/studentlab/{request_id}/reply', response_model=TeacherMaterialRequestResponse)
def studentlab_reply(request_id: int, data: StudentLabReply,
        current_user: User = Depends(get_admin_user), db: Session = Depends(get_db)):
    row = db.query(TeacherMaterialRequest).filter(TeacherMaterialRequest.id == request_id,
        TeacherMaterialRequest.recipient_kind == 'studentlab').with_for_update().first()
    if row is None:
        raise HTTPException(404, 'Richiesta StudentLab non trovata.')
    if row.status != 'pending':
        raise HTTPException(409, 'Questa richiesta è già stata gestita.')
    row.status = data.action
    row.staff_response = data.message.strip()
    row.resolved_by = current_user.id
    row.resolved_at = utc_now()
    row.updated_at = row.resolved_at
    create_notification(db, user_id=row.student_user_id,
        notification_type='teacher_material_request_resolved',
        title='Risposta alla richiesta di materiale', message=row.staff_response,
        actor_user_id=current_user.id, resource_type='teacher_material_request',
        resource_id=row.id, commit=False)
    db.commit()
    db.refresh(row)
    return row


@router.post("",response_model=TeacherMaterialRequestResponse)
def create(request:TeacherMaterialRequestCreate,current_user:User=Depends(get_current_user),db:Session=Depends(get_db)):
    try:
        return create_request(db,current_user,request)
    except ValueError as exc:
        raise HTTPException(status_code=400,detail=str(exc))


@router.get("/mine",response_model=list[TeacherMaterialRequestResponse])
def mine(current_user:User=Depends(get_current_user),db:Session=Depends(get_db)):
    return db.query(TeacherMaterialRequest).filter(TeacherMaterialRequest.student_user_id==current_user.id).order_by(TeacherMaterialRequest.created_at.desc()).all()


@router.get("/teacher",response_model=list[TeacherMaterialRequestResponse])
def teacher(current_user:User=Depends(get_verified_teacher_user),db:Session=Depends(get_db)):
    from models.teacher_assignment import TeacherAssignment
    subject_ids=[row[0] for row in db.query(TeacherAssignment.subject_id).filter(TeacherAssignment.user_id==current_user.id,TeacherAssignment.verification_status=="verified",TeacherAssignment.is_current.is_(True)).all()]
    return db.query(TeacherMaterialRequest).filter(TeacherMaterialRequest.subject_id.in_(subject_ids),
        TeacherMaterialRequest.recipient_kind == 'teachers',
        (TeacherMaterialRequest.teacher_user_id.is_(None) | (TeacherMaterialRequest.teacher_user_id == current_user.id))).order_by(TeacherMaterialRequest.created_at.desc()).all() if subject_ids else []


@router.post("/{request_id}/cancel",response_model=TeacherMaterialRequestResponse)
def cancel(request_id:int,current_user:User=Depends(get_current_user),db:Session=Depends(get_db)):
    record=db.query(TeacherMaterialRequest).filter(TeacherMaterialRequest.id==request_id,TeacherMaterialRequest.student_user_id==current_user.id).first()
    if record is None:
        raise HTTPException(status_code=404,detail="Richiesta non trovata.")
    if record.status!="pending":
        raise HTTPException(status_code=400,detail="Puoi annullare solo una richiesta ancora in attesa.")
    from datetime import datetime, timezone
    record.status="cancelled"
    record.resolved_at=datetime.now(timezone.utc)
    record.updated_at=record.resolved_at
    db.commit()
    db.refresh(record)
    return record


@router.post("/{request_id}/resolve",response_model=TeacherMaterialRequestResponse)
def resolve(request_id:int,request:TeacherMaterialRequestResolve,current_user:User=Depends(get_verified_teacher_user),db:Session=Depends(get_db)):
    try:
        return resolve_request(db,current_user,request_id,request)
    except PermissionError as exc:
        raise HTTPException(status_code=403,detail=str(exc))
    except ValueError as exc:
        raise HTTPException(status_code=400,detail=str(exc))

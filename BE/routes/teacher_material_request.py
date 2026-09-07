
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from core.database import get_db
from core.security import get_current_user, get_verified_teacher_user
from models.teacher_material_request import TeacherMaterialRequest
from models.user import User
from schemas.teacher_material_request import TeacherMaterialRequestCreate, TeacherMaterialRequestResolve, TeacherMaterialRequestResponse
from services.teacher_material_request import create_request, resolve_request

router=APIRouter(prefix="/teacher-material-requests",tags=["teacher-material-requests"])


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
    return db.query(TeacherMaterialRequest).filter(TeacherMaterialRequest.subject_id.in_(subject_ids)).order_by(TeacherMaterialRequest.created_at.desc()).all() if subject_ids else []


@router.post("/{request_id}/resolve",response_model=TeacherMaterialRequestResponse)
def resolve(request_id:int,request:TeacherMaterialRequestResolve,current_user:User=Depends(get_verified_teacher_user),db:Session=Depends(get_db)):
    try:
        return resolve_request(db,current_user,request_id,request)
    except PermissionError as exc:
        raise HTTPException(status_code=403,detail=str(exc))
    except ValueError as exc:
        raise HTTPException(status_code=400,detail=str(exc))

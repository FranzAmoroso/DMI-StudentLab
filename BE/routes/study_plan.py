from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from core.database import get_db
from core.security import get_current_user
from models.user import User
from schemas.study_plan import (
    StudyPlanAssociationRequest,
    StudyPlanBootstrapResponse,
    StudyPlanSyncRequest,
    StudyPlanSyncResponse,
)
from services.study_plan_service import (
    get_study_plan_bootstrap,
    set_session_contribution_enabled,
    sync_study_plan,
)


router = APIRouter(prefix="/study-plan", tags=["study-plan"])


@router.get("/bootstrap", response_model=StudyPlanBootstrapResponse)
def api_study_plan_bootstrap(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return get_study_plan_bootstrap(db, current_user)


@router.post("/sync", response_model=StudyPlanSyncResponse)
def api_study_plan_sync(
    request: StudyPlanSyncRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    try:
        return sync_study_plan(db, current_user, request)
    except PermissionError as exc:
        db.rollback()
        raise HTTPException(status_code=403, detail=str(exc))
    except ValueError as exc:
        db.rollback()
        raise HTTPException(status_code=400, detail=str(exc))
    except Exception:
        db.rollback()
        raise HTTPException(status_code=500, detail="Non è stato possibile sincronizzare il piano di ripasso.")


@router.patch(
    "/sessions/{session_uuid}/association",
    response_model=StudyPlanBootstrapResponse,
)
def api_study_plan_session_association(
    session_uuid: str,
    request: StudyPlanAssociationRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    try:
        return set_session_contribution_enabled(
            db,
            current_user,
            session_uuid.strip(),
            request.contribution_enabled,
        )
    except ValueError as exc:
        db.rollback()
        raise HTTPException(status_code=404, detail=str(exc))

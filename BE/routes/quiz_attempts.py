from fastapi import (
    APIRouter,
    Depends,
    HTTPException,
    Query,
    status,
)

from sqlalchemy.orm import Session

from core.database import get_db
from core.security import get_current_user

from models.quiz_attempt import QuizAttempt
from models.user import User

from schemas.quiz_attempt import (
    QuizAttemptDetailResponse,
    QuizAttemptHistoryResponse,
    QuizAttemptResponse,
    QuizAttemptStart,
    QuizAttemptStartResponse,
    QuizAttemptSubmit,
)

from services.quiz_attempt_service import (
    complete_quiz_attempt,
    delete_quiz_attempt,
    get_quiz_attempt_by_id,
    get_student_quiz_history,
    hide_quiz_attempt_from_history,
    restore_quiz_attempt_to_history,
    start_assigned_quiz_attempt,
    start_quiz_attempt,
)


router = APIRouter(
    prefix="/quiz-attempts",
    tags=[
        "quiz-attempts",
    ],
)


def _raise_service_error(
    exception: Exception,
):
    if isinstance(
        exception,
        PermissionError,
    ):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=str(
                exception
            ),
        ) from exception

    message = str(
        exception
    )

    lowered_message = (
        message.lower()
    )

    if (
        "non trovato"
        in lowered_message
        or "non trovata"
        in lowered_message
    ):
        status_code = (
            status.HTTP_404_NOT_FOUND
        )

    elif (
        "non puoi"
        in lowered_message
        or "non autorizzato"
        in lowered_message
    ):
        status_code = (
            status.HTTP_403_FORBIDDEN
        )

    else:
        status_code = (
            status.HTTP_400_BAD_REQUEST
        )

    raise HTTPException(
        status_code=status_code,
        detail=message,
    ) from exception


def _require_attempt_access(
    attempt: QuizAttempt | None,
    current_user: User,
) -> QuizAttempt:
    if (
        attempt is None
        or attempt.is_deleted
    ):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Tentativo non trovato.",
        )

    if (
        attempt.user_id
        != current_user.id
        and current_user.role
        not in {
            "admin",
            "creator",
        }
    ):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Non puoi visualizzare questo tentativo.",
        )

    return attempt


def _require_attempt_owner(
    attempt: QuizAttempt | None,
    current_user: User,
) -> QuizAttempt:
    if (
        attempt is None
        or attempt.is_deleted
    ):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Tentativo non trovato.",
        )

    if (
        attempt.user_id
        != current_user.id
    ):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Non puoi modificare questo tentativo.",
        )

    return attempt


@router.post(
    "/start",
    response_model=QuizAttemptStartResponse,
    status_code=status.HTTP_201_CREATED,
)
def api_start_quiz_attempt(
    request: QuizAttemptStart,
    current_user: User = Depends(
        get_current_user,
    ),
    db: Session = Depends(
        get_db,
    ),
):
    try:
        return start_quiz_attempt(
            db,
            current_user,
            request,
        )

    except (
        ValueError,
        PermissionError,
    ) as exception:
        _raise_service_error(
            exception
        )


@router.post(
    "/assignments/{assignment_id}/start",
    response_model=QuizAttemptStartResponse,
    status_code=status.HTTP_201_CREATED,
)
def api_start_assigned_quiz_attempt(
    assignment_id: int,
    current_user: User = Depends(
        get_current_user,
    ),
    db: Session = Depends(
        get_db,
    ),
):
    if assignment_id <= 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Assegnazione non valida.",
        )

    try:
        return start_assigned_quiz_attempt(
            db,
            current_user,
            assignment_id,
        )

    except (
        ValueError,
        PermissionError,
    ) as exception:
        _raise_service_error(
            exception
        )


@router.post(
    "/{attempt_id}/complete",
    response_model=QuizAttemptDetailResponse,
)
def api_complete_quiz_attempt(
    attempt_id: int,
    request: QuizAttemptSubmit,
    current_user: User = Depends(
        get_current_user,
    ),
    db: Session = Depends(
        get_db,
    ),
):
    if attempt_id <= 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Tentativo non valido.",
        )

    try:
        return complete_quiz_attempt(
            db,
            current_user,
            attempt_id,
            request,
        )

    except (
        ValueError,
        PermissionError,
    ) as exception:
        _raise_service_error(
            exception
        )


@router.get(
    "/me",
    response_model=QuizAttemptHistoryResponse,
)
def api_get_my_quiz_history(
    include_hidden: bool = Query(
        default=False,
    ),
    limit: int = Query(
        default=50,
        ge=1,
        le=100,
    ),
    offset: int = Query(
        default=0,
        ge=0,
    ),
    current_user: User = Depends(
        get_current_user,
    ),
    db: Session = Depends(
        get_db,
    ),
):
    return get_student_quiz_history(
        db,
        current_user.id,
        include_hidden=include_hidden,
        limit=limit,
        offset=offset,
    )


@router.get(
    "/{attempt_id}",
    response_model=QuizAttemptDetailResponse,
)
def api_get_quiz_attempt(
    attempt_id: int,
    current_user: User = Depends(
        get_current_user,
    ),
    db: Session = Depends(
        get_db,
    ),
):
    if attempt_id <= 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Tentativo non valido.",
        )

    attempt = get_quiz_attempt_by_id(
        db,
        attempt_id,
    )

    return _require_attempt_access(
        attempt,
        current_user,
    )


@router.post(
    "/{attempt_id}/hide",
    response_model=QuizAttemptResponse,
)
def api_hide_quiz_attempt(
    attempt_id: int,
    current_user: User = Depends(
        get_current_user,
    ),
    db: Session = Depends(
        get_db,
    ),
):
    if attempt_id <= 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Tentativo non valido.",
        )

    attempt = _require_attempt_owner(
        get_quiz_attempt_by_id(
            db,
            attempt_id,
        ),
        current_user,
    )

    if (
        attempt.status
        != "completed"
    ):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=(
                "Puoi nascondere dallo storico solo un quiz completato."
            ),
        )

    try:
        return hide_quiz_attempt_from_history(
            db,
            attempt,
            current_user,
        )

    except (
        ValueError,
        PermissionError,
    ) as exception:
        _raise_service_error(
            exception
        )


@router.post(
    "/{attempt_id}/restore",
    response_model=QuizAttemptResponse,
)
def api_restore_quiz_attempt(
    attempt_id: int,
    current_user: User = Depends(
        get_current_user,
    ),
    db: Session = Depends(
        get_db,
    ),
):
    if attempt_id <= 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Tentativo non valido.",
        )

    attempt = _require_attempt_owner(
        get_quiz_attempt_by_id(
            db,
            attempt_id,
        ),
        current_user,
    )

    if (
        attempt.status
        != "completed"
    ):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=(
                "Puoi ripristinare nello storico solo un quiz completato."
            ),
        )

    try:
        return restore_quiz_attempt_to_history(
            db,
            attempt,
        )

    except (
        ValueError,
        PermissionError,
    ) as exception:
        _raise_service_error(
            exception
        )


@router.delete(
    "/{attempt_id}",
    response_model=QuizAttemptResponse,
)
def api_delete_quiz_attempt(
    attempt_id: int,
    current_user: User = Depends(
        get_current_user,
    ),
    db: Session = Depends(
        get_db,
    ),
):
    if attempt_id <= 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Tentativo non valido.",
        )

    attempt = _require_attempt_owner(
        get_quiz_attempt_by_id(
            db,
            attempt_id,
        ),
        current_user,
    )

    try:
        return delete_quiz_attempt(
            db,
            attempt,
            current_user,
        )

    except (
        ValueError,
        PermissionError,
    ) as exception:
        _raise_service_error(
            exception
        )
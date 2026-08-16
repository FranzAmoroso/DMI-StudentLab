from fastapi import (
    Depends,
    HTTPException,
)

from fastapi.security import (
    HTTPAuthorizationCredentials,
    HTTPBearer,
)

from sqlalchemy.orm import Session

from core.database import get_db
from core.config import settings

from models.user import User

from services.auth import (
    decode_access_token,
)

from services.user import (
    get_user_by_id,
)


security = HTTPBearer()


def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(
        security,
    ),
    db: Session = Depends(
        get_db,
    ),
) -> User:

    user_id = decode_access_token(
        token=credentials.credentials,
        secret_key=settings.secret_key,
    )

    if user_id is None:
        raise HTTPException(
            status_code=401,
            detail="Token non valido o scaduto.",
        )

    user = get_user_by_id(
        db,
        user_id,
    )

    if user is None:
        raise HTTPException(
            status_code=401,
            detail="Utente non trovato.",
        )

    if not user.is_active:
        raise HTTPException(
            status_code=403,
            detail="Utente non attivo.",
        )

    return user
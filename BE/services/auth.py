from datetime import (
    datetime,
    timedelta,
    timezone,
)

from jose import (
    JWTError,
    jwt,
)

from pwdlib import PasswordHash

from sqlalchemy.orm import Session

from models.user import User


password_hash = (
    PasswordHash.recommended()
)


ALGORITHM = "HS256"


def hash_password(
    password: str,
) -> str:
    return password_hash.hash(
        password,
    )


def verify_password(
    plain_password: str,
    hashed_password: str,
) -> bool:
    return password_hash.verify(
        plain_password,
        hashed_password,
    )


def authenticate_user(
    db: Session,
    email: str,
    password: str,
):
    normalized_email = (
        email
        .strip()
        .lower()
    )

    user = (
        db.query(
            User,
        )
        .filter(
            User.email ==
            normalized_email,
        )
        .first()
    )

    if user is None:
        return None

    if not user.is_active:
        return None

    if not user.password_hash:
        return None

    if not verify_password(
        password,
        user.password_hash,
    ):
        return None

    return user


def create_access_token(
    *,
    user_id: int,
    secret_key: str,
    expires_minutes: int = 60 * 24 * 7,
) -> str:
    now = datetime.now(
        timezone.utc,
    )

    expire = (
        now
        + timedelta(
            minutes=expires_minutes,
        )
    )

    payload = {
        "sub":
            str(
                user_id,
            ),

        "iat":
            now,

        "exp":
            expire,
    }

    return jwt.encode(
        payload,
        secret_key,
        algorithm=ALGORITHM,
    )


def decode_access_token(
    *,
    token: str,
    secret_key: str,
) -> int | None:
    try:
        payload = jwt.decode(
            token,
            secret_key,
            algorithms=[
                ALGORITHM,
            ],
        )

        subject = payload.get(
            "sub",
        )

        if subject is None:
            return None

        return int(
            subject,
        )

    except (
        JWTError,
        ValueError,
        TypeError,
    ):
        return None
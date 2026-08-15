from sqlalchemy.orm import (
    Session,
    joinedload,
)

from models.user import User
from models.subject import UserSubject

from schemas.user import (
    UserCreate,
    UserUpdate,
)

from schemas.subject import (
    UserSubjectCreate,
)


# =============================================================================
# CREA UTENTE
# =============================================================================

def create_user(
    db: Session,
    data: UserCreate,
):
    user = User(
        first_name=data.first_name,
        last_name=data.last_name,
        email=data.email,
        department=data.department,
        course=data.course,
        description=data.description,
        role=data.role,
        available=data.available,
        willing_to_teach=data.willing_to_teach,
    )

    db.add(user)

    db.commit()

    db.refresh(user)

    return user


# =============================================================================
# TUTTI GLI UTENTI
# =============================================================================

def get_users(
    db: Session,
):
    return (
        db.query(User)
        .options(
            joinedload(
                User.subjects
            ).joinedload(
                UserSubject.subject
            )
        )
        .all()
    )


# =============================================================================
# UTENTE PER ID
# =============================================================================

def get_user_by_id(
    db: Session,
    user_id: int,
):
    return (
        db.query(User)
        .options(
            joinedload(
                User.subjects
            ).joinedload(
                UserSubject.subject
            )
        )
        .filter(
            User.id == user_id
        )
        .first()
    )


# =============================================================================
# UTENTE PER EMAIL
# =============================================================================

def get_user_by_email(
    db: Session,
    email: str,
):
    return (
        db.query(User)
        .filter(
            User.email == email
        )
        .first()
    )


# =============================================================================
# MODIFICA UTENTE
# =============================================================================

def update_user(
    db: Session,
    user: User,
    data: UserUpdate,
):
    update_data = data.model_dump(
        exclude_unset=True,
    )

    for field, value in update_data.items():
        setattr(
            user,
            field,
            value,
        )

    db.commit()

    db.refresh(user)

    return get_user_by_id(
        db,
        user.id,
    )


# =============================================================================
# AGGIUNGI MATERIA
# =============================================================================

def add_subject_to_user(
    db: Session,
    user_id: int,
    data: UserSubjectCreate,
):
    user_subject = UserSubject(
        user_id=user_id,
        subject_id=data.subject_id,
        grade=data.grade,
        note=data.note,
        can_help=data.can_help,
    )

    db.add(user_subject)

    db.commit()

    db.refresh(user_subject)

    return user_subject


# =============================================================================
# CERCA COLLEGAMENTO UTENTE/MATERIA
# =============================================================================

def get_user_subject(
    db: Session,
    user_id: int,
    subject_id: int,
):
    return (
        db.query(UserSubject)
        .filter(
            UserSubject.user_id == user_id,
            UserSubject.subject_id == subject_id,
        )
        .first()
    )


# =============================================================================
# RIMUOVI MATERIA
# =============================================================================

def remove_subject_from_user(
    db: Session,
    user_subject: UserSubject,
):
    db.delete(
        user_subject,
    )

    db.commit()
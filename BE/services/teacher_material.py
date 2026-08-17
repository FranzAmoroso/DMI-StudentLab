import uuid

from sqlalchemy.orm import Session

from models.subject import Subject

from models.teacher_material import (
    TeacherMaterial,
)

from models.user import User

from schemas.teacher_material import (
    TeacherMaterialCompleteRequest,
    TeacherMaterialUpdate,
)

from services.teacher_assignment import (
    get_verified_teacher_assignment,
)


MAX_TEACHER_MATERIAL_SIZE = (
    250 *
    1024 *
    1024
)


ALLOWED_TEACHER_MATERIAL_VISIBILITY = {
    "students",
    "private",
}


ALLOWED_TEACHER_MIME_TYPES = {
    "application/pdf",
    "application/zip",
    "application/x-zip-compressed",
    "application/msword",
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
    "application/vnd.ms-powerpoint",
    "application/vnd.openxmlformats-officedocument.presentationml.presentation",
    "application/vnd.ms-excel",
    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
    "text/plain",
    "text/csv",
    "image/jpeg",
    "image/png",
    "image/webp",
}


def require_teacher_subject(
    db: Session,
    teacher_id: int,
    subject_id: int,
):
    subject = (
        db.query(
            Subject,
        )
        .filter(
            Subject.id ==
            subject_id,
        )
        .first()
    )

    if subject is None:
        raise ValueError(
            "Materia non trovata.",
        )

    assignment = (
        get_verified_teacher_assignment(
            db,
            teacher_id,
            subject_id,
        )
    )

    if assignment is None:
        raise PermissionError(
            "Il docente non possiede un insegnamento verificato per questa materia.",
        )

    return subject


def validate_teacher_material_size(
    size: int,
):
    if size <= 0:
        raise ValueError(
            "Il file è vuoto.",
        )

    if (
        size >
        MAX_TEACHER_MATERIAL_SIZE
    ):
        raise ValueError(
            "Il file supera la dimensione massima consentita di 250 MB.",
        )


def validate_teacher_material_mime_type(
    mime_type: str,
):
    value = (
        mime_type
        .strip()
        .lower()
    )

    if (
        value not in
        ALLOWED_TEACHER_MIME_TYPES
    ):
        raise ValueError(
            "Tipo di file non consentito.",
        )


def generate_teacher_material_stored_name(
    teacher_id: int,
    subject_id: int,
    original_name: str,
):
    safe_name = (
        original_name
        .strip()
        .replace(
            "/",
            "_",
        )
        .replace(
            "\\",
            "_",
        )
    )

    unique_id = (
        uuid.uuid4()
        .hex
    )

    return (
        f"teacher-materials/"
        f"{teacher_id}/"
        f"{subject_id}/"
        f"{unique_id}-"
        f"{safe_name}"
    )


def ensure_teacher_material_not_duplicate(
    db: Session,
    teacher_id: int,
    subject_id: int,
    file_hash: str | None,
):
    if not file_hash:
        return

    normalized_hash = (
        file_hash
        .strip()
        .lower()
    )

    material = (
        db.query(
            TeacherMaterial,
        )
        .filter(
            TeacherMaterial.uploaded_by ==
            teacher_id,
            TeacherMaterial.subject_id ==
            subject_id,
            TeacherMaterial.file_hash ==
            normalized_hash,
        )
        .first()
    )

    if material is not None:
        raise ValueError(
            "Questo file è già presente per questa materia.",
        )


def create_teacher_material(
    db: Session,
    teacher: User,
    request: TeacherMaterialCompleteRequest,
):
    require_teacher_subject(
        db,
        teacher.id,
        request.subject_id,
    )

    validate_teacher_material_size(
        request.size,
    )

    validate_teacher_material_mime_type(
        request.mime_type,
    )

    ensure_teacher_material_not_duplicate(
        db,
        teacher.id,
        request.subject_id,
        request.file_hash,
    )

    visibility = (
        request.visibility
        .strip()
        .lower()
    )

    if (
        visibility not in
        ALLOWED_TEACHER_MATERIAL_VISIBILITY
    ):
        raise ValueError(
            "Visibilità materiale non valida.",
        )

    material = TeacherMaterial(
        subject_id=request.subject_id,
        uploaded_by=teacher.id,
        title=request.title.strip(),
        description=request.description.strip(),
        original_name=request.original_name.strip(),
        stored_name=request.stored_name.strip(),
        file_path=request.file_path.strip(),
        mime_type=request.mime_type.strip(),
        size=request.size,
        file_hash=(
            request.file_hash
            .strip()
            .lower()
            if request.file_hash
            else None
        ),
        visibility=visibility,
        is_active=True,
    )

    db.add(
        material,
    )

    db.commit()

    db.refresh(
        material,
    )

    return material


def get_teacher_materials(
    db: Session,
    teacher_id: int,
):
    return (
        db.query(
            TeacherMaterial,
        )
        .filter(
            TeacherMaterial.uploaded_by ==
            teacher_id,
        )
        .order_by(
            TeacherMaterial.created_at
            .desc(),
        )
        .all()
    )


def get_teacher_material_by_id(
    db: Session,
    material_id: int,
):
    return (
        db.query(
            TeacherMaterial,
        )
        .filter(
            TeacherMaterial.id ==
            material_id,
        )
        .first()
    )


def require_teacher_material_owner(
    material: TeacherMaterial,
    teacher_id: int,
):
    if (
        material.uploaded_by !=
        teacher_id
    ):
        raise PermissionError(
            "Non puoi gestire questo materiale.",
        )

    return material


def update_teacher_material(
    db: Session,
    material: TeacherMaterial,
    teacher: User,
    request: TeacherMaterialUpdate,
):
    require_teacher_material_owner(
        material,
        teacher.id,
    )

    values = request.model_dump(
        exclude_unset=True,
    )

    if (
        "title" in values and
        values["title"] is not None
    ):
        values["title"] = (
            values["title"]
            .strip()
        )

    if (
        "description" in values and
        values["description"] is not None
    ):
        values["description"] = (
            values["description"]
            .strip()
        )

    if (
        "visibility" in values and
        values["visibility"] is not None
    ):
        visibility = (
            values["visibility"]
            .strip()
            .lower()
        )

        if (
            visibility not in
            ALLOWED_TEACHER_MATERIAL_VISIBILITY
        ):
            raise ValueError(
                "Visibilità materiale non valida.",
            )

        values["visibility"] = (
            visibility
        )

    for key, value in (
        values.items()
    ):
        setattr(
            material,
            key,
            value,
        )

    db.commit()

    db.refresh(
        material,
    )

    return material


def delete_teacher_material(
    db: Session,
    material: TeacherMaterial,
    teacher: User,
):
    require_teacher_material_owner(
        material,
        teacher.id,
    )

    db.delete(
        material,
    )

    db.commit()


def get_student_teacher_materials(
    db: Session,
    subject_id: int,
):
    return (
        db.query(
            TeacherMaterial,
        )
        .join(
            User,
            User.id ==
            TeacherMaterial.uploaded_by,
        )
        .filter(
            TeacherMaterial.subject_id ==
            subject_id,
            TeacherMaterial.visibility ==
            "students",
            TeacherMaterial.is_active.is_(
                True,
            ),
            User.role ==
            "teacher",
            User.teacher_verification_status ==
            "verified",
            User.is_active.is_(
                True,
            ),
        )
        .order_by(
            TeacherMaterial.created_at
            .desc(),
        )
        .all()
    )
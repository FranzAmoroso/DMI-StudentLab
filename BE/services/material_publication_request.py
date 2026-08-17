from datetime import (
    datetime,
    timezone,
)

from sqlalchemy.orm import (
    Session,
)

from models.material_publication_request import (
    MaterialPublicationRequest,
)

from models.public_material import (
    PublicMaterial,
)

from models.subject import (
    Subject,
)

from models.user import (
    User,
)

from schemas.material_publication_request import (
    MaterialPublicationApproveRequest,
    MaterialPublicationCompleteRequest,
    MaterialPublicationRejectRequest,
    MaterialDuplicateReviewRequest,
)


MAX_PUBLIC_MATERIAL_SIZE = (
    250
    * 1024
    * 1024
)


ALLOWED_PUBLIC_MATERIAL_MIME_TYPES = {
    "application/pdf",
    "text/plain",
    "application/msword",
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
    "application/vnd.ms-powerpoint",
    "application/vnd.openxmlformats-officedocument.presentationml.presentation",
}


def validate_publication_material_size(
    size: int,
):
    if size <= 0:
        raise ValueError(
            "Dimensione del file non valida.",
        )

    if size > MAX_PUBLIC_MATERIAL_SIZE:
        raise ValueError(
            "Il file supera la dimensione massima consentita.",
        )


def validate_publication_material_mime_type(
    mime_type: str,
):
    normalized_mime_type = (
        mime_type
        .strip()
        .lower()
    )

    if (
        normalized_mime_type
        not in
        ALLOWED_PUBLIC_MATERIAL_MIME_TYPES
    ):
        raise ValueError(
            "Tipo di file non supportato.",
        )


def get_publication_request_by_id(
    db: Session,
    request_id: int,
):
    return (
        db.query(
            MaterialPublicationRequest,
        )
        .filter(
            MaterialPublicationRequest.id ==
            request_id,
        )
        .first()
    )


def get_user_publication_requests(
    db: Session,
    user_id: int,
):
    return (
        db.query(
            MaterialPublicationRequest,
        )
        .filter(
            MaterialPublicationRequest.user_id ==
            user_id,
        )
        .order_by(
            MaterialPublicationRequest.created_at.desc(),
        )
        .all()
    )


def get_pending_publication_requests(
    db: Session,
):
    return (
        db.query(
            MaterialPublicationRequest,
        )
        .filter(
            MaterialPublicationRequest.status ==
            "pending",
        )
        .order_by(
            MaterialPublicationRequest.created_at.asc(),
        )
        .all()
    )


def get_publication_requests(
    db: Session,
    status: str | None = None,
):
    query = db.query(
        MaterialPublicationRequest,
    )

    if status is not None:
        query = query.filter(
            MaterialPublicationRequest.status ==
            status,
        )

    return (
        query
        .order_by(
            MaterialPublicationRequest.created_at.desc(),
        )
        .all()
    )


def get_subject_for_publication(
    db: Session,
    subject_id: int,
):
    return (
        db.query(
            Subject,
        )
        .filter(
            Subject.id ==
            subject_id,
            Subject.is_active.is_(
                True,
            ),
        )
        .first()
    )


def find_exact_public_material_duplicate(
    db: Session,
    *,
    subject_id: int,
    file_hash: str,
):
    return (
        db.query(
            PublicMaterial,
        )
        .filter(
            PublicMaterial.subject_id ==
            subject_id,
            PublicMaterial.file_hash ==
            file_hash,
            PublicMaterial.status ==
            "published",
        )
        .order_by(
            PublicMaterial.id.asc(),
        )
        .first()
    )


def find_possible_public_material_duplicate(
    db: Session,
    *,
    subject_id: int,
    original_name: str,
    size: int,
):
    normalized_name = (
        original_name
        .strip()
        .lower()
    )

    materials = (
        db.query(
            PublicMaterial,
        )
        .filter(
            PublicMaterial.subject_id ==
            subject_id,
            PublicMaterial.status ==
            "published",
        )
        .order_by(
            PublicMaterial.created_at.desc(),
        )
        .all()
    )

    for material in materials:
        material_name = (
            material.original_name
            .strip()
            .lower()
        )

        if (
            material_name ==
            normalized_name
        ):
            return material

        if material.size == size:
            return material

    return None


def find_duplicate_candidate(
    db: Session,
    *,
    subject_id: int,
    original_name: str,
    size: int,
    file_hash: str,
):
    exact_duplicate = (
        find_exact_public_material_duplicate(
            db,
            subject_id=subject_id,
            file_hash=file_hash,
        )
    )

    if exact_duplicate is not None:
        return exact_duplicate

    return (
        find_possible_public_material_duplicate(
            db,
            subject_id=subject_id,
            original_name=original_name,
            size=size,
        )
    )


def create_material_publication_request(
    db: Session,
    *,
    current_user: User,
    data: MaterialPublicationCompleteRequest,
):
    if not current_user.is_active:
        raise PermissionError(
            "Account non attivo.",
        )

    subject = get_subject_for_publication(
        db,
        data.subject_id,
    )

    if subject is None:
        raise ValueError(
            "Materia non trovata.",
        )

    validate_publication_material_size(
        data.size,
    )

    validate_publication_material_mime_type(
        data.mime_type,
    )

    duplicate = find_duplicate_candidate(
        db,
        subject_id=subject.id,
        original_name=(
            data.original_name
        ),
        size=data.size,
        file_hash=(
            data.file_hash
            .lower()
        ),
    )

    duplicate_status = "none"

    possible_duplicate_material_id = None

    if duplicate is not None:
        duplicate_status = (
            "suspected"
        )

        possible_duplicate_material_id = (
            duplicate.id
        )

    publication_request = (
        MaterialPublicationRequest(
            user_id=(
                current_user.id
            ),
            subject_id=(
                subject.id
            ),
            university=(
                subject.university
            ),
            university_code=(
                subject.university_code
            ),
            department=(
                subject.department
            ),
            department_code=(
                subject.department_code
            ),
            course=(
                subject.course
            ),
            course_code=(
                subject.course_code
            ),
            title=(
                data.title
                .strip()
            ),
            description=(
                data.description
                .strip()
                if data.description
                is not None
                else None
            ),
            original_name=(
                data.original_name
                .strip()
            ),
            stored_name=(
                data.stored_name
                .strip()
            ),
            file_path=(
                data.file_path
                .strip()
            ),
            mime_type=(
                data.mime_type
                .strip()
                .lower()
            ),
            size=(
                data.size
            ),
            file_hash=(
                data.file_hash
                .lower()
            ),
            status="pending",
            duplicate_status=(
                duplicate_status
            ),
            possible_duplicate_material_id=(
                possible_duplicate_material_id
            ),
            reviewed_by=None,
            reviewed_at=None,
            rejection_reason=None,
            admin_note=None,
        )
    )

    try:
        db.add(
            publication_request,
        )

        db.commit()

        db.refresh(
            publication_request,
        )

        return publication_request

    except Exception:
        db.rollback()
        raise


def review_material_duplicate(
    db: Session,
    *,
    publication_request:
        MaterialPublicationRequest,
    current_admin: User,
    data: MaterialDuplicateReviewRequest,
):
    if (
        publication_request.status !=
        "pending"
    ):
        raise ValueError(
            "La richiesta è già stata elaborata.",
        )

    if (
        data.duplicate_status ==
        "confirmed"
    ):
        if (
            publication_request.possible_duplicate_material_id
            is None
        ):
            raise ValueError(
                "Nessun possibile duplicato associato alla richiesta.",
            )

        publication_request.duplicate_status = (
            "confirmed"
        )

    else:
        publication_request.duplicate_status = (
            "not_duplicate"
        )

        publication_request.possible_duplicate_material_id = (
            None
        )

    publication_request.reviewed_by = (
        current_admin.id
    )

    publication_request.reviewed_at = (
        datetime.now(
            timezone.utc,
        )
    )

    publication_request.admin_note = (
        data.admin_note.strip()
        if data.admin_note
        is not None
        else None
    )

    try:
        db.commit()

        db.refresh(
            publication_request,
        )

        return publication_request

    except Exception:
        db.rollback()
        raise


def approve_material_publication_request(
    db: Session,
    *,
    publication_request:
        MaterialPublicationRequest,
    current_admin: User,
    data: MaterialPublicationApproveRequest,
):
    if (
        publication_request.status !=
        "pending"
    ):
        raise ValueError(
            "La richiesta è già stata elaborata.",
        )

    if (
        publication_request.duplicate_status ==
        "confirmed"
    ):
        raise ValueError(
            "Il materiale è stato confermato come duplicato.",
        )

    existing_public_material = (
        db.query(
            PublicMaterial,
        )
        .filter(
            PublicMaterial.publication_request_id ==
            publication_request.id,
        )
        .first()
    )

    if existing_public_material is not None:
        raise ValueError(
            "La richiesta ha già generato un materiale pubblico.",
        )

    approved_at = datetime.now(
        timezone.utc,
    )

    public_material = PublicMaterial(
        subject_id=(
            publication_request.subject_id
        ),
        uploaded_by=(
            publication_request.user_id
        ),
        publication_request_id=(
            publication_request.id
        ),
        university=(
            publication_request.university
        ),
        university_code=(
            publication_request.university_code
        ),
        department=(
            publication_request.department
        ),
        department_code=(
            publication_request.department_code
        ),
        course=(
            publication_request.course
        ),
        course_code=(
            publication_request.course_code
        ),
        title=(
            publication_request.title
        ),
        description=(
            publication_request.description
        ),
        original_name=(
            publication_request.original_name
        ),
        stored_name=(
            publication_request.stored_name
        ),
        file_path=(
            publication_request.file_path
        ),
        mime_type=(
            publication_request.mime_type
        ),
        size=(
            publication_request.size
        ),
        file_hash=(
            publication_request.file_hash
        ),
        status="published",
        is_visible=True,
        approved_by=(
            current_admin.id
        ),
        approved_at=(
            approved_at
        ),
    )

    publication_request.status = (
        "approved"
    )

    publication_request.reviewed_by = (
        current_admin.id
    )

    publication_request.reviewed_at = (
        approved_at
    )

    publication_request.rejection_reason = (
        None
    )

    publication_request.admin_note = (
        data.admin_note.strip()
        if data.admin_note
        is not None
        else None
    )

    try:
        db.add(
            public_material,
        )

        db.flush()

        db.commit()

        db.refresh(
            publication_request,
        )

        db.refresh(
            public_material,
        )

        return public_material

    except Exception:
        db.rollback()
        raise


def reject_material_publication_request(
    db: Session,
    *,
    publication_request:
        MaterialPublicationRequest,
    current_admin: User,
    data: MaterialPublicationRejectRequest,
):
    if (
        publication_request.status !=
        "pending"
    ):
        raise ValueError(
            "La richiesta è già stata elaborata.",
        )

    publication_request.status = (
        "rejected"
    )

    publication_request.reviewed_by = (
        current_admin.id
    )

    publication_request.reviewed_at = (
        datetime.now(
            timezone.utc,
        )
    )

    publication_request.rejection_reason = (
        data.rejection_reason
        .strip()
    )

    publication_request.admin_note = (
        data.admin_note.strip()
        if data.admin_note
        is not None
        else None
    )

    try:
        db.commit()

        db.refresh(
            publication_request,
        )

        return publication_request

    except Exception:
        db.rollback()
        raise
import uuid

from pathlib import Path

from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError

from vercel.blob import AsyncBlobClient

from core.config import settings

from models.material import GroupMaterial


ALLOWED_MIME_TYPES = {
    "application/pdf",
    "text/plain",
    "application/zip",
    "application/x-zip-compressed",
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
    "application/vnd.openxmlformats-officedocument.presentationml.presentation",
}


MAX_FILE_SIZE = 250 * 1024 * 1024


def generate_stored_name(
    group_id: int,
    original_name: str,
) -> str:
    extension = Path(
        original_name
    ).suffix.lower()

    unique_id = uuid.uuid4().hex

    return (
        f"groups/"
        f"group_{group_id}/"
        f"{unique_id}{extension}"
    )


def validate_material_size(
    size: int,
) -> None:
    if size <= 0:
        raise ValueError(
            "Il file è vuoto."
        )

    if size > MAX_FILE_SIZE:
        raise ValueError(
            "Il file supera la dimensione "
            "massima consentita di 250 MB."
        )


def validate_material_mime_type(
    mime_type: str,
) -> None:
    if mime_type not in ALLOWED_MIME_TYPES:
        raise ValueError(
            "Tipo di file non supportato."
        )


def normalize_file_hash(
    file_hash: str,
) -> str:
    normalized_hash = (
        file_hash
        .strip()
        .lower()
    )

    if len(normalized_hash) != 64:
        raise ValueError(
            "Hash del file non valido."
        )

    if not all(
        character in
        "0123456789abcdef"
        for character
        in normalized_hash
    ):
        raise ValueError(
            "Hash del file non valido."
        )

    return normalized_hash


def validate_stored_name(
    group_id: int,
    stored_name: str,
) -> None:
    expected_prefix = (
        f"groups/group_{group_id}/"
    )

    if not stored_name.startswith(
        expected_prefix
    ):
        raise ValueError(
            "Percorso storage non valido."
        )


def get_group_material_by_hash(
    db: Session,
    group_id: int,
    file_hash: str,
):
    normalized_hash = normalize_file_hash(
        file_hash,
    )

    return (
        db.query(
            GroupMaterial
        )
        .filter(
            GroupMaterial.group_id
            == group_id,
            GroupMaterial.file_hash
            == normalized_hash,
        )
        .first()
    )


def material_exists_in_group(
    db: Session,
    group_id: int,
    file_hash: str,
) -> bool:
    return (
        get_group_material_by_hash(
            db,
            group_id,
            file_hash,
        )
        is not None
    )


def ensure_material_not_duplicate(
    db: Session,
    group_id: int,
    file_hash: str,
) -> None:
    if material_exists_in_group(
        db,
        group_id,
        file_hash,
    ):
        raise ValueError(
            "Questo materiale è già presente "
            "nel gruppo."
        )


def create_group_material_record(
    db: Session,
    group_id: int,
    uploaded_by: int,
    original_name: str,
    stored_name: str,
    file_path: str,
    mime_type: str,
    size: int,
    file_hash: str,
):
    validate_material_size(
        size,
    )

    validate_material_mime_type(
        mime_type,
    )

    validate_stored_name(
        group_id,
        stored_name,
    )

    normalized_hash = normalize_file_hash(
        file_hash,
    )

    ensure_material_not_duplicate(
        db,
        group_id,
        normalized_hash,
    )

    material = GroupMaterial(
        group_id=group_id,
        uploaded_by=uploaded_by,
        original_name=original_name,
        stored_name=stored_name,
        file_path=file_path,
        mime_type=mime_type,
        size=size,
        file_hash=normalized_hash,
    )

    try:
        db.add(
            material
        )

        db.commit()

        db.refresh(
            material
        )

        return material

    except IntegrityError as exception:
        db.rollback()

        raise ValueError(
            "Questo materiale è già presente "
            "nel gruppo."
        ) from exception

    except Exception:
        db.rollback()
        raise


def get_group_materials(
    db: Session,
    group_id: int,
):
    return (
        db.query(
            GroupMaterial
        )
        .filter(
            GroupMaterial.group_id
            == group_id
        )
        .order_by(
            GroupMaterial.created_at.desc()
        )
        .all()
    )


def get_group_material_by_id(
    db: Session,
    material_id: int,
):
    return (
        db.query(
            GroupMaterial
        )
        .filter(
            GroupMaterial.id
            == material_id
        )
        .first()
    )


def get_blob_client():
    if not settings.blob_read_write_token:
        raise RuntimeError(
            "Token Vercel Blob non configurato."
        )

    return AsyncBlobClient(
        token=settings.blob_read_write_token,
    )


async def delete_group_material(
    db: Session,
    material: GroupMaterial,
):
    client = get_blob_client()

    await client.delete(
        material.stored_name,
    )

    try:
        db.delete(
            material
        )

        db.commit()

    except Exception:
        db.rollback()
        raise
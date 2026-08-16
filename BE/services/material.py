import uuid

from pathlib import Path

from sqlalchemy.orm import Session

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


def create_group_material_record(
    db: Session,
    group_id: int,
    uploaded_by: int,
    original_name: str,
    stored_name: str,
    file_path: str,
    mime_type: str,
    size: int,
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

    material = GroupMaterial(
        group_id=group_id,
        uploaded_by=uploaded_by,
        original_name=original_name,
        stored_name=stored_name,
        file_path=file_path,
        mime_type=mime_type,
        size=size,
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
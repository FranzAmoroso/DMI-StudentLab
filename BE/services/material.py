import uuid

from pathlib import Path

from fastapi import UploadFile

from sqlalchemy.orm import Session

from models.material import GroupMaterial


ALLOWED_MIME_TYPES = {
    "application/pdf",
    "text/plain",
    "application/zip",
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
    "application/vnd.openxmlformats-officedocument.presentationml.presentation",
}


MAX_FILE_SIZE = 50 * 1024 * 1024


STORAGE_ROOT = Path(
    "storage/groups"
)


def get_group_storage_directory(
    group_id: int,
):
    directory = (
        STORAGE_ROOT
        / f"group_{group_id}"
    )

    directory.mkdir(
        parents=True,
        exist_ok=True,
    )

    return directory


def generate_stored_name(
    original_name: str,
):
    extension = Path(
        original_name
    ).suffix.lower()

    unique_id = uuid.uuid4().hex

    return (
        f"{unique_id}{extension}"
    )


def save_group_material(
    db: Session,
    group_id: int,
    uploaded_by: int,
    file: UploadFile,
):
    original_name = (
        file.filename
        or "file"
    )

    stored_name = generate_stored_name(
        original_name,
    )

    directory = (
        get_group_storage_directory(
            group_id,
        )
    )

    destination = (
        directory
        / stored_name
    )

    size = 0

    try:
        with destination.open(
            "wb"
        ) as output_file:

            while True:
                chunk = file.file.read(
                    1024 * 1024
                )

                if not chunk:
                    break

                size += len(chunk)

                if size > MAX_FILE_SIZE:
                    raise ValueError(
                        "Il file supera la dimensione massima consentita."
                    )

                output_file.write(
                    chunk
                )

        material = GroupMaterial(
            group_id=group_id,
            uploaded_by=uploaded_by,
            original_name=original_name,
            stored_name=stored_name,
            file_path=str(destination),
            mime_type=(
                file.content_type
                or "application/octet-stream"
            ),
            size=size,
        )

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

        if destination.exists():
            destination.unlink()

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


def delete_group_material(
    db: Session,
    material: GroupMaterial,
):
    path = Path(
        material.file_path
    )

    db.delete(
        material
    )

    db.commit()

    if path.exists():
        path.unlink()
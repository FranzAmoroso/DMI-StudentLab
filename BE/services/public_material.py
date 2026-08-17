from sqlalchemy.orm import (
    Session,
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


def get_public_material_by_id(
    db: Session,
    material_id: int,
):
    return (
        db.query(
            PublicMaterial,
        )
        .filter(
            PublicMaterial.id ==
            material_id,
        )
        .first()
    )


def get_visible_public_material_by_id(
    db: Session,
    material_id: int,
):
    return (
        db.query(
            PublicMaterial,
        )
        .filter(
            PublicMaterial.id ==
            material_id,
            PublicMaterial.status ==
            "published",
            PublicMaterial.is_visible.is_(
                True,
            ),
        )
        .first()
    )


def get_public_materials(
    db: Session,
):
    return (
        db.query(
            PublicMaterial,
        )
        .filter(
            PublicMaterial.status ==
            "published",
            PublicMaterial.is_visible.is_(
                True,
            ),
        )
        .order_by(
            PublicMaterial.created_at.desc(),
        )
        .all()
    )


def get_public_materials_by_subject(
    db: Session,
    subject_id: int,
):
    return (
        db.query(
            PublicMaterial,
        )
        .filter(
            PublicMaterial.subject_id ==
            subject_id,
            PublicMaterial.status ==
            "published",
            PublicMaterial.is_visible.is_(
                True,
            ),
        )
        .order_by(
            PublicMaterial.created_at.desc(),
        )
        .all()
    )


def get_public_materials_by_catalog(
    db: Session,
    *,
    university_code: str,
    department_code: str,
    course_code: str,
    subject_id: int,
):
    subject = (
        db.query(
            Subject,
        )
        .filter(
            Subject.id ==
            subject_id,
            Subject.university_code ==
            university_code,
            Subject.department_code ==
            department_code,
            Subject.course_code ==
            course_code,
            Subject.is_active.is_(
                True,
            ),
        )
        .first()
    )

    if subject is None:
        return None

    return (
        db.query(
            PublicMaterial,
        )
        .filter(
            PublicMaterial.subject_id ==
            subject_id,
            PublicMaterial.university_code ==
            university_code,
            PublicMaterial.department_code ==
            department_code,
            PublicMaterial.course_code ==
            course_code,
            PublicMaterial.status ==
            "published",
            PublicMaterial.is_visible.is_(
                True,
            ),
        )
        .order_by(
            PublicMaterial.created_at.desc(),
        )
        .all()
    )


def get_admin_public_materials(
    db: Session,
    status: str | None = None,
):
    query = db.query(
        PublicMaterial,
    )

    if status is not None:
        query = query.filter(
            PublicMaterial.status ==
            status,
        )

    return (
        query
        .order_by(
            PublicMaterial.created_at.desc(),
        )
        .all()
    )


def hide_public_material(
    db: Session,
    *,
    material: PublicMaterial,
    current_admin: User,
):
    material.status = (
        "hidden"
    )

    material.is_visible = (
        False
    )

    try:
        db.commit()

        db.refresh(
            material,
        )

        return material

    except Exception:
        db.rollback()
        raise


def restore_public_material(
    db: Session,
    *,
    material: PublicMaterial,
    current_admin: User,
):
    material.status = (
        "published"
    )

    material.is_visible = (
        True
    )

    try:
        db.commit()

        db.refresh(
            material,
        )

        return material

    except Exception:
        db.rollback()
        raise


def remove_public_material(
    db: Session,
    *,
    material: PublicMaterial,
    current_admin: User,
):
    material.status = (
        "removed"
    )

    material.is_visible = (
        False
    )

    try:
        db.commit()

        db.refresh(
            material,
        )

        return material

    except Exception:
        db.rollback()
        raise
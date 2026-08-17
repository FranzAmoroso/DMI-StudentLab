from datetime import (
    datetime,
    timezone,
)

from sqlalchemy import (
    BigInteger,
    CheckConstraint,
    Column,
    DateTime,
    ForeignKey,
    Integer,
    String,
    Text,
)

from sqlalchemy.orm import relationship

from core.database import Base


def utc_now():
    return datetime.now(
        timezone.utc,
    )


class MaterialPublicationRequest(Base):
    __tablename__ = (
        "material_publication_requests"
    )

    id = Column(
        Integer,
        primary_key=True,
        index=True,
    )

    user_id = Column(
        Integer,
        ForeignKey(
            "users.id",
            ondelete="CASCADE",
        ),
        nullable=False,
        index=True,
    )

    subject_id = Column(
        Integer,
        ForeignKey(
            "subjects.id",
            ondelete="CASCADE",
        ),
        nullable=False,
        index=True,
    )

    university = Column(
        String(200),
        nullable=False,
    )

    university_code = Column(
        String(100),
        nullable=False,
        index=True,
    )

    department = Column(
        String(200),
        nullable=False,
    )

    department_code = Column(
        String(100),
        nullable=False,
        index=True,
    )

    course = Column(
        String(200),
        nullable=False,
    )

    course_code = Column(
        String(100),
        nullable=False,
        index=True,
    )

    title = Column(
        String(250),
        nullable=False,
    )

    description = Column(
        Text,
        nullable=True,
    )

    original_name = Column(
        String(255),
        nullable=False,
    )

    stored_name = Column(
        String(500),
        nullable=False,
        unique=True,
    )

    file_path = Column(
        String(1000),
        nullable=False,
    )

    mime_type = Column(
        String(150),
        nullable=False,
    )

    size = Column(
        BigInteger,
        nullable=False,
    )

    file_hash = Column(
        String(64),
        nullable=False,
        index=True,
    )

    status = Column(
        String(30),
        nullable=False,
        default="pending",
        index=True,
    )

    duplicate_status = Column(
        String(30),
        nullable=False,
        default="none",
        index=True,
    )

    possible_duplicate_material_id = Column(
        Integer,
        ForeignKey(
            "public_materials.id",
            ondelete="SET NULL",
        ),
        nullable=True,
        index=True,
    )

    reviewed_by = Column(
        Integer,
        ForeignKey(
            "users.id",
            ondelete="SET NULL",
        ),
        nullable=True,
        index=True,
    )

    reviewed_at = Column(
        DateTime(
            timezone=True,
        ),
        nullable=True,
    )

    rejection_reason = Column(
        Text,
        nullable=True,
    )

    admin_note = Column(
        Text,
        nullable=True,
    )

    created_at = Column(
        DateTime(
            timezone=True,
        ),
        nullable=False,
        default=utc_now,
        index=True,
    )

    updated_at = Column(
        DateTime(
            timezone=True,
        ),
        nullable=False,
        default=utc_now,
        onupdate=utc_now,
    )

    user = relationship(
        "User",
        foreign_keys=[
            user_id,
        ],
    )

    subject = relationship(
        "Subject",
    )

    reviewer = relationship(
        "User",
        foreign_keys=[
            reviewed_by,
        ],
    )

    possible_duplicate_material = (
        relationship(
            "PublicMaterial",
            foreign_keys=[
                possible_duplicate_material_id,
            ],
        )
    )

    __table_args__ = (
        CheckConstraint(
            "status IN ("
            "'pending', "
            "'approved', "
            "'rejected'"
            ")",
            name=(
                "chk_material_publication_request_status"
            ),
        ),
        CheckConstraint(
            "duplicate_status IN ("
            "'none', "
            "'suspected', "
            "'confirmed', "
            "'not_duplicate'"
            ")",
            name=(
                "chk_material_publication_request_duplicate_status"
            ),
        ),
        CheckConstraint(
            "size > 0",
            name=(
                "chk_material_publication_request_size"
            ),
        ),
    )
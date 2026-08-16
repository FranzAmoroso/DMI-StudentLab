from sqlalchemy import (
    BigInteger,
    Boolean,
    CheckConstraint,
    Column,
    DateTime,
    ForeignKey,
    Integer,
    String,
    Text,
    func,
)

from sqlalchemy.orm import (
    relationship,
)

from core.database import (
    Base,
)


class TeacherMaterial(Base):
    __tablename__ = "teacher_materials"

    __table_args__ = (
        CheckConstraint(
            "size > 0",
            name="chk_teacher_material_size",
        ),
        CheckConstraint(
            "visibility IN ('students', 'private')",
            name="chk_teacher_material_visibility",
        ),
    )

    id = Column(
        Integer,
        primary_key=True,
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

    uploaded_by = Column(
        Integer,
        ForeignKey(
            "users.id",
            ondelete="CASCADE",
        ),
        nullable=False,
        index=True,
    )

    title = Column(
        String(255),
        nullable=False,
    )

    description = Column(
        Text,
        nullable=False,
        default="",
        server_default="",
    )

    original_name = Column(
        String(255),
        nullable=False,
    )

    stored_name = Column(
        Text,
        nullable=False,
    )

    file_path = Column(
        Text,
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
        nullable=True,
    )

    visibility = Column(
        String(30),
        nullable=False,
        default="students",
        server_default="students",
    )

    is_active = Column(
        Boolean,
        nullable=False,
        default=True,
        server_default="true",
        index=True,
    )

    created_at = Column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
    )

    updated_at = Column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
        onupdate=func.now(),
    )

    subject = relationship(
        "Subject",
        foreign_keys=[
            subject_id,
        ],
    )

    uploader = relationship(
        "User",
        foreign_keys=[
            uploaded_by,
        ],
    )
from datetime import datetime

from sqlalchemy import (
    Column,
    DateTime,
    ForeignKey,
    Integer,
    String,
    UniqueConstraint,
)

from sqlalchemy.orm import relationship

from core.database import Base


class GroupMaterial(Base):
    __tablename__ = "group_materials"

    __table_args__ = (
        UniqueConstraint(
            "group_id",
            "file_hash",
            name="uq_group_material_group_file_hash",
        ),
    )

    id = Column(
        Integer,
        primary_key=True,
        index=True,
    )

    group_id = Column(
        Integer,
        ForeignKey(
            "study_groups.id",
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

    original_name = Column(
        String(255),
        nullable=False,
    )

    stored_name = Column(
        String(255),
        nullable=False,
        unique=True,
    )

    file_path = Column(
        String(500),
        nullable=False,
    )

    mime_type = Column(
        String(150),
        nullable=False,
    )

    size = Column(
        Integer,
        nullable=False,
    )

    file_hash = Column(
        String(64),
        nullable=True,
        index=True,
    )

    created_at = Column(
        DateTime,
        nullable=False,
        default=datetime.utcnow,
    )

    group = relationship(
        "StudyGroup",
        back_populates="materials",
        foreign_keys=[
            group_id,
        ],
    )
    uploader = relationship(
        "User",
    )
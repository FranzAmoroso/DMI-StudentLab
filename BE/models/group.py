# models/group.py

from datetime import datetime

from sqlalchemy import (
    Boolean,
    Column,
    DateTime,
    ForeignKey,
    Integer,
    String,
    Text,
    UniqueConstraint,
)

from sqlalchemy.orm import relationship

from core.database import Base


class StudyGroup(Base):
    __tablename__ = "study_groups"

    id = Column(
        Integer,
        primary_key=True,
        index=True,
    )

    name = Column(
        String(150),
        nullable=False,
    )

    description = Column(
        Text,
        nullable=True,
    )

    subject_id = Column(
        Integer,
        ForeignKey(
            "subjects.id",
            ondelete="SET NULL",
        ),
        nullable=True,
        index=True,
    )

    department = Column(
        String(150),
        nullable=False,
    )

    course = Column(
        String(150),
        nullable=False,
    )

    is_private = Column(
        Boolean,
        nullable=False,
        default=False,
    )

    created_by = Column(
        Integer,
        ForeignKey(
            "users.id",
            ondelete="CASCADE",
        ),
        nullable=False,
        index=True,
    )

    created_at = Column(
        DateTime,
        nullable=False,
        default=datetime.utcnow,
    )

    subject = relationship(
        "Subject",
    )

    creator = relationship(
        "User",
        foreign_keys=[
            created_by,
        ],
    )

    members = relationship(
        "GroupMember",
        back_populates="group",
        cascade="all, delete-orphan",
    )

    join_requests = relationship(
        "GroupJoinRequest",
        back_populates="group",
        cascade="all, delete-orphan",
    )

    materials = relationship(
    "GroupMaterial",
    cascade="all, delete-orphan",
    )


class GroupMember(Base):
    __tablename__ = "group_members"

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

    user_id = Column(
        Integer,
        ForeignKey(
            "users.id",
            ondelete="CASCADE",
        ),
        nullable=False,
        index=True,
    )

    role = Column(
        String(20),
        nullable=False,
        default="member",
    )

    joined_at = Column(
        DateTime,
        nullable=False,
        default=datetime.utcnow,
    )

    group = relationship(
        "StudyGroup",
        back_populates="members",
    )

    user = relationship(
        "User",
    )

    __table_args__ = (
        UniqueConstraint(
            "group_id",
            "user_id",
            name="uq_group_member",
        ),
    )


class GroupJoinRequest(Base):
    __tablename__ = "group_join_requests"

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

    user_id = Column(
        Integer,
        ForeignKey(
            "users.id",
            ondelete="CASCADE",
        ),
        nullable=False,
        index=True,
    )

    status = Column(
        String(20),
        nullable=False,
        default="pending",
    )

    created_at = Column(
        DateTime,
        nullable=False,
        default=datetime.utcnow,
    )

    group = relationship(
        "StudyGroup",
        back_populates="join_requests",
    )

    user = relationship(
        "User",
    )

    __table_args__ = (
        UniqueConstraint(
            "group_id",
            "user_id",
            name="uq_group_join_request",
        ),
    )
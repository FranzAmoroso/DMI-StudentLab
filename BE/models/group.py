from datetime import datetime

from sqlalchemy import (
    Boolean,
    CheckConstraint,
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

    university = Column(
        String(150),
        nullable=False,
        default="",
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

    status = Column(
        String(30),
        nullable=False,
        default="active",
        index=True,
    )

    deletion_requested_at = Column(
        DateTime(
            timezone=True,
        ),
        nullable=True,
    )

    deletion_deadline = Column(
        DateTime(
            timezone=True,
        ),
        nullable=True,
        index=True,
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
        DateTime(
            timezone=True,
        ),
        nullable=False,
        default=datetime.utcnow,
    )

    updated_at = Column(
        DateTime(
            timezone=True,
        ),
        nullable=False,
        default=datetime.utcnow,
        onupdate=datetime.utcnow,
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

    ownership_transfers = relationship(
        "GroupOwnershipTransfer",
        foreign_keys="GroupOwnershipTransfer.group_id",
        cascade="all, delete-orphan",
        order_by="GroupOwnershipTransfer.id",
    )

    reports = relationship(
        "GroupReport",
        foreign_keys="GroupReport.group_id",
        cascade="all, delete-orphan",
        order_by="GroupReport.id",
    )

    content_reports = relationship(
        "GroupContentReport",
        foreign_keys="GroupContentReport.group_id",
        cascade="all, delete-orphan",
        order_by="GroupContentReport.id",
    )

    __table_args__ = (
        CheckConstraint(
            "status IN ("
            "'active', "
            "'pending_deletion', "
            "'deleted'"
            ")",
            name="chk_study_group_status",
        ),
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
        index=True,
    )

    joined_at = Column(
        DateTime(
            timezone=True,
        ),
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
        CheckConstraint(
            "role IN ("
            "'owner', "
            "'admin', "
            "'member'"
            ")",
            name="chk_group_member_role",
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

    created_at = Column(
        DateTime(
            timezone=True,
        ),
        nullable=False,
        default=datetime.utcnow,
    )

    updated_at = Column(
        DateTime(
            timezone=True,
        ),
        nullable=False,
        default=datetime.utcnow,
        onupdate=datetime.utcnow,
    )

    group = relationship(
        "StudyGroup",
        back_populates="join_requests",
    )

    user = relationship(
        "User",
        foreign_keys=[
            user_id,
        ],
    )

    reviewer = relationship(
        "User",
        foreign_keys=[
            reviewed_by,
        ],
    )

    __table_args__ = (
        UniqueConstraint(
            "group_id",
            "user_id",
            name="uq_group_join_request",
        ),
        CheckConstraint(
            "status IN ("
            "'pending', "
            "'accepted', "
            "'rejected', "
            "'cancelled'"
            ")",
            name="chk_group_join_request_status",
        ),
    )
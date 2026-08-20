from datetime import datetime, timezone

from sqlalchemy import (
    Boolean,
    CheckConstraint,
    Column,
    DateTime,
    ForeignKey,
    Integer,
    JSON,
    String,
    Text,
    UniqueConstraint,
)
from sqlalchemy.orm import relationship

from core.database import Base


def utc_now() -> datetime:
    return datetime.now(timezone.utc)


class QuizAssignment(Base):
    __tablename__ = "quiz_assignments"

    id = Column(
        Integer,
        primary_key=True,
        index=True,
    )

    teacher_id = Column(
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

    department = Column(
        String(100),
        nullable=False,
        index=True,
    )

    course = Column(
        String(100),
        nullable=False,
        index=True,
    )

    subject = Column(
        String(255),
        nullable=False,
        index=True,
    )

    title = Column(
        String(255),
        nullable=False,
    )

    description = Column(
        Text,
        nullable=True,
    )

    selection_mode = Column(
        String(30),
        nullable=False,
        default="random",
        index=True,
    )

    selected_arguments = Column(
        JSON,
        nullable=False,
        default=list,
    )

    selected_question_ids = Column(
        JSON,
        nullable=False,
        default=list,
    )

    question_count = Column(
        Integer,
        nullable=False,
    )

    time_limit_seconds = Column(
        Integer,
        nullable=True,
    )

    due_at = Column(
        DateTime(timezone=True),
        nullable=True,
        index=True,
    )

    is_active = Column(
        Boolean,
        nullable=False,
        default=True,
        index=True,
    )

    created_at = Column(
        DateTime(timezone=True),
        nullable=False,
        default=utc_now,
    )

    updated_at = Column(
        DateTime(timezone=True),
        nullable=False,
        default=utc_now,
        onupdate=utc_now,
    )

    recipients = relationship(
        "QuizAssignmentRecipient",
        back_populates="assignment",
        cascade="all, delete-orphan",
        passive_deletes=True,
    )


class QuizAssignmentRecipient(Base):
    __tablename__ = "quiz_assignment_recipients"

    __table_args__ = (
        UniqueConstraint(
            "assignment_id",
            "user_id",
            name="uq_quiz_assignment_recipient_user",
        ),
        UniqueConstraint(
            "assignment_id",
            "group_id",
            name="uq_quiz_assignment_recipient_group",
        ),
        CheckConstraint(
            "(user_id IS NOT NULL AND group_id IS NULL) OR "
            "(user_id IS NULL AND group_id IS NOT NULL)",
            name="ck_quiz_assignment_recipient_exactly_one_target",
        ),
    )

    id = Column(
        Integer,
        primary_key=True,
        index=True,
    )

    assignment_id = Column(
        Integer,
        ForeignKey(
            "quiz_assignments.id",
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
        nullable=True,
        index=True,
    )

    group_id = Column(
        Integer,
        ForeignKey(
            "study_groups.id",
            ondelete="CASCADE",
        ),
        nullable=True,
        index=True,
    )

    created_at = Column(
        DateTime(timezone=True),
        nullable=False,
        default=utc_now,
    )

    assignment = relationship(
        "QuizAssignment",
        back_populates="recipients",
    )
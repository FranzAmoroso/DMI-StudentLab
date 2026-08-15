from sqlalchemy import (
    Boolean,
    Column,
    ForeignKey,
    Integer,
    String,
    Text,
    UniqueConstraint,
)

from sqlalchemy.orm import relationship

from core.database import Base


class Subject(Base):
    __tablename__ = "subjects"

    id = Column(
        Integer,
        primary_key=True,
        index=True,
    )

    name = Column(
        String(150),
        nullable=False,
    )

    department = Column(
        String(150),
        nullable=False,
    )

    course = Column(
        String(150),
        nullable=False,
    )

    __table_args__ = (
        UniqueConstraint(
            "name",
            "department",
            "course",
            name="uq_subject_department_course",
        ),
    )

    users = relationship(
        "UserSubject",
        back_populates="subject",
        cascade="all, delete-orphan",
    )


class UserSubject(Base):
    __tablename__ = "user_subjects"

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

    grade = Column(
        Integer,
        nullable=True,
    )

    note = Column(
        Text,
        nullable=True,
    )

    can_help = Column(
        Boolean,
        nullable=False,
        default=False,
    )

    user = relationship(
        "User",
        back_populates="subjects",
    )

    subject = relationship(
        "Subject",
        back_populates="users",
    )

    __table_args__ = (
        UniqueConstraint(
            "user_id",
            "subject_id",
            name="uq_user_subject",
        ),
    )
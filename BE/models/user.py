from sqlalchemy import (
    Boolean,
    Column,
    DateTime,
    ForeignKey,
    Integer,
    String,
    Text,
)

from sqlalchemy.orm import relationship

from core.database import Base


class User(Base):
    __tablename__ = "users"

    id = Column(
        Integer,
        primary_key=True,
        index=True,
    )

    first_name = Column(
        String(100),
        nullable=False,
    )

    last_name = Column(
        String(100),
        nullable=False,
    )

    email = Column(
        String(255),
        nullable=False,
        unique=True,
        index=True,
    )

    password_hash = Column(
        String(255),
        nullable=False,
    )

    university = Column(
        String(200),
        nullable=True,
    )

    department = Column(
        String(150),
        nullable=True,
    )

    course = Column(
        String(150),
        nullable=True,
    )

    description = Column(
        Text,
        nullable=True,
    )

    role = Column(
        String(30),
        nullable=False,
        default="student",
        index=True,
    )

    teacher_verification_status = Column(
        String(30),
        nullable=False,
        default="not_required",
        index=True,
    )

    teacher_verified_by = Column(
        Integer,
        ForeignKey(
            "users.id",
            ondelete="SET NULL",
        ),
        nullable=True,
    )

    teacher_verified_at = Column(
        DateTime(
            timezone=True,
        ),
        nullable=True,
    )

    available = Column(
        Boolean,
        nullable=False,
        default=False,
    )

    available_for_help = Column(
        Boolean,
        nullable=False,
        default=False,
    )

    available_for_private_lessons = Column(
        Boolean,
        nullable=False,
        default=False,
    )

    willing_to_teach = Column(
        Boolean,
        nullable=False,
        default=False,
    )

    is_active = Column(
        Boolean,
        nullable=False,
        default=True,
        index=True,
    )

    subjects = relationship(
        "UserSubject",
        back_populates="user",
        cascade="all, delete-orphan",
    )

    academic_paths = relationship(
        "UserAcademicPath",
        back_populates="user",
        cascade="all, delete-orphan",
        order_by="UserAcademicPath.id",
        foreign_keys="UserAcademicPath.user_id",
    )


class UserAcademicPath(Base):
    __tablename__ = "user_academic_paths"

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

    university = Column(
        String(200),
        nullable=False,
    )

    university_code = Column(
        String(50),
        nullable=False,
    )

    department = Column(
        String(200),
        nullable=False,
    )

    department_code = Column(
        String(50),
        nullable=False,
    )

    course = Column(
        String(200),
        nullable=False,
    )

    course_code = Column(
        String(50),
        nullable=False,
    )

    degree_type = Column(
        String(50),
        nullable=True,
    )

    status = Column(
        String(30),
        nullable=False,
        default="enrolled",
        index=True,
    )

    verification_status = Column(
        String(30),
        nullable=False,
        default="not_required",
        index=True,
    )

    verified_by = Column(
        Integer,
        ForeignKey(
            "users.id",
            ondelete="SET NULL",
        ),
        nullable=True,
    )

    verified_at = Column(
        DateTime(
            timezone=True,
        ),
        nullable=True,
    )

    start_year = Column(
        Integer,
        nullable=True,
    )

    graduation_year = Column(
        Integer,
        nullable=True,
    )

    is_current = Column(
        Boolean,
        nullable=False,
        default=False,
        index=True,
    )

    is_primary = Column(
        Boolean,
        nullable=False,
        default=False,
        index=True,
    )

    user = relationship(
        "User",
        back_populates="academic_paths",
        foreign_keys=[
            user_id,
        ],
    )
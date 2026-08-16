from sqlalchemy import (
    Boolean,
    Column,
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

    # student
    # teacher
    role = Column(
        String(30),
        nullable=False,
        default="student",
    )

    available = Column(
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
    )

    subjects = relationship(
        "UserSubject",
        back_populates="user",
        cascade="all, delete-orphan",
    )


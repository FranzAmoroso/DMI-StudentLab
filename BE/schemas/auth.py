from datetime import date

from typing import Literal

from pydantic import (
    BaseModel,
    EmailStr,
    Field,
)


class RegisterRequest(BaseModel):
    first_name: str = Field(
        min_length=1,
        max_length=100,
    )

    last_name: str = Field(
        min_length=1,
        max_length=100,
    )

    date_of_birth: date

    email: EmailStr

    password: str = Field(
        min_length=8,
        max_length=128,
    )

    policy_version: str = Field(
        min_length=1,
        max_length=30,
    )

    privacy_acknowledged: bool

    terms_accepted: bool

    university: str | None = None

    university_code: str | None = None

    department: str | None = None

    department_code: str | None = None

    course: str | None = None

    course_code: str | None = None

    degree_type: str | None = None

    academic_status: Literal[
        "enrolled",
        "graduated",
        "withdrawn",
        "transferred",
    ] = "enrolled"

    start_year: int | None = None

    graduation_year: int | None = None

    description: str | None = None

    role: Literal[
        "student",
        "teacher",
    ] = "student"

    available: bool = True

    available_for_help: bool = False

    available_for_private_lessons: bool = False

    willing_to_teach: bool | None = None


class LoginRequest(BaseModel):
    email: EmailStr

    password: str


class TokenResponse(BaseModel):
    access_token: str

    token_type: str = "bearer"
from typing import Literal

from pydantic import (
    BaseModel,
    EmailStr,
)


class RegisterRequest(BaseModel):
    first_name: str

    last_name: str

    email: EmailStr

    password: str

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
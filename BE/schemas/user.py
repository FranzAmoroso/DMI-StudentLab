from datetime import datetime

from typing import Literal

from pydantic import (
    BaseModel,
    ConfigDict,
    Field,
)

from schemas.subject import (
    UserSubjectResponse,
)


AcademicPathStatus = Literal[
    "enrolled",
    "graduated",
    "withdrawn",
    "transferred",
]


AcademicPathVerificationStatus = Literal[
    "not_required",
    "pending",
    "verified",
    "rejected",
]


class UserAcademicPathCreate(BaseModel):
    university: str

    university_code: str

    department: str

    department_code: str

    course: str

    course_code: str

    degree_type: str | None = None

    status: AcademicPathStatus = "enrolled"

    start_year: int | None = None

    graduation_year: int | None = None

    is_current: bool = False

    is_primary: bool = False


class UserAcademicPathUpdate(BaseModel):
    university: str | None = None

    university_code: str | None = None

    department: str | None = None

    department_code: str | None = None

    course: str | None = None

    course_code: str | None = None

    degree_type: str | None = None

    status: AcademicPathStatus | None = None

    start_year: int | None = None

    graduation_year: int | None = None

    is_current: bool | None = None

    is_primary: bool | None = None


class AcademicPathVerificationUpdate(BaseModel):
    status: Literal[
        "verified",
        "rejected",
    ]


class UserAcademicPathResponse(BaseModel):
    model_config = ConfigDict(
        from_attributes=True,
    )

    id: int

    user_id: int

    university: str

    university_code: str

    department: str

    department_code: str

    course: str

    course_code: str

    degree_type: str | None

    status: str

    verification_status: str

    verified_by: int | None

    verified_at: datetime | None

    start_year: int | None

    graduation_year: int | None

    is_current: bool

    is_primary: bool


class UserCreate(BaseModel):
    first_name: str

    last_name: str

    email: str

    university: str | None = None

    university_code: str | None = None

    department: str | None = None

    department_code: str | None = None

    course: str | None = None

    course_code: str | None = None

    degree_type: str | None = None

    academic_status: AcademicPathStatus = "enrolled"

    start_year: int | None = None

    graduation_year: int | None = None

    description: str | None = None

    role: Literal[
        "student",
        "teacher",
    ] = "student"

    available: bool = False

    available_for_help: bool | None = None

    available_for_private_lessons: bool | None = None

    willing_to_teach: bool | None = None


class UserUpdate(BaseModel):
    first_name: str | None = None

    last_name: str | None = None

    description: str | None = None

    available: bool | None = None

    available_for_help: bool | None = None

    available_for_private_lessons: bool | None = None

    willing_to_teach: bool | None = None


class TeacherVerificationUpdate(BaseModel):
    status: Literal[
        "verified",
        "rejected",
    ]


class UserAdminStatusUpdate(BaseModel):
    is_active: bool


class UserResponse(BaseModel):
    model_config = ConfigDict(
        from_attributes=True,
    )

    id: int

    first_name: str

    last_name: str

    email: str

    university: str | None

    department: str | None

    course: str | None

    description: str | None

    role: str

    teacher_verification_status: str

    teacher_verified_by: int | None

    teacher_verified_at: datetime | None

    available: bool

    available_for_help: bool

    available_for_private_lessons: bool

    willing_to_teach: bool

    is_active: bool

    subjects: list[
        UserSubjectResponse
    ] = Field(
        default_factory=list,
    )

    academic_paths: list[
        UserAcademicPathResponse
    ] = Field(
        default_factory=list,
    )
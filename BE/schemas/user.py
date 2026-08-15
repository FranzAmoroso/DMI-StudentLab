from pydantic import (
    BaseModel,
    ConfigDict,
)

from schemas.subject import (
    UserSubjectResponse,
)


# =============================================================================
# USER CREATE
# =============================================================================

class UserCreate(BaseModel):
    first_name: str

    last_name: str

    email: str

    department: str | None = None

    course: str | None = None

    description: str | None = None

    role: str = "student"

    available: bool = False

    willing_to_teach: bool = False


# =============================================================================
# USER UPDATE
# =============================================================================

class UserUpdate(BaseModel):
    first_name: str | None = None

    last_name: str | None = None

    department: str | None = None

    course: str | None = None

    description: str | None = None

    role: str | None = None

    available: bool | None = None

    willing_to_teach: bool | None = None


# =============================================================================
# USER RESPONSE
# =============================================================================

class UserResponse(BaseModel):
    model_config = ConfigDict(
        from_attributes=True,
    )

    id: int

    first_name: str

    last_name: str

    email: str

    department: str | None

    course: str | None

    description: str | None

    role: str

    available: bool

    willing_to_teach: bool

    is_active: bool

    subjects: list[UserSubjectResponse] = []
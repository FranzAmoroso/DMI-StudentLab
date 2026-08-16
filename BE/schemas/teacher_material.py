from datetime import datetime

from pydantic import (
    BaseModel,
    Field,
)


class TeacherMaterialUploadRequest(
    BaseModel,
):
    subject_id: int

    original_name: str = Field(
        min_length=1,
        max_length=255,
    )

    mime_type: str = Field(
        min_length=1,
        max_length=150,
    )

    size: int = Field(
        gt=0,
    )

    file_hash: str | None = Field(
        default=None,
        max_length=64,
    )


class TeacherMaterialCompleteRequest(
    BaseModel,
):
    subject_id: int

    title: str = Field(
        min_length=1,
        max_length=255,
    )

    description: str = Field(
        default="",
        max_length=5000,
    )

    original_name: str = Field(
        min_length=1,
        max_length=255,
    )

    stored_name: str = Field(
        min_length=1,
    )

    file_path: str = Field(
        min_length=1,
    )

    mime_type: str = Field(
        min_length=1,
        max_length=150,
    )

    size: int = Field(
        gt=0,
    )

    file_hash: str | None = Field(
        default=None,
        max_length=64,
    )

    visibility: str = "students"


class TeacherMaterialUpdate(
    BaseModel,
):
    title: str | None = Field(
        default=None,
        min_length=1,
        max_length=255,
    )

    description: str | None = Field(
        default=None,
        max_length=5000,
    )

    visibility: str | None = None

    is_active: bool | None = None


class TeacherMaterialSubjectResponse(
    BaseModel,
):
    id: int

    code: str

    name: str


class TeacherMaterialResponse(
    BaseModel,
):
    id: int

    subject_id: int

    uploaded_by: int

    title: str

    description: str

    original_name: str

    stored_name: str

    file_path: str

    mime_type: str

    size: int

    file_hash: str | None

    visibility: str

    is_active: bool

    created_at: datetime

    updated_at: datetime

    subject: (
        TeacherMaterialSubjectResponse
        | None
    ) = None

    model_config = {
        "from_attributes": True,
    }
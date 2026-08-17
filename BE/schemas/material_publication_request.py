from datetime import datetime

from typing import Literal

from pydantic import (
    BaseModel,
    ConfigDict,
    Field,
)


MaterialPublicationStatus = Literal[
    "pending",
    "approved",
    "rejected",
]


MaterialDuplicateStatus = Literal[
    "none",
    "suspected",
    "confirmed",
    "not_duplicate",
]


class MaterialPublicationRequestCreate(BaseModel):
    subject_id: int

    title: str = Field(
        min_length=1,
        max_length=250,
    )

    description: str | None = None

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

    file_hash: str = Field(
        min_length=64,
        max_length=64,
        pattern=r"^[a-fA-F0-9]{64}$",
    )


class MaterialPublicationUploadRequest(BaseModel):
    subject_id: int

    title: str = Field(
        min_length=1,
        max_length=250,
    )

    description: str | None = None

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

    file_hash: str = Field(
        min_length=64,
        max_length=64,
        pattern=r"^[a-fA-F0-9]{64}$",
    )


class MaterialPublicationCompleteRequest(BaseModel):
    subject_id: int

    title: str = Field(
        min_length=1,
        max_length=250,
    )

    description: str | None = None

    original_name: str = Field(
        min_length=1,
        max_length=255,
    )

    stored_name: str = Field(
        min_length=1,
        max_length=500,
    )

    file_path: str = Field(
        min_length=1,
        max_length=1000,
    )

    mime_type: str = Field(
        min_length=1,
        max_length=150,
    )

    size: int = Field(
        gt=0,
    )

    file_hash: str = Field(
        min_length=64,
        max_length=64,
        pattern=r"^[a-fA-F0-9]{64}$",
    )


class MaterialPublicationRequestResponse(BaseModel):
    model_config = ConfigDict(
        from_attributes=True,
    )

    id: int

    user_id: int

    subject_id: int

    university: str

    university_code: str

    department: str

    department_code: str

    course: str

    course_code: str

    title: str

    description: str | None

    original_name: str

    mime_type: str

    size: int

    file_hash: str

    status: str

    duplicate_status: str

    possible_duplicate_material_id: int | None

    reviewed_by: int | None

    reviewed_at: datetime | None

    rejection_reason: str | None

    admin_note: str | None

    created_at: datetime

    updated_at: datetime


class MaterialPublicationRequestAdminResponse(
    MaterialPublicationRequestResponse,
):
    stored_name: str

    file_path: str


class MaterialPublicationApproveRequest(BaseModel):
    admin_note: str | None = None


class MaterialPublicationRejectRequest(BaseModel):
    rejection_reason: str = Field(
        min_length=1,
    )

    admin_note: str | None = None


class MaterialDuplicateReviewRequest(BaseModel):
    duplicate_status: Literal[
        "confirmed",
        "not_duplicate",
    ]

    admin_note: str | None = None
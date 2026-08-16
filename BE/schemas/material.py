from datetime import datetime

from pydantic import (
    BaseModel,
    ConfigDict,
    Field,
)


class GroupMaterialResponse(BaseModel):
    model_config = ConfigDict(
        from_attributes=True,
    )

    id: int
    group_id: int
    uploaded_by: int
    original_name: str
    mime_type: str
    size: int
    file_hash: str | None
    created_at: datetime


class GroupMaterialUploadRequest(BaseModel):
    uploaded_by: int

    original_name: str

    mime_type: str

    size: int

    file_hash: str = Field(
        min_length=64,
        max_length=64,
        pattern=r"^[a-fA-F0-9]{64}$",
    )


class GroupMaterialCompleteRequest(BaseModel):
    uploaded_by: int

    original_name: str

    stored_name: str

    file_path: str

    mime_type: str

    size: int

    file_hash: str = Field(
        min_length=64,
        max_length=64,
        pattern=r"^[a-fA-F0-9]{64}$",
    )
from datetime import datetime

from pydantic import (
    BaseModel,
    ConfigDict,
)


class PublicMaterialResponse(BaseModel):
    model_config = ConfigDict(
        from_attributes=True,
    )

    id: int

    subject_id: int

    uploaded_by: int | None

    publication_request_id: int | None

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

    status: str

    is_visible: bool

    approved_at: datetime | None

    created_at: datetime

    updated_at: datetime


class PublicMaterialAdminResponse(
    PublicMaterialResponse,
):
    stored_name: str

    file_path: str

    file_hash: str

    approved_by: int | None

from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class TeacherMaterialRequestCreate(BaseModel):
    subject_id: int
    teacher_user_id: int | None = None
    topic: str | None = Field(default=None, max_length=255)
    message: str = Field(min_length=1, max_length=3000)


class TeacherMaterialRequestResolve(BaseModel):
    action: str = Field(pattern="^(fulfilled|rejected)$")
    fulfilled_material_id: int | None = None


class TeacherMaterialRequestResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    student_user_id: int
    subject_id: int
    teacher_user_id: int | None
    topic: str | None
    message: str
    status: str
    fulfilled_material_id: int | None
    resolved_by: int | None
    resolved_at: datetime | None
    created_at: datetime
    updated_at: datetime

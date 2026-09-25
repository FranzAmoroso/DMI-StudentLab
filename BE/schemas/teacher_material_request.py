
from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class TeacherMaterialRequestCreate(BaseModel):
    subject_id: int
    teacher_user_id: int | None = None
    topic: str | None = Field(default=None, max_length=255)
    message: str = Field(min_length=1, max_length=3000)
    # Destinatario scelto dallo studente:
    #   None / "auto" -> docenti della materia se ci sono, altrimenti StudentLab (comportamento storico);
    #   "teachers"    -> solo docenti (errore se la materia non ne ha);
    #   "studentlab"  -> la redazione StudentLab anche se ci sono docenti.
    recipient_kind: str | None = Field(default=None, pattern="^(auto|teachers|studentlab)$")


class TeacherMaterialRequestResolve(BaseModel):
    action: str = Field(pattern="^(fulfilled|rejected)$")
    fulfilled_material_id: int | None = None
    fulfilled_share_id: int | None = None


class TeacherMaterialRequestResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    student_user_id: int
    subject_id: int
    teacher_user_id: int | None
    recipient_kind: str = 'teachers'
    staff_response: str | None = None
    topic: str | None
    message: str
    status: str
    fulfilled_material_id: int | None
    fulfilled_share_id: int | None = None
    public_material_id: int | None = None
    teacher_declined_at: datetime | None = None
    resolved_by: int | None
    resolved_at: datetime | None
    created_at: datetime
    updated_at: datetime

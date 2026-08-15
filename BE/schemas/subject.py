from pydantic import (
    BaseModel,
    ConfigDict,
)


# =============================================================================
# SUBJECT CREATE
# =============================================================================

class SubjectCreate(BaseModel):
    name: str
    department: str
    course: str


# =============================================================================
# SUBJECT RESPONSE
# =============================================================================

class SubjectResponse(BaseModel):
    model_config = ConfigDict(
        from_attributes=True,
    )

    id: int

    name: str

    department: str

    course: str


# =============================================================================
# AGGIUNTA MATERIA ALL'UTENTE
# =============================================================================

class UserSubjectCreate(BaseModel):
    subject_id: int

    grade: int | None = None

    note: str | None = None

    can_help: bool = False


# =============================================================================
# USER SUBJECT RESPONSE
# =============================================================================

class UserSubjectResponse(BaseModel):
    model_config = ConfigDict(
        from_attributes=True,
    )

    id: int

    grade: int | None

    note: str | None

    can_help: bool

    subject: SubjectResponse
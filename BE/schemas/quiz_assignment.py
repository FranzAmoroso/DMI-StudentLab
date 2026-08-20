from datetime import datetime, timezone

from pydantic import BaseModel, ConfigDict, Field, field_validator, model_validator


class QuizAssignmentCreate(BaseModel):
    department: str
    course: str
    subject: str
    title: str
    description: str | None = None
    selection_mode: str = "random"
    arguments: list[str] = Field(default_factory=list)
    question_ids: list[str] = Field(default_factory=list)
    question_count: int = Field(ge=1)
    time_limit_seconds: int | None = Field(default=None, ge=1)
    due_at: datetime | None = None
    user_ids: list[int] = Field(default_factory=list)
    group_ids: list[int] = Field(default_factory=list)

    @field_validator("department", "course", "subject", "title")
    @classmethod
    def validate_required_text(cls, value: str) -> str:
        value = value.strip()
        if not value:
            raise ValueError("Il valore non può essere vuoto.")
        return value

    @field_validator("description")
    @classmethod
    def validate_description(cls, value: str | None) -> str | None:
        if value is None:
            return None
        value = value.strip()
        return value or None

    @field_validator("selection_mode")
    @classmethod
    def validate_selection_mode(cls, value: str) -> str:
        value = value.strip().lower()
        allowed = {"random", "arguments", "selected_questions"}
        if value not in allowed:
            raise ValueError("Modalità di selezione quiz non valida.")
        return value

    @field_validator("arguments")
    @classmethod
    def normalize_arguments(cls, value: list[str]) -> list[str]:
        result: list[str] = []
        for argument in value:
            normalized = str(argument).strip()
            if normalized and normalized not in result:
                result.append(normalized)
        return result

    @field_validator("question_ids")
    @classmethod
    def normalize_question_ids(cls, value: list[str]) -> list[str]:
        result: list[str] = []
        for question_id in value:
            normalized = str(question_id).strip()
            if normalized and normalized not in result:
                result.append(normalized)
        return result

    @field_validator("user_ids", "group_ids")
    @classmethod
    def normalize_ids(cls, value: list[int]) -> list[int]:
        result: list[int] = []
        for item in value:
            if item > 0 and item not in result:
                result.append(item)
        return result

    @model_validator(mode="after")
    def validate_assignment(self):
        if not self.user_ids and not self.group_ids:
            raise ValueError("Seleziona almeno uno studente o un gruppo.")

        if self.selection_mode == "arguments" and not self.arguments:
            raise ValueError("Seleziona almeno un argomento.")

        if self.selection_mode == "selected_questions":
            if not self.question_ids:
                raise ValueError("Seleziona almeno una domanda.")
            if self.question_count != len(self.question_ids):
                raise ValueError(
                    "Il numero di domande deve coincidere con le domande selezionate."
                )

        if self.selection_mode != "arguments":
            self.arguments = []

        if self.selection_mode != "selected_questions":
            self.question_ids = []

        if self.due_at is not None:
            due_at = self.due_at
            if due_at.tzinfo is None:
                due_at = due_at.replace(tzinfo=timezone.utc)
            else:
                due_at = due_at.astimezone(timezone.utc)

            if due_at <= datetime.now(timezone.utc):
                raise ValueError("La scadenza deve essere futura.")

            self.due_at = due_at

        return self


class QuizAssignmentUpdate(BaseModel):
    department: str | None = None
    course: str | None = None
    subject: str | None = None
    title: str | None = None
    description: str | None = None
    selection_mode: str | None = None
    arguments: list[str] | None = None
    question_ids: list[str] | None = None
    question_count: int | None = Field(default=None, ge=1)
    time_limit_seconds: int | None = Field(default=None, ge=1)
    due_at: datetime | None = None
    user_ids: list[int] | None = None
    group_ids: list[int] | None = None
    is_active: bool | None = None

    @field_validator("department", "course", "subject", "title")
    @classmethod
    def validate_optional_required_text(cls, value: str | None) -> str | None:
        if value is None:
            return None
        value = value.strip()
        if not value:
            raise ValueError("Il valore non può essere vuoto.")
        return value

    @field_validator("description")
    @classmethod
    def validate_description(cls, value: str | None) -> str | None:
        if value is None:
            return None
        value = value.strip()
        return value or None

    @field_validator("selection_mode")
    @classmethod
    def validate_selection_mode(cls, value: str | None) -> str | None:
        if value is None:
            return None

        value = value.strip().lower()
        allowed = {"random", "arguments", "selected_questions"}

        if value not in allowed:
            raise ValueError("Modalità di selezione quiz non valida.")

        return value

    @field_validator("arguments")
    @classmethod
    def normalize_arguments(cls, value: list[str] | None) -> list[str] | None:
        if value is None:
            return None

        result: list[str] = []

        for argument in value:
            normalized = str(argument).strip()
            if normalized and normalized not in result:
                result.append(normalized)

        return result

    @field_validator("question_ids")
    @classmethod
    def normalize_question_ids(
        cls,
        value: list[str] | None,
    ) -> list[str] | None:
        if value is None:
            return None

        result: list[str] = []

        for question_id in value:
            normalized = str(question_id).strip()
            if normalized and normalized not in result:
                result.append(normalized)

        return result

    @field_validator("user_ids", "group_ids")
    @classmethod
    def normalize_ids(cls, value: list[int] | None) -> list[int] | None:
        if value is None:
            return None

        result: list[int] = []

        for item in value:
            if item > 0 and item not in result:
                result.append(item)

        return result

    @field_validator("due_at")
    @classmethod
    def normalize_due_at(cls, value: datetime | None) -> datetime | None:
        if value is None:
            return None

        if value.tzinfo is None:
            value = value.replace(tzinfo=timezone.utc)
        else:
            value = value.astimezone(timezone.utc)

        if value <= datetime.now(timezone.utc):
            raise ValueError("La scadenza deve essere futura.")

        return value


class QuizAssignmentRecipientResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    user_id: int | None
    group_id: int | None
    created_at: datetime


class QuizAssignmentResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    teacher_id: int
    subject_id: int
    department: str
    course: str
    subject: str
    title: str
    description: str | None
    selection_mode: str
    selected_arguments: list[str] = Field(default_factory=list)
    selected_question_ids: list[str] = Field(default_factory=list)
    question_count: int
    time_limit_seconds: int | None
    due_at: datetime | None
    is_active: bool
    created_at: datetime
    updated_at: datetime
    recipients: list[QuizAssignmentRecipientResponse] = Field(default_factory=list)


class StudentAssignedQuizResponse(QuizAssignmentResponse):
    is_expired: bool = False
    can_start: bool = True
    attempt_id: int | None = None
    is_completed: bool = False
    is_in_progress: bool = False
from datetime import (
    datetime,
)

from typing import (
    Any,
)

from pydantic import (
    BaseModel,
    ConfigDict,
    Field,
    field_validator,
    model_validator,
)


class QuizAttemptStart(BaseModel):
    department: str
    course: str
    subject: str

    arguments: list[str] = Field(
        default_factory=list,
    )

    all_arguments: bool = False

    number_of_questions: int = Field(
        ge=1,
    )

    time_limit_seconds: int | None = Field(
        default=None,
        ge=1,
    )

    @field_validator(
        "department",
        "course",
        "subject",
    )
    @classmethod
    def validate_text(
        cls,
        value: str,
    ) -> str:
        value = value.strip()

        if not value:
            raise ValueError(
                "Il valore non può essere vuoto."
            )

        return value

    @field_validator(
        "arguments",
    )
    @classmethod
    def validate_arguments(
        cls,
        value: list[str],
    ) -> list[str]:
        result = []

        for argument in value:
            argument = argument.strip()

            if not argument:
                continue

            if argument not in result:
                result.append(
                    argument
                )

        return result


class QuizAnswerSubmit(BaseModel):
    question_id: str

    selected_option_id: str | None = None

    response_time_seconds: int | None = Field(
        default=None,
        ge=0,
    )

    @field_validator(
        "question_id",
    )
    @classmethod
    def validate_question_id(
        cls,
        value: str,
    ) -> str:
        value = value.strip()

        if not value:
            raise ValueError(
                "ID domanda non valido."
            )

        return value

    @field_validator(
        "selected_option_id",
    )
    @classmethod
    def validate_option_id(
        cls,
        value: str | None,
    ) -> str | None:
        if value is None:
            return None

        value = value.strip()

        if not value:
            return None

        return value


class QuizAttemptSubmit(BaseModel):
    answers: list[
        QuizAnswerSubmit
    ] = Field(
        default_factory=list,
    )

    elapsed_seconds: int | None = Field(
        default=None,
        ge=0,
    )

    @model_validator(
        mode="after",
    )
    def validate_answers(
        self,
    ):
        ids = [
            answer.question_id
            for answer in self.answers
        ]

        if len(ids) != len(
            set(ids)
        ):
            raise ValueError(
                "Una domanda non può essere inviata più volte."
            )

        return self


class QuizQuestionAttachmentPublic(
    BaseModel
):
    id: str | None = None

    type: str

    original_name: str

    mime_type: str

    stored_name: str


class QuizQuestionPublic(BaseModel):
    id_question: str

    estimed_time: (
        str
        | int
        | None
    ) = None

    metadata: dict[
        str,
        Any,
    ] = Field(
        default_factory=dict,
    )

    text: str

    attachments: list[
        QuizQuestionAttachmentPublic
    ] = Field(
        default_factory=list,
    )

    option: list[
        dict[str, Any]
    ] = Field(
        default_factory=list,
    )


class QuizAttemptStartResponse(BaseModel):
    attempt_id: int

    assignment_id: int | None = None

    department: str

    course: str

    subject: str

    arguments: list[str] = Field(
        default_factory=list,
    )

    question_count: int

    time_limit_seconds: int | None

    started_at: datetime

    questions: list[
        QuizQuestionPublic
    ] = Field(
        default_factory=list,
    )


class QuizAttemptAnswerResponse(BaseModel):
    model_config = ConfigDict(
        from_attributes=True,
    )

    id: int

    question_id: str

    argument: str | None

    question_text: str

    attachments_snapshot: list[
        dict[str, Any]
    ] = Field(
        default_factory=list,
    )

    options_snapshot: list[
        dict[str, Any]
    ] = Field(
        default_factory=list,
    )

    selected_option_id: str | None

    selected_option_text: str | None

    correct_option_id: str

    correct_option_text: str

    is_answered: bool

    is_correct: bool | None

    response_time_seconds: int | None

    formal_explanation: str | None

    informal_explanation: str | None

    selected_answer_explanation: str | None

    correct_answer_explanation: str | None


class QuizAttemptResponse(BaseModel):
    model_config = ConfigDict(
        from_attributes=True,
    )

    id: int

    user_id: int

    assignment_id: int | None = None

    department: str

    course: str

    subject: str

    selected_arguments: list[str] = Field(
        default_factory=list,
    )

    question_count: int

    correct_count: int

    wrong_count: int

    unanswered_count: int

    percentage: float

    time_limit_seconds: int | None

    elapsed_seconds: int | None

    status: str

    started_at: datetime

    completed_at: datetime | None

    is_hidden_from_history: bool

    created_at: datetime


class QuizAttemptDetailResponse(
    QuizAttemptResponse
):
    answers: list[
        QuizAttemptAnswerResponse
    ] = Field(
        default_factory=list,
    )


class QuizAttemptHistoryResponse(
    BaseModel
):
    total: int

    attempts: list[
        QuizAttemptResponse
    ] = Field(
        default_factory=list,
    )
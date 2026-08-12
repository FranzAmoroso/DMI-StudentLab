from pydantic import BaseModel, Field


class Filter(BaseModel):
    department: str
    course: str
    sub: str
    arguments: list[str] = Field(default_factory=list)
    number_of_questions: int | None = None


class Answer(BaseModel):
    idQuestion: str
    idChoice: str
    department: str
    sub: str


class QuestionCountRequest(BaseModel):
    department: str
    course: str
    sub: str
    arguments: list[str] = Field(default_factory=list)

class SubjectRequest(BaseModel):
    department: str
    course: str

class ArgumentsRequest(BaseModel):
    department: str
    course: str
    sub: str
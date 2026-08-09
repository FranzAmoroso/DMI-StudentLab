from pydantic import BaseModel

class Filter(BaseModel):
    department: str
    course: str
    sub: str
    argoment: str | None = None
    tot: int | None = None

class Answer(BaseModel):
    idQuestion: str
    idChoice: str
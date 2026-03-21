from pydantic import BaseModel

class Filter(BaseModel):
    department: str
    course: str
    sub: str

class Answer(BaseModel):
    idQuestion: str
    idChoice: str
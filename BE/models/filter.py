from pydantic import BaseModel

class Filter(BaseModel):
    dipartimento: str
    corso: str
    materia: str

class Answer(BaseModel):
    id_domanda: str
    id_scelta: str
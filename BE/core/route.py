from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from models.filter import Filter,Answer
from services.filter import shuffle_filter,validate_answer

router = APIRouter()

@router.post("/send")
async def send_quest(filter: Filter):
    try:
        question = shuffle_filter(filter.dipartimento, filter.corso, filter.materia)
        return {"success":True,"question":question}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/validate")
async def validate_quest(id : Answer):
        outcome = validate_answer(id.id_domanda, id.id_scelta)
        if outcome is None:
            raise HTTPException(status_code=404,detail="Domanda non trovata")
        return {
            "corretto":outcome,
            "messaggio":"Ottimo lavoro!" if outcome else "Risposta errata."
        }





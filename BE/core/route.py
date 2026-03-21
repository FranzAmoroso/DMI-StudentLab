from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from models.filter import Filter,Answer
from services.filter import shuffle_filter,validate_answer

router = APIRouter()

@router.post("/send")
async def send_quest(filter: Filter):
    try:
        print(filter)
        question = shuffle_filter(filter.department, filter.course, filter.sub)
        return {"success":True,"question":question}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/validate")
async def validate_quest(id : Answer):
        outcome = validate_answer(id.idQuestion, id.idChoice)
        if outcome is None:
            raise HTTPException(status_code=404,detail="Question not founded")
        return {
            "correct":outcome,
            "message":"Ottimo lavoro!" if outcome else "Risposta errata."
        }





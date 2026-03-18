from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from models.filter import Filter,Answer
from services.filter import shuffle_filter,validation

app = FastAPI()

@app.post("/{filter.dipartimento}{filter.corso}{filter.materia}")
async def send_quest(filter: Filter):
    try:
        question = shuffle_filter(filter.dipartimento, filter.corso, filter.materia)
        return {"success":True,"question":question}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/{filter.dipartimento}{filter.corso}{filter.materia}")
async def validate_quest(id : Answer):
        outcome = validation(id.id_domanda, id.id_scelta)
        if outcome is None:
            raise HTTPException(status_code=404,detail="Domanda non trovata")
        return {
            "corretto":outcome,
            "messaggio":"Ottimo lavoro!" if outcome else "Risposta errata."
        }





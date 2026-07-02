from fastapi.middleware.cors import CORSMiddleware
from fastapi import FastAPI
from core.route import router 
from services.filter import shuffle_filter, validate_answer
app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"]
)

app.include_router(router, prefix="")

@app.get("/")
async def root():
    return {"status":"Server attivo."}

@app.get("/shuffle_filter")
def api_shuffle_filter(department: str, course: str, sub: str):
    return shuffle_filter(department, course, sub)

@app.post("/validate_answer")
def api_validate_answer(idQuestion: str, idChoice: str):
    return validate_answer(idQuestion, idChoice)

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

from core.route import router

from services.filter import (
    shuffle_filter,
    validate_answer,
    arguments,
    question_count,
    subjects,
)

from models.request_models import Filter, Answer, QuestionCountRequest


app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(router, prefix="")

@app.get("/")
async def root():
    return {
        "status": "Server attivo."
    }

@app.post("/shuffle_filter")
def api_shuffle_filter(request: Filter):
    return shuffle_filter(
        request.department,
        request.course,
        request.sub,
        request.arguments,
        request.number_of_questions,
    )

@app.post("/validate_answer")
def api_validate_answer(answer: Answer):
    return validate_answer(
        answer.idQuestion,
        answer.idChoice,
        answer.department,
        answer.sub,
    )

@app.post("/arguments")
def api_arguments(
    department: str,
    course: str,
    sub: str,
):
    return arguments(
        department,
        course,
        sub,
    )

@app.post("/question_count")
def api_question_count(
    request: QuestionCountRequest,
):

    count = question_count(
        request.department,
        request.course,
        request.sub,
        request.selected_arguments,
    )

    return {
        "count": count
    }

    @app.post("/subjects")
    def api_subjects(
        department: str,
        course: str,
    ):
        return subjects(
            department,
            course,
        )
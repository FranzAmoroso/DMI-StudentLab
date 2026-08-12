import json
import random
import os
from pathlib import Path
def shuffle_filter(
    department,
    course,
    sub,
    selected_arguments=None,
    number_of_questions=None
):
    path = os.path.join(
        "data",
        department.lower(),
        "question",
        f"{sub}.json"
    )

    with open(path, "r", encoding="utf-8") as file:
        all_questions = json.load(file)

    filtered = [
        question
        for question in all_questions
        if question.get("metadata", {}).get("department") == department
        and question.get("metadata", {}).get("course") == course
        and question.get("metadata", {}).get("sub") == sub
    ]

    if selected_arguments:
        filtered = [
            question
            for question in filtered
            if question.get("metadata", {}).get("argoment")
            in selected_arguments
        ]

    random.shuffle(filtered)

    if number_of_questions is not None:
        filtered = filtered[:number_of_questions]

    for question in filtered:
        random.shuffle(question["option"])

    return filtered

def validate_answer(idQuestion, idChoice, department, sub):
    path = os.path.join(
        "data",
        department.lower(),
        "question",
        f"{sub}.json"
    )

    with open(path, "r", encoding="utf-8") as file:
        all_questions = json.load(file)

    for question in all_questions:
        if str(question["id_question"]) == str(idQuestion):
            return str(question["id_correct"]) == str(idChoice)

    return None

def arguments(department, course, sub):
    path = os.path.join(
        "data",
        department.lower(),
        "question",
        f"{sub}.json"
    )

    with open(path, "r", encoding="utf-8") as file:
        all_questions = json.load(file)

    arguments = {
        question["metadata"]["argoment"]
        for question in all_questions
        if question.get("metadata", {}).get("argoment")
    }

    return sorted(arguments)

def question_count(department, course, sub, selected_arguments):
    path = os.path.join(
        "data",
        department.lower(),
        "question",
        f"{sub}.json"
    )

    with open(path, "r", encoding="utf-8") as file:
        all_questions = json.load(file)

    count = sum(
        1
        for question in all_questions
        if question.get("metadata", {}).get("department") == department
        and question.get("metadata", {}).get("course") == course
        and question.get("metadata", {}).get("sub") == sub
        and question.get("metadata", {}).get("argoment")
            in selected_arguments
    )

    return count

def subjects(
    department,
    course,
):
    question_path = os.path.join(
        "data",
        department.lower(),
        "question",
    )

    if not os.path.exists(question_path):
        return []

    available_subjects = []

    for filename in os.listdir(question_path):

        if not filename.endswith(".json"):
            continue

        path = os.path.join(
            question_path,
            filename,
        )

        try:
            with open(
                path,
                "r",
                encoding="utf-8",
            ) as file:
                all_questions = json.load(file)

            for question in all_questions:

                metadata = question.get(
                    "metadata",
                    {},
                )

                if (
                    metadata.get("department") == department
                    and metadata.get("course") == course
                    and metadata.get("sub")
                ):
                    available_subjects.append(
                        metadata["sub"]
                    )
                    break

        except (json.JSONDecodeError, OSError):
            continue

    return sorted(set(available_subjects))
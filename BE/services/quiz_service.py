import json
import random
import re
from copy import deepcopy
from pathlib import Path
from typing import Any


DATA_ROOT = Path("data")


def _normalize_directory(value: str) -> str:
    return value.strip().lower()


def _normalize_subject(value: str) -> str:
    """
    Converte il nome visualizzato della materia nel nome canonico del JSON.

    Esempi:
        Programmazione 1 -> programmazione_1
        Reti di Calcolatori -> reti_di_calcolatori
        Interazione-e-Multimedia -> interazione_e_multimedia
    """
    value = value.strip().lower()
    value = re.sub(r"[\s\-]+", "_", value)
    value = re.sub(r"_+", "_", value)
    return value.strip("_")


def _display_subject_from_stem(value: str) -> str:
    value = value.strip().replace("_", " ")
    value = re.sub(r"\s+", " ", value)
    return value.strip()


def _question_directories(
    department: str,
    course: str,
) -> list[Path]:
    """
    Supporta sia la directory storica `question/` sia `questions/`.
    La prima resta quella canonica per compatibilità.
    """
    department_slug = _normalize_directory(department)
    course_slug = _normalize_directory(course)
    base = DATA_ROOT / department_slug / course_slug
    return [base / "question", base / "questions"]


def _question_directory(
    department: str,
    course: str,
) -> Path:
    """
    Directory canonica usata per nuove scritture.
    """
    return _question_directories(department, course)[0]


def _question_file_path(
    department: str,
    course: str,
    subject: str,
) -> Path:
    """
    Risolve il file JSON della materia.

    Esempio:
        subject = "Programmazione 1"
        -> programmazione_1.json

    Cerca prima il nome canonico esatto e poi esegue un fallback
    case-insensitive/normalizzato sugli stem presenti.
    """
    subject_slug = _normalize_subject(subject)
    directories = _question_directories(department, course)

    for directory in directories:
        exact = directory / f"{subject_slug}.json"
        if exact.is_file():
            return exact

    for directory in directories:
        if not directory.is_dir():
            continue
        for file_path in directory.glob("*.json"):
            if not file_path.is_file():
                continue
            if _normalize_subject(file_path.stem) == subject_slug:
                return file_path

    return directories[0] / f"{subject_slug}.json"


def load_questions(
    department: str,
    course: str,
    subject: str,
) -> list[dict[str, Any]]:
    path = _question_file_path(
        department=department,
        course=course,
        subject=subject,
    )

    if not path.is_file():
        return []

    try:
        with path.open("r", encoding="utf-8") as file:
            data = json.load(file)
    except (OSError, json.JSONDecodeError):
        return []

    if not isinstance(data, list):
        return []

    return [
        question
        for question in data
        if isinstance(question, dict)
    ]


def _is_question_available(
    question: dict[str, Any],
) -> bool:
    if question.get("is_hidden", False):
        return False
    if question.get("is_active", True) is False:
        return False
    return True


def _filter_by_arguments(
    questions: list[dict[str, Any]],
    selected_arguments: list[str] | None = None,
) -> list[dict[str, Any]]:
    selected_arguments = selected_arguments or []

    if not selected_arguments:
        return list(questions)

    selected = {
        argument.strip()
        for argument in selected_arguments
        if argument and argument.strip()
    }

    return [
        question
        for question in questions
        if question.get("metadata", {}).get("argoment") in selected
    ]


def shuffle_filter(
    department: str,
    course: str,
    subject: str,
    selected_arguments: list[str] | None = None,
    number_of_questions: int | None = None,
) -> list[dict[str, Any]]:
    all_questions = load_questions(
        department=department,
        course=course,
        subject=subject,
    )

    available_questions = [
        question
        for question in all_questions
        if _is_question_available(question)
    ]

    filtered_questions = _filter_by_arguments(
        questions=available_questions,
        selected_arguments=selected_arguments,
    )

    result = deepcopy(filtered_questions)
    random.shuffle(result)

    if number_of_questions is not None:
        number_of_questions = max(0, number_of_questions)
        result = result[:number_of_questions]

    for question in result:
        options = question.get("option")
        if isinstance(options, list):
            random.shuffle(options)

    return result


def validate_answer(
    id_question: str,
    id_choice: str,
    department: str,
    course: str,
    subject: str,
) -> dict[str, Any] | None:
    all_questions = load_questions(
        department=department,
        course=course,
        subject=subject,
    )

    for question in all_questions:
        question_id = question.get("id_question")

        if str(question_id) != str(id_question):
            continue

        correct_option_id = question.get("id_correct")
        if correct_option_id is None:
            return None

        selected_option_id = str(id_choice)
        correct_option_id = str(correct_option_id)

        response_explanations = question.get(
            "question_response_explanation",
            {},
        )

        if not isinstance(response_explanations, dict):
            response_explanations = {}

        return {
            "question_id": str(question_id),
            "selected_option_id": selected_option_id,
            "correct_option_id": correct_option_id,
            "is_correct": selected_option_id == correct_option_id,
            "formal_explanation": question.get("formal_explanation"),
            "informal_explanation": question.get("informal_explanation"),
            "selected_answer_explanation": response_explanations.get(
                selected_option_id
            ),
            "correct_answer_explanation": response_explanations.get(
                correct_option_id
            ),
            "answer_explanations": response_explanations,
        }

    return None


def arguments(
    department: str,
    course: str,
    subject: str,
) -> list[str]:
    all_questions = load_questions(
        department=department,
        course=course,
        subject=subject,
    )

    result: set[str] = set()

    for question in all_questions:
        if not _is_question_available(question):
            continue

        metadata = question.get("metadata", {})
        if not isinstance(metadata, dict):
            continue

        argument = metadata.get("argoment")
        if isinstance(argument, str) and argument.strip():
            result.add(argument.strip())

    return sorted(result, key=str.casefold)


def question_count(
    department: str,
    course: str,
    subject: str,
    selected_arguments: list[str] | None = None,
) -> int:
    all_questions = load_questions(
        department=department,
        course=course,
        subject=subject,
    )

    available_questions = [
        question
        for question in all_questions
        if _is_question_available(question)
    ]

    filtered_questions = _filter_by_arguments(
        questions=available_questions,
        selected_arguments=selected_arguments,
    )

    return len(filtered_questions)


def subjects(
    department: str,
    course: str,
) -> list[str]:
    """
    Restituisce tutte le materie per cui esiste un JSON valido.

    Esempio:
        programmazione_1.json -> Programmazione 1 lato client
        reti_di_calcolatori.json -> Reti di Calcolatori lato client

    I duplicati tra `question/` e `questions/` vengono rimossi
    usando la forma normalizzata del nome.
    """
    result_by_key: dict[str, str] = {}

    for path in _question_directories(
        department=department,
        course=course,
    ):
        if not path.is_dir():
            continue

        for file_path in path.glob("*.json"):
            if not file_path.is_file():
                continue

            try:
                with file_path.open("r", encoding="utf-8") as file:
                    data = json.load(file)

                if not isinstance(data, list):
                    continue
            except (OSError, json.JSONDecodeError):
                continue

            display_name = _display_subject_from_stem(file_path.stem)
            key = _normalize_subject(display_name)

            if display_name and key and key not in result_by_key:
                result_by_key[key] = display_name

    return sorted(
        result_by_key.values(),
        key=str.casefold,
    )

import random

from copy import deepcopy
from datetime import datetime, timezone

from sqlalchemy.orm import Session, joinedload

from models.quiz_attempt import QuizAttempt, QuizAttemptAnswer
from models.user import User

from schemas.quiz_attempt import QuizAttemptStart, QuizAttemptSubmit

from services.notification import (
    update_user_notification_action_status_by_resource,
)
from services.quiz_assignment_service import (
    can_user_access_quiz_assignment,
    get_quiz_assignment_by_id,
)
from services.quiz_service import (
    find_question,
    question_count,
    shuffle_filter,
)


def utc_now() -> datetime:
    return datetime.now(timezone.utc)


def _as_utc(
    value: datetime | None,
) -> datetime | None:
    if value is None:
        return None

    if value.tzinfo is None:
        return value.replace(
            tzinfo=timezone.utc
        )

    return value.astimezone(
        timezone.utc
    )


def _get_question_metadata(
    question: dict,
) -> dict:
    metadata = question.get(
        "metadata",
        {}
    )

    if not isinstance(
        metadata,
        dict,
    ):
        return {}

    return metadata


def _get_question_attachments(
    question: dict,
) -> list[dict]:
    attachments = question.get(
        "attachments",
        []
    )

    if not isinstance(
        attachments,
        list,
    ):
        return []

    return [
        attachment
        for attachment in attachments
        if isinstance(
            attachment,
            dict,
        )
    ]


def _get_question_options(
    question: dict,
) -> list[dict]:
    options = question.get(
        "option",
        []
    )

    if not isinstance(
        options,
        list,
    ):
        return []

    return [
        option
        for option in options
        if isinstance(
            option,
            dict,
        )
    ]


def _get_option_text(
    question: dict,
    option_id: str | None,
) -> str | None:
    if option_id is None:
        return None

    for option in _get_question_options(
        question
    ):
        if (
            str(
                option.get(
                    "id"
                )
            )
            ==
            str(
                option_id
            )
        ):
            return str(
                option.get(
                    "text",
                    ""
                )
            )

    return None


def _prepare_question_snapshot(
    question: dict,
) -> dict:
    snapshot = deepcopy(
        question
    )

    snapshot["metadata"] = deepcopy(
        _get_question_metadata(
            question
        )
    )

    snapshot["attachments"] = deepcopy(
        _get_question_attachments(
            question
        )
    )

    options = deepcopy(
        _get_question_options(
            question
        )
    )

    random.shuffle(
        options
    )

    snapshot["option"] = options

    return snapshot


def _public_question(
    question: dict,
) -> dict:
    return {
        "id_question": str(
            question.get(
                "id_question"
            )
        ),
        "estimed_time": question.get(
            "estimed_time"
        ),
        "metadata": _get_question_metadata(
            question
        ),
        "text": str(
            question.get(
                "text",
                ""
            )
        ),
        "attachments": _get_question_attachments(
            question
        ),
        "option": _get_question_options(
            question
        ),
    }


def _get_snapshot_question(
    attempt: QuizAttempt,
    question_id: str,
) -> dict | None:
    snapshots = (
        attempt.questions_snapshot
        or []
    )

    if not isinstance(
        snapshots,
        list,
    ):
        return None

    for question in snapshots:
        if not isinstance(
            question,
            dict,
        ):
            continue

        if (
            str(
                question.get(
                    "id_question"
                )
            )
            ==
            str(
                question_id
            )
        ):
            return question

    return None


def _get_attempt_question(
    attempt: QuizAttempt,
    question_id: str,
) -> dict | None:
    question = _get_snapshot_question(
        attempt,
        question_id,
    )

    if question is not None:
        return question

    return find_question(
        id_question=question_id,
        department=attempt.department,
        course=attempt.course,
        subject=attempt.subject,
        include_hidden=True,
    )


def get_quiz_attempt_by_id(
    db: Session,
    attempt_id: int,
) -> QuizAttempt | None:
    return (
        db.query(
            QuizAttempt
        )
        .options(
            joinedload(
                QuizAttempt.answers
            )
        )
        .filter(
            QuizAttempt.id
            == attempt_id
        )
        .first()
    )


def _create_quiz_attempt(
    db: Session,
    user: User,
    *,
    department: str,
    course: str,
    subject: str,
    questions: list[dict],
    time_limit_seconds: int | None,
    assignment_id: int | None = None,
):
    if not questions:
        raise ValueError(
            "Il quiz non contiene domande."
        )

    snapshots = [
        _prepare_question_snapshot(
            question
        )
        for question in questions
    ]

    question_ids = [
        str(
            question.get(
                "id_question"
            )
        )
        for question in snapshots
    ]

    arguments: list[str] = []

    for question in snapshots:
        metadata = _get_question_metadata(
            question
        )

        argument = metadata.get(
            "argoment"
        )

        if not isinstance(
            argument,
            str,
        ):
            continue

        argument = argument.strip()

        if (
            argument
            and argument not in arguments
        ):
            arguments.append(
                argument
            )

    attempt = QuizAttempt(
        user_id=user.id,
        assignment_id=assignment_id,
        department=department,
        course=course,
        subject=subject,
        selected_arguments=arguments,
        question_ids=question_ids,
        questions_snapshot=snapshots,
        question_count=len(
            snapshots
        ),
        correct_count=0,
        wrong_count=0,
        unanswered_count=len(
            snapshots
        ),
        percentage=0.0,
        time_limit_seconds=time_limit_seconds,
        elapsed_seconds=None,
        status="in_progress",
        started_at=utc_now(),
        completed_at=None,
        is_hidden_from_history=False,
        is_deleted=False,
    )

    try:
        db.add(
            attempt
        )
        db.commit()
        db.refresh(
            attempt
        )
    except Exception:
        db.rollback()
        raise

    return {
        "attempt_id": attempt.id,
        "assignment_id": attempt.assignment_id,
        "department": attempt.department,
        "course": attempt.course,
        "subject": attempt.subject,
        "arguments": (
            attempt.selected_arguments
            or []
        ),
        "question_count": attempt.question_count,
        "time_limit_seconds": attempt.time_limit_seconds,
        "started_at": attempt.started_at,
        "questions": [
            _public_question(
                question
            )
            for question in snapshots
        ],
    }


def start_quiz_attempt(
    db: Session,
    user: User,
    data: QuizAttemptStart,
):
    selected_arguments = (
        []
        if data.all_arguments
        else data.arguments
    )

    available_count = question_count(
        department=data.department,
        course=data.course,
        subject=data.subject,
        selected_arguments=selected_arguments,
    )

    if available_count <= 0:
        raise ValueError(
            "Non ci sono domande disponibili per i filtri selezionati."
        )

    if (
        data.number_of_questions
        > available_count
    ):
        raise ValueError(
            f"Il numero massimo di domande disponibili è {available_count}."
        )

    questions = shuffle_filter(
        department=data.department,
        course=data.course,
        subject=data.subject,
        selected_arguments=selected_arguments,
        number_of_questions=data.number_of_questions,
    )

    if (
        len(
            questions
        )
        != data.number_of_questions
    ):
        raise ValueError(
            "Non è stato possibile generare il numero richiesto di domande."
        )

    return _create_quiz_attempt(
        db,
        user,
        assignment_id=None,
        department=data.department,
        course=data.course,
        subject=data.subject,
        questions=questions,
        time_limit_seconds=data.time_limit_seconds,
    )


def start_assigned_quiz_attempt(
    db: Session,
    user: User,
    assignment_id: int,
):
    assignment = get_quiz_assignment_by_id(
        db,
        assignment_id,
    )

    if assignment is None:
        raise ValueError(
            "Assegnazione non trovata."
        )

    if not assignment.is_active:
        raise ValueError(
            "Questa assegnazione non è più attiva."
        )

    due_at = _as_utc(
        assignment.due_at
    )

    if (
        due_at is not None
        and due_at <= utc_now()
    ):
        raise ValueError(
            "Questa assegnazione è scaduta."
        )

    if not can_user_access_quiz_assignment(
        db,
        assignment.id,
        user.id,
    ):
        raise PermissionError(
            "Non puoi svolgere questa assegnazione."
        )

    existing_attempt = (
        db.query(
            QuizAttempt
        )
        .filter(
            QuizAttempt.user_id
            == user.id,
            QuizAttempt.assignment_id
            == assignment.id,
            QuizAttempt.is_deleted.is_(
                False
            ),
        )
        .first()
    )

    if existing_attempt is not None:
        if (
            existing_attempt.status
            == "completed"
        ):
            raise ValueError(
                "Hai già completato questo quiz assegnato."
            )

        raise ValueError(
            "Hai già un tentativo in corso per questo quiz."
        )

    if (
        assignment.selection_mode
        == "selected_questions"
    ):
        questions: list[dict] = []

        question_ids = (
            assignment.selected_question_ids
            or []
        )

        for question_id in question_ids:
            question = find_question(
                id_question=str(
                    question_id
                ),
                department=assignment.department,
                course=assignment.course,
                subject=assignment.subject,
                include_hidden=False,
            )

            if question is None:
                raise ValueError(
                    f"La domanda {question_id} non è più disponibile."
                )

            questions.append(
                question
            )
    else:
        selected_arguments: list[str] = []

        if (
            assignment.selection_mode
            == "arguments"
        ):
            selected_arguments = (
                assignment.selected_arguments
                or []
            )

        available_count = question_count(
            department=assignment.department,
            course=assignment.course,
            subject=assignment.subject,
            selected_arguments=selected_arguments,
        )

        if (
            available_count
            < assignment.question_count
        ):
            raise ValueError(
                "Non ci sono più abbastanza domande disponibili per questo quiz."
            )

        questions = shuffle_filter(
            department=assignment.department,
            course=assignment.course,
            subject=assignment.subject,
            selected_arguments=selected_arguments,
            number_of_questions=assignment.question_count,
        )

    if (
        len(
            questions
        )
        != assignment.question_count
    ):
        raise ValueError(
            "Non è stato possibile generare il quiz assegnato."
        )

    return _create_quiz_attempt(
        db,
        user,
        assignment_id=assignment.id,
        department=assignment.department,
        course=assignment.course,
        subject=assignment.subject,
        questions=questions,
        time_limit_seconds=assignment.time_limit_seconds,
    )


def complete_quiz_attempt(
    db: Session,
    user: User,
    attempt_id: int,
    data: QuizAttemptSubmit,
):
    attempt = get_quiz_attempt_by_id(
        db,
        attempt_id,
    )

    if attempt is None:
        raise ValueError(
            "Tentativo non trovato."
        )

    if (
        attempt.user_id
        != user.id
    ):
        raise PermissionError(
            "Non puoi modificare questo tentativo."
        )

    if attempt.is_deleted:
        raise ValueError(
            "Tentativo non trovato."
        )

    if (
        attempt.status
        != "in_progress"
    ):
        raise ValueError(
            "Il quiz è già stato completato."
        )

    allowed_question_ids = {
        str(
            question_id
        )
        for question_id in (
            attempt.question_ids
            or []
        )
    }

    submitted_ids = {
        str(
            answer.question_id
        )
        for answer in data.answers
    }

    if not submitted_ids.issubset(
        allowed_question_ids
    ):
        raise ValueError(
            "Sono state inviate domande non appartenenti al quiz."
        )

    if (
        len(
            data.answers
        )
        > attempt.question_count
    ):
        raise ValueError(
            "Numero di risposte non valido."
        )

    answers_by_id = {
        str(
            answer.question_id
        ): answer
        for answer in data.answers
    }

    saved_answers: list[
        QuizAttemptAnswer
    ] = []

    correct_count = 0
    wrong_count = 0
    unanswered_count = 0

    for question_id in (
        attempt.question_ids
        or []
    ):
        question_id = str(
            question_id
        )

        question = _get_attempt_question(
            attempt,
            question_id,
        )

        if question is None:
            raise ValueError(
                f"La domanda {question_id} non è più disponibile."
            )

        submitted = answers_by_id.get(
            question_id
        )

        selected_option_id = (
            submitted.selected_option_id
            if submitted is not None
            else None
        )

        response_time_seconds = (
            submitted.response_time_seconds
            if submitted is not None
            else None
        )

        raw_correct_option_id = question.get(
            "id_correct"
        )

        if raw_correct_option_id is None:
            raise ValueError(
                f"La domanda {question_id} non contiene una risposta corretta."
            )

        correct_option_id = str(
            raw_correct_option_id
        ).strip()

        correct_option_text = _get_option_text(
            question,
            correct_option_id,
        )

        if correct_option_text is None:
            raise ValueError(
                f"La domanda {question_id} non contiene una risposta corretta valida."
            )

        is_answered = (
            selected_option_id
            is not None
        )

        selected_option_text = None
        is_correct = None

        if is_answered:
            selected_option_id = str(
                selected_option_id
            ).strip()

            selected_option_text = _get_option_text(
                question,
                selected_option_id,
            )

            if selected_option_text is None:
                raise ValueError(
                    f"Risposta non valida per la domanda {question_id}."
                )

            is_correct = (
                selected_option_id
                == correct_option_id
            )

            if is_correct:
                correct_count += 1
            else:
                wrong_count += 1
        else:
            unanswered_count += 1

        explanations = question.get(
            "question_response_explanation",
            {},
        )

        if not isinstance(
            explanations,
            dict,
        ):
            explanations = {}

        metadata = _get_question_metadata(
            question
        )

        argument = metadata.get(
            "argoment"
        )

        if not isinstance(
            argument,
            str,
        ):
            argument = None

        answer_record = QuizAttemptAnswer(
            attempt_id=attempt.id,
            question_id=question_id,
            argument=argument,
            question_text=str(
                question.get(
                    "text",
                    ""
                )
            ),
            attachments_snapshot=deepcopy(
                _get_question_attachments(
                    question
                )
            ),
            options_snapshot=deepcopy(
                _get_question_options(
                    question
                )
            ),
            selected_option_id=selected_option_id,
            selected_option_text=selected_option_text,
            correct_option_id=correct_option_id,
            correct_option_text=correct_option_text,
            is_answered=is_answered,
            is_correct=is_correct,
            response_time_seconds=response_time_seconds,
            formal_explanation=question.get(
                "formal_explanation"
            ),
            informal_explanation=question.get(
                "informal_explanation"
            ),
            selected_answer_explanation=(
                explanations.get(
                    selected_option_id
                )
                if selected_option_id
                is not None
                else None
            ),
            correct_answer_explanation=explanations.get(
                correct_option_id
            ),
        )

        saved_answers.append(
            answer_record
        )

    percentage = (
        (
            correct_count
            / attempt.question_count
        )
        * 100
        if attempt.question_count > 0
        else 0.0
    )

    attempt.correct_count = correct_count
    attempt.wrong_count = wrong_count
    attempt.unanswered_count = unanswered_count
    attempt.percentage = round(
        percentage,
        2,
    )
    attempt.elapsed_seconds = (
        data.elapsed_seconds
    )
    attempt.status = "completed"
    attempt.completed_at = utc_now()

    try:
        db.add_all(
            saved_answers
        )

        if attempt.assignment_id is not None:
            update_user_notification_action_status_by_resource(
                db=db,
                user_id=user.id,
                action_type="quiz_assignment",
                action_resource_id=attempt.assignment_id,
                action_status="completed",
                current_statuses={
                    "pending"
                },
                mark_as_read=True,
                commit=False,
            )

        db.commit()

    except Exception:
        db.rollback()
        raise

    return get_quiz_attempt_by_id(
        db,
        attempt.id,
    )


def get_student_quiz_history(
    db: Session,
    user_id: int,
    *,
    include_hidden: bool = False,
    limit: int = 50,
    offset: int = 0,
):
    safe_limit = max(
        1,
        min(
            limit,
            100,
        ),
    )

    safe_offset = max(
        0,
        offset,
    )

    query = (
        db.query(
            QuizAttempt
        )
        .filter(
            QuizAttempt.user_id
            == user_id,
            QuizAttempt.status
            == "completed",
            QuizAttempt.is_deleted.is_(
                False
            ),
        )
    )

    if not include_hidden:
        query = query.filter(
            QuizAttempt
            .is_hidden_from_history
            .is_(
                False
            )
        )

    total = query.count()

    attempts = (
        query
        .order_by(
            QuizAttempt.completed_at.desc(),
            QuizAttempt.id.desc(),
        )
        .offset(
            safe_offset
        )
        .limit(
            safe_limit
        )
        .all()
    )

    return {
        "total": total,
        "attempts": attempts,
    }


def hide_quiz_attempt_from_history(
    db: Session,
    attempt: QuizAttempt,
    actor: User,
):
    if attempt.is_deleted:
        raise ValueError(
            "Tentativo non trovato."
        )

    attempt.is_hidden_from_history = True
    attempt.hidden_from_history_at = utc_now()
    attempt.hidden_from_history_by = actor.id

    try:
        db.commit()
        db.refresh(
            attempt
        )
    except Exception:
        db.rollback()
        raise

    return attempt


def restore_quiz_attempt_to_history(
    db: Session,
    attempt: QuizAttempt,
):
    if attempt.is_deleted:
        raise ValueError(
            "Tentativo non trovato."
        )

    attempt.is_hidden_from_history = False
    attempt.hidden_from_history_at = None
    attempt.hidden_from_history_by = None

    try:
        db.commit()
        db.refresh(
            attempt
        )
    except Exception:
        db.rollback()
        raise

    return attempt


def delete_quiz_attempt(
    db: Session,
    attempt: QuizAttempt,
    actor: User,
):
    if attempt.is_deleted:
        return attempt

    now = utc_now()

    attempt.is_deleted = True
    attempt.deleted_at = now
    attempt.deleted_by = actor.id
    attempt.is_hidden_from_history = True

    if (
        attempt.hidden_from_history_at
        is None
    ):
        attempt.hidden_from_history_at = now

    if (
        attempt.hidden_from_history_by
        is None
    ):
        attempt.hidden_from_history_by = actor.id

    try:
        db.commit()
        db.refresh(
            attempt
        )
    except Exception:
        db.rollback()
        raise

    return attempt
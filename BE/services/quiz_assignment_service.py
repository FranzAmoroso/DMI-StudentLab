from datetime import datetime, timezone

from sqlalchemy import func, or_
from sqlalchemy.orm import Session, joinedload

from models.group import GroupMember, StudyGroup
from models.quiz_assignment import QuizAssignment, QuizAssignmentRecipient
from models.quiz_attempt import QuizAttempt
from models.subject import Subject
from models.teacher_assignment import TeacherAssignment
from models.user import User

from schemas.quiz_assignment import QuizAssignmentCreate, QuizAssignmentUpdate

from services.notification import (
    create_notification,
    update_notifications_action_status_by_resource,
    update_notifications_expiration_by_resource,
    update_user_notification_action_status_by_resource,
)
from services.quiz_service import find_question, question_count


def utc_now() -> datetime:
    return datetime.now(timezone.utc)


def _as_utc(value: datetime | None) -> datetime | None:
    if value is None:
        return None

    if value.tzinfo is None:
        return value.replace(
            tzinfo=timezone.utc
        )

    return value.astimezone(
        timezone.utc
    )


def get_quiz_assignment_by_id(
    db: Session,
    assignment_id: int,
) -> QuizAssignment | None:
    return (
        db.query(QuizAssignment)
        .options(
            joinedload(
                QuizAssignment.recipients
            )
        )
        .filter(
            QuizAssignment.id == assignment_id
        )
        .first()
    )


def _get_subject(
    db: Session,
    department: str,
    course: str,
    subject: str,
) -> Subject | None:
    return (
        db.query(Subject)
        .filter(
            func.lower(
                Subject.department_code
            ) == department.strip().lower(),
            func.lower(
                Subject.course_code
            ) == course.strip().lower(),
            func.lower(
                Subject.name
            ) == subject.strip().lower(),
            Subject.is_active.is_(True),
        )
        .first()
    )


def _require_teacher_subject(
    db: Session,
    actor: User,
    subject_record: Subject,
) -> None:
    if actor.role in {
        "admin",
        "creator",
    }:
        return

    if actor.role != "teacher":
        raise PermissionError(
            "Solo i docenti verificati possono assegnare quiz."
        )

    if (
        actor.teacher_verification_status
        != "verified"
    ):
        raise PermissionError(
            "Il profilo docente non è verificato."
        )

    teacher_assignment = (
        db.query(TeacherAssignment)
        .filter(
            TeacherAssignment.user_id == actor.id,
            TeacherAssignment.subject_id == subject_record.id,
            TeacherAssignment.verification_status == "verified",
            TeacherAssignment.is_current.is_(True),
        )
        .first()
    )

    if teacher_assignment is None:
        raise PermissionError(
            "Non sei autorizzato ad assegnare quiz per questa materia."
        )


def _require_recipient_user(
    db: Session,
    user_id: int,
) -> User:
    user = (
        db.query(User)
        .filter(
            User.id == user_id,
            User.is_active.is_(True),
        )
        .first()
    )

    if user is None:
        raise ValueError(
            f"Utente destinatario {user_id} non trovato o non attivo."
        )

    return user


def _require_group(
    db: Session,
    group_id: int,
) -> StudyGroup:
    group = (
        db.query(StudyGroup)
        .filter(
            StudyGroup.id == group_id
        )
        .first()
    )

    if group is None:
        raise ValueError(
            f"Gruppo {group_id} non trovato."
        )

    return group


def _teacher_can_assign_to_group(
    db: Session,
    actor: User,
    group_id: int,
) -> bool:
    if actor.role in {
        "admin",
        "creator",
    }:
        return True

    member = (
        db.query(GroupMember)
        .filter(
            GroupMember.group_id == group_id,
            GroupMember.user_id == actor.id,
        )
        .first()
    )

    return (
        member is not None
        and member.role in {
            "owner",
            "admin",
        }
    )


def _validate_selected_question_ids(
    department: str,
    course: str,
    subject: str,
    question_ids: list[int],
) -> None:
    if not question_ids:
        raise ValueError(
            "Devi selezionare almeno una domanda."
        )

    seen: set[int] = set()

    for question_id in question_ids:
        if question_id in seen:
            raise ValueError(
                f"La domanda {question_id} è stata selezionata più di una volta."
            )

        seen.add(
            question_id
        )

        question = find_question(
            id_question=question_id,
            department=department,
            course=course,
            subject=subject,
            include_hidden=False,
        )

        if question is None:
            raise ValueError(
                f"La domanda {question_id} non è disponibile."
            )


def _validate_random_question_configuration(
    department: str,
    course: str,
    subject: str,
    selection_mode: str,
    arguments: list[str],
    requested_count: int,
) -> None:
    selected_arguments = (
        arguments
        if selection_mode == "arguments"
        else []
    )

    if (
        selection_mode == "arguments"
        and not selected_arguments
    ):
        raise ValueError(
            "Devi selezionare almeno un argomento."
        )

    if requested_count <= 0:
        raise ValueError(
            "Il numero di domande deve essere maggiore di zero."
        )

    available = question_count(
        department=department,
        course=course,
        subject=subject,
        selected_arguments=selected_arguments,
    )

    if available <= 0:
        raise ValueError(
            "Non ci sono domande disponibili per questa configurazione."
        )

    if requested_count > available:
        raise ValueError(
            f"Il numero massimo di domande disponibili è {available}."
        )


def _validate_assignment_configuration(
    *,
    department: str,
    course: str,
    subject: str,
    selection_mode: str,
    arguments: list[str],
    question_ids: list[int],
    question_count_value: int,
) -> None:
    if selection_mode not in {
        "random",
        "arguments",
        "selected_questions",
    }:
        raise ValueError(
            "Modalità di selezione delle domande non valida."
        )

    if selection_mode == "selected_questions":
        _validate_selected_question_ids(
            department=department,
            course=course,
            subject=subject,
            question_ids=question_ids,
        )
        return

    _validate_random_question_configuration(
        department=department,
        course=course,
        subject=subject,
        selection_mode=selection_mode,
        arguments=arguments,
        requested_count=question_count_value,
    )


def validate_quiz_assignment_questions(
    data: QuizAssignmentCreate,
) -> None:
    _validate_assignment_configuration(
        department=data.department,
        course=data.course,
        subject=data.subject,
        selection_mode=data.selection_mode,
        arguments=list(
            data.arguments
        ),
        question_ids=list(
            data.question_ids
        ),
        question_count_value=data.question_count,
    )


def _normalize_recipient_ids(
    values: list[int],
) -> list[int]:
    return list(
        dict.fromkeys(
            values
        )
    )


def _validate_recipients(
    db: Session,
    actor: User,
    user_ids: list[int],
    group_ids: list[int],
) -> None:
    if (
        not user_ids
        and not group_ids
    ):
        raise ValueError(
            "Devi specificare almeno un destinatario o un gruppo."
        )

    for user_id in user_ids:
        _require_recipient_user(
            db,
            user_id,
        )

    for group_id in group_ids:
        _require_group(
            db,
            group_id,
        )

        if not _teacher_can_assign_to_group(
            db,
            actor,
            group_id,
        ):
            raise PermissionError(
                f"Non puoi assegnare quiz al gruppo {group_id}."
            )


def _get_effective_recipient_user_ids(
    db: Session,
    user_ids: list[int],
    group_ids: list[int],
) -> set[int]:
    result: set[int] = set(
        user_ids
    )

    if group_ids:
        rows = (
            db.query(
                GroupMember.user_id
            )
            .join(
                User,
                User.id == GroupMember.user_id,
            )
            .filter(
                GroupMember.group_id.in_(
                    group_ids
                ),
                User.is_active.is_(True),
            )
            .distinct()
            .all()
        )

        result.update(
            int(row[0])
            for row in rows
        )

    if not result:
        return set()

    rows = (
        db.query(
            User.id
        )
        .filter(
            User.id.in_(
                result
            ),
            User.is_active.is_(True),
        )
        .all()
    )

    return {
        int(row[0])
        for row in rows
    }


def _get_completed_assignment_user_ids(
    db: Session,
    assignment_id: int,
    user_ids: set[int],
) -> set[int]:
    if not user_ids:
        return set()

    rows = (
        db.query(
            QuizAttempt.user_id
        )
        .filter(
            QuizAttempt.assignment_id == assignment_id,
            QuizAttempt.user_id.in_(
                user_ids
            ),
            QuizAttempt.status == "completed",
            QuizAttempt.is_deleted.is_(False),
        )
        .distinct()
        .all()
    )

    return {
        int(row[0])
        for row in rows
    }


def _create_assignment_notifications(
    db: Session,
    assignment: QuizAssignment,
    actor: User,
    user_ids: set[int],
) -> None:
    if not user_ids:
        return

    actor_name = " ".join(
        value.strip()
        for value in [
            actor.first_name or "",
            actor.last_name or "",
        ]
        if value
        and value.strip()
    ) or "Un docente"

    for user_id in sorted(
        user_ids
    ):
        create_notification(
            db=db,
            user_id=user_id,
            notification_type="quiz_assignment",
            title="Nuovo quiz assegnato",
            message=(
                f'{actor_name} ti ha assegnato il quiz '
                f'"{assignment.title}" per {assignment.subject}.'
            ),
            actor_user_id=actor.id,
            resource_type="quiz_assignment",
            resource_id=assignment.id,
            action_type="quiz_assignment",
            action_resource_id=assignment.id,
            action_status="pending",
            expires_at=assignment.due_at,
            commit=False,
        )


def _create_reactivation_notifications(
    db: Session,
    assignment: QuizAssignment,
    actor: User,
    user_ids: set[int],
) -> None:
    if not user_ids:
        return

    completed_user_ids = (
        _get_completed_assignment_user_ids(
            db,
            assignment.id,
            user_ids,
        )
    )

    eligible_user_ids = (
        user_ids
        - completed_user_ids
    )

    if not eligible_user_ids:
        return

    actor_name = " ".join(
        value.strip()
        for value in [
            actor.first_name or "",
            actor.last_name or "",
        ]
        if value
        and value.strip()
    ) or "Un docente"

    for user_id in sorted(
        eligible_user_ids
    ):
        create_notification(
            db=db,
            user_id=user_id,
            notification_type="quiz_assignment",
            title="Quiz nuovamente disponibile",
            message=(
                f'{actor_name} ha riattivato il quiz '
                f'"{assignment.title}" per {assignment.subject}.'
            ),
            actor_user_id=actor.id,
            resource_type="quiz_assignment",
            resource_id=assignment.id,
            action_type="quiz_assignment",
            action_resource_id=assignment.id,
            action_status="pending",
            expires_at=assignment.due_at,
            commit=False,
        )


def _cancel_removed_recipient_notifications(
    db: Session,
    assignment_id: int,
    user_ids: set[int],
) -> None:
    for user_id in user_ids:
        update_user_notification_action_status_by_resource(
            db=db,
            user_id=user_id,
            action_type="quiz_assignment",
            action_resource_id=assignment_id,
            action_status="cancelled",
            current_statuses={
                "pending",
            },
            mark_as_read=False,
            commit=False,
        )


def _assignment_has_attempts(
    db: Session,
    assignment_id: int,
) -> bool:
    return (
        db.query(
            QuizAttempt.id
        )
        .filter(
            QuizAttempt.assignment_id == assignment_id,
            QuizAttempt.is_deleted.is_(False),
        )
        .first()
        is not None
    )


def _current_recipient_ids(
    assignment: QuizAssignment,
) -> tuple[
    list[int],
    list[int],
]:
    user_ids: list[int] = []
    group_ids: list[int] = []

    for recipient in (
        assignment.recipients
    ):
        if recipient.user_id is not None:
            user_ids.append(
                recipient.user_id
            )

        if recipient.group_id is not None:
            group_ids.append(
                recipient.group_id
            )

    return (
        _normalize_recipient_ids(
            user_ids
        ),
        _normalize_recipient_ids(
            group_ids
        ),
    )


def _replace_recipients(
    db: Session,
    assignment: QuizAssignment,
    user_ids: list[int],
    group_ids: list[int],
) -> None:
    (
        db.query(
            QuizAssignmentRecipient
        )
        .filter(
            QuizAssignmentRecipient.assignment_id
            == assignment.id
        )
        .delete(
            synchronize_session=False
        )
    )

    for user_id in user_ids:
        db.add(
            QuizAssignmentRecipient(
                assignment_id=assignment.id,
                user_id=user_id,
                group_id=None,
            )
        )

    for group_id in group_ids:
        db.add(
            QuizAssignmentRecipient(
                assignment_id=assignment.id,
                user_id=None,
                group_id=group_id,
            )
        )


def create_quiz_assignment(
    db: Session,
    actor: User,
    data: QuizAssignmentCreate,
) -> QuizAssignment:
    subject_record = _get_subject(
        db,
        data.department,
        data.course,
        data.subject,
    )

    if subject_record is None:
        raise ValueError(
            "Materia non trovata."
        )

    _require_teacher_subject(
        db,
        actor,
        subject_record,
    )

    validate_quiz_assignment_questions(
        data
    )

    user_ids = _normalize_recipient_ids(
        list(
            data.user_ids
        )
    )

    group_ids = _normalize_recipient_ids(
        list(
            data.group_ids
        )
    )

    _validate_recipients(
        db,
        actor,
        user_ids,
        group_ids,
    )

    effective_user_ids = (
        _get_effective_recipient_user_ids(
            db,
            user_ids,
            group_ids,
        )
    )

    due_at = _as_utc(
        data.due_at
    )

    if (
        due_at is not None
        and due_at <= utc_now()
    ):
        raise ValueError(
            "La scadenza deve essere futura."
        )

    title = data.title.strip()

    if not title:
        raise ValueError(
            "Il titolo non può essere vuoto."
        )

    assignment = QuizAssignment(
        teacher_id=actor.id,
        subject_id=subject_record.id,
        department=data.department.strip(),
        course=data.course.strip(),
        subject=data.subject.strip(),
        title=title,
        description=(
            data.description.strip()
            if data.description
            else None
        ),
        selection_mode=data.selection_mode,
        selected_arguments=(
            list(
                data.arguments
            )
            if data.selection_mode
            == "arguments"
            else []
        ),
        selected_question_ids=(
            list(
                data.question_ids
            )
            if data.selection_mode
            == "selected_questions"
            else []
        ),
        question_count=(
            len(
                data.question_ids
            )
            if data.selection_mode
            == "selected_questions"
            else data.question_count
        ),
        time_limit_seconds=data.time_limit_seconds,
        due_at=due_at,
        is_active=True,
    )

    try:
        db.add(
            assignment
        )

        db.flush()

        _replace_recipients(
            db,
            assignment,
            user_ids,
            group_ids,
        )

        _create_assignment_notifications(
            db,
            assignment,
            actor,
            effective_user_ids,
        )

        db.commit()

    except Exception:
        db.rollback()
        raise

    return get_quiz_assignment_by_id(
        db,
        assignment.id,
    )


def update_quiz_assignment(
    db: Session,
    assignment: QuizAssignment,
    actor: User,
    data: QuizAssignmentUpdate,
) -> QuizAssignment:
    if (
        actor.role not in {
            "admin",
            "creator",
        }
        and assignment.teacher_id
        != actor.id
    ):
        raise PermissionError(
            "Non puoi modificare questa assegnazione."
        )

    values = data.model_dump(
        exclude_unset=True
    )

    previous_active = bool(
        assignment.is_active
    )

    target_active = bool(
        values.get(
            "is_active",
            previous_active,
        )
    )

    reactivating = (
        not previous_active
        and target_active
    )

    deactivating = (
        previous_active
        and not target_active
    )

    target_department = str(
        values.get(
            "department",
            assignment.department,
        )
    ).strip()

    target_course = str(
        values.get(
            "course",
            assignment.course,
        )
    ).strip()

    target_subject = str(
        values.get(
            "subject",
            assignment.subject,
        )
    ).strip()

    subject_record = _get_subject(
        db,
        target_department,
        target_course,
        target_subject,
    )

    if subject_record is None:
        raise ValueError(
            "Materia non trovata."
        )

    _require_teacher_subject(
        db,
        actor,
        subject_record,
    )

    current_user_ids, current_group_ids = (
        _current_recipient_ids(
            assignment
        )
    )

    current_effective_ids = (
        _get_effective_recipient_user_ids(
            db,
            current_user_ids,
            current_group_ids,
        )
    )

    target_user_ids = _normalize_recipient_ids(
        list(
            values.pop(
                "user_ids",
                current_user_ids,
            )
            or []
        )
    )

    target_group_ids = _normalize_recipient_ids(
        list(
            values.pop(
                "group_ids",
                current_group_ids,
            )
            or []
        )
    )

    recipients_changed = (
        target_user_ids
        != current_user_ids
        or target_group_ids
        != current_group_ids
    )

    if recipients_changed:
        _validate_recipients(
            db,
            actor,
            target_user_ids,
            target_group_ids,
        )

    target_effective_ids = (
        _get_effective_recipient_user_ids(
            db,
            target_user_ids,
            target_group_ids,
        )
    )

    added_user_ids = (
        target_effective_ids
        - current_effective_ids
    )

    removed_user_ids = (
        current_effective_ids
        - target_effective_ids
    )

    selection_mode = str(
        values.get(
            "selection_mode",
            assignment.selection_mode,
        )
    )

    raw_arguments = values.pop(
        "arguments",
        values.get(
            "selected_arguments",
            assignment.selected_arguments
            or [],
        ),
    )

    raw_question_ids = values.pop(
        "question_ids",
        values.get(
            "selected_question_ids",
            assignment.selected_question_ids
            or [],
        ),
    )

    target_arguments = list(
        raw_arguments
        or []
    )

    target_question_ids = list(
        raw_question_ids
        or []
    )

    if (
        "arguments"
        in data.model_fields_set
    ):
        values[
            "selected_arguments"
        ] = target_arguments

    if (
        "question_ids"
        in data.model_fields_set
    ):
        values[
            "selected_question_ids"
        ] = target_question_ids

    target_question_count = int(
        values.get(
            "question_count",
            assignment.question_count,
        )
    )

    if (
        selection_mode
        == "selected_questions"
    ):
        target_question_count = len(
            target_question_ids
        )

        values[
            "question_count"
        ] = target_question_count

        values[
            "selected_arguments"
        ] = []

    else:
        values[
            "selected_question_ids"
        ] = []

        if selection_mode != "arguments":
            values[
                "selected_arguments"
            ] = []

    structural_fields = {
        "department",
        "course",
        "subject",
        "selection_mode",
        "arguments",
        "selected_arguments",
        "question_ids",
        "selected_question_ids",
        "question_count",
        "time_limit_seconds",
    }

    if (
        structural_fields.intersection(
            data.model_fields_set
        )
        and _assignment_has_attempts(
            db,
            assignment.id,
        )
    ):
        raise ValueError(
            "Non puoi modificare la configurazione del quiz dopo l'avvio di un tentativo."
        )

    _validate_assignment_configuration(
        department=target_department,
        course=target_course,
        subject=target_subject,
        selection_mode=selection_mode,
        arguments=(
            target_arguments
            if selection_mode
            == "arguments"
            else []
        ),
        question_ids=(
            target_question_ids
            if selection_mode
            == "selected_questions"
            else []
        ),
        question_count_value=target_question_count,
    )

    due_at_changed = (
        "due_at"
        in values
    )

    if due_at_changed:
        due_at = _as_utc(
            values[
                "due_at"
            ]
        )

        if (
            due_at is not None
            and due_at <= utc_now()
        ):
            raise ValueError(
                "La scadenza deve essere futura."
            )

        values[
            "due_at"
        ] = due_at

    target_due_at = _as_utc(
        values.get(
            "due_at",
            assignment.due_at,
        )
    )

    if (
        reactivating
        and target_due_at is not None
        and target_due_at <= utc_now()
    ):
        raise ValueError(
            "Non puoi riattivare un quiz con una scadenza già trascorsa."
        )

    if "title" in values:
        title = values[
            "title"
        ]

        if (
            title is None
            or not str(
                title
            ).strip()
        ):
            raise ValueError(
                "Il titolo non può essere vuoto."
            )

        values[
            "title"
        ] = str(
            title
        ).strip()

    if "description" in values:
        description = values[
            "description"
        ]

        values[
            "description"
        ] = (
            str(
                description
            ).strip()
            if description
            else None
        )

    values[
        "department"
    ] = target_department

    values[
        "course"
    ] = target_course

    values[
        "subject"
    ] = target_subject

    values[
        "subject_id"
    ] = subject_record.id

    values[
        "selection_mode"
    ] = selection_mode

    allowed_fields = {
        "subject_id",
        "department",
        "course",
        "subject",
        "title",
        "description",
        "selection_mode",
        "selected_arguments",
        "selected_question_ids",
        "question_count",
        "time_limit_seconds",
        "due_at",
        "is_active",
    }

    update_values = {
        field: value
        for field, value
        in values.items()
        if field
        in allowed_fields
    }

    try:
        for field, value in (
            update_values.items()
        ):
            setattr(
                assignment,
                field,
                value,
            )

        if recipients_changed:
            _replace_recipients(
                db,
                assignment,
                target_user_ids,
                target_group_ids,
            )

            _cancel_removed_recipient_notifications(
                db,
                assignment.id,
                removed_user_ids,
            )

            if (
                assignment.is_active
                and not reactivating
                and added_user_ids
            ):
                completed_added_user_ids = (
                    _get_completed_assignment_user_ids(
                        db,
                        assignment.id,
                        added_user_ids,
                    )
                )

                _create_assignment_notifications(
                    db,
                    assignment,
                    actor,
                    (
                        added_user_ids
                        - completed_added_user_ids
                    ),
                )

        if due_at_changed:
            update_notifications_expiration_by_resource(
                db=db,
                action_type="quiz_assignment",
                action_resource_id=assignment.id,
                expires_at=assignment.due_at,
                only_pending=True,
                commit=False,
            )

        if deactivating:
            update_notifications_action_status_by_resource(
                db=db,
                action_type="quiz_assignment",
                action_resource_id=assignment.id,
                action_status="cancelled",
                current_statuses={
                    "pending",
                },
                mark_as_read=False,
                commit=False,
            )

        if reactivating:
            _create_reactivation_notifications(
                db,
                assignment,
                actor,
                target_effective_ids,
            )

        db.commit()

        db.refresh(
            assignment
        )

    except Exception:
        db.rollback()
        raise

    updated = get_quiz_assignment_by_id(
        db,
        assignment.id,
    )

    if updated is None:
        raise RuntimeError(
            "Assegnazione quiz non trovata dopo l'aggiornamento."
        )

    return updated


def deactivate_quiz_assignment(
    db: Session,
    assignment: QuizAssignment,
    actor: User,
) -> QuizAssignment:
    if (
        actor.role not in {
            "admin",
            "creator",
        }
        and assignment.teacher_id
        != actor.id
    ):
        raise PermissionError(
            "Non puoi disattivare questa assegnazione."
        )

    if not assignment.is_active:
        return assignment

    assignment.is_active = False

    try:
        update_notifications_action_status_by_resource(
            db=db,
            action_type="quiz_assignment",
            action_resource_id=assignment.id,
            action_status="cancelled",
            current_statuses={
                "pending",
            },
            mark_as_read=False,
            commit=False,
        )

        db.commit()

        db.refresh(
            assignment
        )

    except Exception:
        db.rollback()
        raise

    return assignment


def get_teacher_quiz_assignments(
    db: Session,
    actor: User,
) -> list[QuizAssignment]:
    query = (
        db.query(
            QuizAssignment
        )
        .options(
            joinedload(
                QuizAssignment.recipients
            )
        )
    )

    if actor.role not in {
        "admin",
        "creator",
    }:
        query = query.filter(
            QuizAssignment.teacher_id
            == actor.id
        )

    return (
        query
        .order_by(
            QuizAssignment.created_at.desc(),
            QuizAssignment.id.desc(),
        )
        .all()
    )


def _get_user_group_ids(
    db: Session,
    user_id: int,
) -> list[int]:
    rows = (
        db.query(
            GroupMember.group_id
        )
        .filter(
            GroupMember.user_id
            == user_id
        )
        .all()
    )

    return list({
        int(row[0])
        for row in rows
    })


def can_user_access_quiz_assignment(
    db: Session,
    assignment_id: int,
    user_id: int,
) -> bool:
    direct = (
        db.query(
            QuizAssignmentRecipient
        )
        .filter(
            QuizAssignmentRecipient.assignment_id
            == assignment_id,
            QuizAssignmentRecipient.user_id
            == user_id,
        )
        .first()
    )

    if direct is not None:
        return True

    group_ids = _get_user_group_ids(
        db,
        user_id,
    )

    if not group_ids:
        return False

    return (
        db.query(
            QuizAssignmentRecipient
        )
        .filter(
            QuizAssignmentRecipient.assignment_id
            == assignment_id,
            QuizAssignmentRecipient.group_id.in_(
                group_ids
            ),
        )
        .first()
        is not None
    )


def get_user_quiz_assignments(
    db: Session,
    user_id: int,
) -> list[dict]:
    user = _require_recipient_user(
        db,
        user_id,
    )

    group_ids = _get_user_group_ids(
        db,
        user.id,
    )

    recipient_filters = [
        QuizAssignmentRecipient.user_id
        == user.id
    ]

    if group_ids:
        recipient_filters.append(
            QuizAssignmentRecipient.group_id.in_(
                group_ids
            )
        )

    assignments = (
        db.query(
            QuizAssignment
        )
        .join(
            QuizAssignmentRecipient,
            QuizAssignmentRecipient.assignment_id
            == QuizAssignment.id,
        )
        .options(
            joinedload(
                QuizAssignment.recipients
            )
        )
        .filter(
            QuizAssignment.is_active.is_(
                True
            ),
            or_(
                *recipient_filters
            ),
        )
        .distinct()
        .all()
    )

    assignments.sort(
        key=lambda assignment: (
            _as_utc(
                assignment.due_at
            ) is None,
            _as_utc(
                assignment.due_at
            )
            or datetime.max.replace(
                tzinfo=timezone.utc
            ),
            -assignment.id,
        )
    )

    now = utc_now()

    result: list[dict] = []

    for assignment in assignments:
        due_at = _as_utc(
            assignment.due_at
        )

        expired = (
            due_at is not None
            and due_at <= now
        )

        attempt = (
            db.query(
                QuizAttempt
            )
            .filter(
                QuizAttempt.assignment_id
                == assignment.id,
                QuizAttempt.user_id
                == user.id,
                QuizAttempt.is_deleted.is_(
                    False
                ),
            )
            .order_by(
                QuizAttempt.started_at.desc(),
                QuizAttempt.id.desc(),
            )
            .first()
        )

        result.append({
            "id":
                assignment.id,

            "teacher_id":
                assignment.teacher_id,

            "subject_id":
                assignment.subject_id,

            "department":
                assignment.department,

            "course":
                assignment.course,

            "subject":
                assignment.subject,

            "title":
                assignment.title,

            "description":
                assignment.description,

            "selection_mode":
                assignment.selection_mode,

            "selected_arguments":
                assignment.selected_arguments
                or [],

            "selected_question_ids":
                assignment.selected_question_ids
                or [],

            "question_count":
                assignment.question_count,

            "time_limit_seconds":
                assignment.time_limit_seconds,

            "due_at":
                assignment.due_at,

            "is_active":
                assignment.is_active,

            "created_at":
                assignment.created_at,

            "updated_at":
                assignment.updated_at,

            "recipients":
                assignment.recipients,

            "is_expired":
                expired,

            "can_start":
                (
                    not expired
                    and attempt is None
                ),

            "attempt_id":
                (
                    attempt.id
                    if attempt is not None
                    else None
                ),

            "is_completed":
                (
                    attempt is not None
                    and attempt.status
                    == "completed"
                ),

            "is_in_progress":
                (
                    attempt is not None
                    and attempt.status
                    == "in_progress"
                ),
        })

    return result


def get_student_quiz_assignments(
    db: Session,
    user_id: int,
) -> list[dict]:
    return get_user_quiz_assignments(
        db,
        user_id,
    )


def get_quiz_assignment_results(
    db: Session,
    assignment: QuizAssignment,
    actor: User,
) -> list[QuizAttempt]:
    if (
        actor.role not in {
            "admin",
            "creator",
        }
        and assignment.teacher_id
        != actor.id
    ):
        raise PermissionError(
            "Non puoi visualizzare i risultati di questa assegnazione."
        )

    return (
        db.query(
            QuizAttempt
        )
        .filter(
            QuizAttempt.assignment_id
            == assignment.id,
            QuizAttempt.is_deleted.is_(
                False
            ),
        )
        .order_by(
            QuizAttempt.completed_at.desc(),
            QuizAttempt.started_at.desc(),
        )
        .all()
    )
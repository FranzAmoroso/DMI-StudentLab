from datetime import (
    datetime,
    timezone,
)

from fastapi import (
    Depends,
    FastAPI,
    HTTPException,
)

from models.teacher_material import (
    TeacherMaterial,
)

from schemas.teacher_material import (
    TeacherMaterialCompleteRequest,
    TeacherMaterialResponse,
    TeacherMaterialUpdate,
    TeacherMaterialUploadRequest,
)

from services.teacher_material import (
    create_teacher_material,
    delete_teacher_material,
    ensure_teacher_material_not_duplicate,
    generate_teacher_material_stored_name,
    get_student_teacher_materials,
    get_teacher_material_by_id,
    get_teacher_materials,
    require_teacher_subject,
    update_teacher_material,
    validate_teacher_material_mime_type,
    validate_teacher_material_size,
)

from fastapi.middleware.cors import (
    CORSMiddleware,
)

from fastapi.responses import (
    StreamingResponse,
)

from sqlalchemy.exc import (
    IntegrityError,
)

from sqlalchemy.orm import (
    Session,
)

from vercel.blob import (
    AsyncBlobClient,
)


from core.config import (
    settings,
)

from core.database import (
    create_tables,
    get_db,
)

from core.security import (
    get_admin_user,
    get_current_user,
    get_creator_user,
    get_verified_teacher,
    get_verified_teacher_user,
)


from models.user import (
    User,
    UserAcademicPath,
)

from models.subject import (
    Subject,
    UserSubject,
)


from models.filter import (
    Answer,
    ArgumentsRequest,
    Filter,
    QuestionCountRequest,
    SubjectRequest,
)


from schemas.app_config import (
    AppConfigResponse,
)

from schemas.user import (
    AcademicPathVerificationUpdate,
    TeacherVerificationUpdate,
    UserAcademicPathCreate,
    UserAcademicPathResponse,
    UserAcademicPathUpdate,
    UserAdminStatusUpdate,
    UserResponse,
    UserUpdate,
)

from schemas.auth import (
    LoginRequest,
    RegisterRequest,
    TokenResponse,
)

from schemas.subject import (
    SubjectCreate,
    SubjectResponse,
    UserSubjectCreate,
)

from schemas.group import (
    AddGroupMemberRequest,
    ChangeGroupMemberRoleRequest,
    GroupCreate,
    GroupDetailResponse,
    GroupJoinRequestCreate,
    GroupJoinRequestResponse,
    GroupMemberResponse,
    GroupResponse,
    GroupUpdate,
    JoinGroupResponse,
)

from schemas.material import (
    GroupMaterialCompleteRequest,
    GroupMaterialResponse,
    GroupMaterialUploadRequest,
)

from schemas.review import (
    AdminReviewsResponse,
    ReviewCreate,
    ReviewModerationUpdate,
    ReviewResponse,
    ReviewUpdate,
    UserReviewsResponse,
)


from services.app_config import (
    get_app_config,
)

from services.auth import (
    authenticate_user,
    create_access_token,
    hash_password,
)

from services.filter import (
    arguments,
    question_count,
    shuffle_filter,
    subjects,
    validate_answer,
)

from services.user import (
    add_subject_to_user,
    create_academic_path,
    get_academic_path_by_id,
    get_pending_academic_path_verifications,
    get_user_academic_paths,
    get_user_by_email,
    get_user_by_id,
    get_user_subject,
    get_users,
    reject_academic_path,
    reject_teacher,
    remove_academic_path,
    remove_subject_from_user,
    set_current_academic_path,
    set_primary_academic_path,
    set_user_active_status,
    update_academic_path,
    update_user,
    verify_academic_path,
    verify_teacher,
)

from services.subject import (
    create_subject,
    get_existing_subject,
    get_subject_by_id,
    get_subjects_by_course,
)

from services.group import (
    accept_group_join_request,
    add_group_member,
    create_group,
    create_group_join_request,
    delete_group,
    get_group_by_id,
    get_group_join_request,
    get_group_join_request_by_id,
    get_group_join_requests,
    get_group_member,
    get_groups,
    get_groups_by_user,
    reject_group_join_request,
    remove_group_member,
    update_group,
    update_group_member_role,
)

from services.material import (
    create_group_material_record,
    delete_group_material,
    ensure_material_not_duplicate,
    generate_stored_name,
    get_group_material_by_id,
    get_group_materials,
    validate_material_mime_type,
    validate_material_size,
)

from services.review import (
    create_review,
    delete_review,
    get_review_between_users,
    moderate_review,
    restore_hidden_review,
    serialize_admin_reviews,
    serialize_public_user_reviews,
    serialize_review,
    update_review,
)

from models.account_deletion_request import (
    AccountDeletionRequest,
)

from models.group_content_report import (
    GroupContentReport,
)

from models.group_ownership_transfer import (
    GroupOwnershipTransfer,
)

from models.group_report import (
    GroupReport,
)

from models.notification import (
    Notification,
)

from models.profile_error_report import (
    ProfileErrorReport,
)

from models.user_report import (
    UserReport,
)

from routes.teacher_assignment import (
    router as teacher_assignment_router,
)

from routes.user_report import (
    router as user_report_router,
)

from routes.profile_error_report import (
    router as profile_error_report_router,
)

from routes.account_deletion_request import (
    router as account_deletion_request_router,
)

from routes.group_ownership_transfer import (
    router as group_ownership_transfer_router,
)

from routes.notification import (
    router as notification_router,
)

from routes.group_report import (
    router as group_report_router,
)

from routes.group_content_report import (
    router as group_content_report_router,
)

app = FastAPI()

app.include_router(
    teacher_assignment_router,
)

app.include_router(
    user_report_router,
)

app.include_router(
    profile_error_report_router,
)

app.include_router(
    account_deletion_request_router,
)

app.include_router(
    group_ownership_transfer_router,
)

app.include_router(
    notification_router,
)

app.include_router(
    group_report_router,
)

app.include_router(
    group_content_report_router,
)

@app.on_event(
    "startup",
)
def startup_event():
    create_tables()


app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "*",
    ],
    allow_credentials=True,
    allow_methods=[
        "*",
    ],
    allow_headers=[
        "*",
    ],
)


def require_group_member(
    db: Session,
    group_id: int,
    user_id: int,
):
    member = get_group_member(
        db,
        group_id,
        user_id,
    )

    if member is None:
        raise HTTPException(
            status_code=403,
            detail="L'utente non appartiene al gruppo.",
        )

    return member


def require_group_manager(
    db: Session,
    group_id: int,
    user_id: int,
):
    member = require_group_member(
        db,
        group_id,
        user_id,
    )

    if member.role not in [
        "owner",
        "admin",
    ]:
        raise HTTPException(
            status_code=403,
            detail="Permessi insufficienti.",
        )

    return member


def require_academic_path_owner(
    academic_path: UserAcademicPath,
    current_user: User,
):
    if (
        academic_path.user_id !=
        current_user.id
    ):
        raise HTTPException(
            status_code=403,
            detail="Non puoi modificare questo percorso accademico.",
        )


@app.get(
    "/",
)
async def root():
    return {
        "status":
            "Server attivo.",
    }


@app.post(
    "/shuffle_filter",
)
def api_shuffle_filter(
    request: Filter,
):
    return shuffle_filter(
        request.department,
        request.course,
        request.sub,
        request.arguments,
        request.number_of_questions,
    )


@app.post(
    "/validate_answer",
)
def api_validate_answer(
    answer: Answer,
):
    return validate_answer(
        answer.idQuestion,
        answer.idChoice,
        answer.department,
        answer.sub,
    )


@app.post(
    "/arguments",
)
def api_arguments(
    request: ArgumentsRequest,
):
    return arguments(
        request.department,
        request.course,
        request.sub,
    )


@app.post(
    "/question_count",
)
def api_question_count(
    request: QuestionCountRequest,
):
    count = question_count(
        request.department,
        request.course,
        request.sub,
        request.arguments,
    )

    return {
        "count":
            count,
    }


@app.post(
    "/subjects",
)
def api_subjects(
    request: SubjectRequest,
):
    return subjects(
        request.department,
        request.course,
    )


@app.get(
    "/universities",
)
def api_universities(
    db: Session = Depends(
        get_db,
    ),
):
    rows = (
        db.query(
            Subject.university_code,
            Subject.university,
        )
        .filter(
            Subject.is_active.is_(
                True,
            ),
        )
        .distinct()
        .order_by(
            Subject.university.asc(),
        )
        .all()
    )

    return [
        {
            "code":
                code,
            "name":
                name,
        }
        for code, name in rows
    ]


@app.get(
    "/universities/{university_code}/departments",
)
def api_departments(
    university_code: str,
    db: Session = Depends(
        get_db,
    ),
):
    rows = (
        db.query(
            Subject.department_code,
            Subject.department,
        )
        .filter(
            Subject.university_code ==
            university_code,
            Subject.is_active.is_(
                True,
            ),
        )
        .distinct()
        .order_by(
            Subject.department.asc(),
        )
        .all()
    )

    return [
        {
            "code":
                code,
            "name":
                name,
        }
        for code, name in rows
    ]


@app.get(
    "/universities/{university_code}/departments/{department_code}/courses",
)
def api_courses(
    university_code: str,
    department_code: str,
    db: Session = Depends(
        get_db,
    ),
):
    rows = (
        db.query(
            Subject.course_code,
            Subject.course,
            Subject.degree_type,
        )
        .filter(
            Subject.university_code ==
            university_code,
            Subject.department_code ==
            department_code,
            Subject.is_active.is_(
                True,
            ),
        )
        .distinct()
        .order_by(
            Subject.course.asc(),
        )
        .all()
    )

    return [
        {
            "code":
                code,
            "name":
                name,
            "degree_type":
                degree_type,
        }
        for (
            code,
            name,
            degree_type,
        ) in rows
    ]


@app.get(
    "/universities/{university_code}/departments/{department_code}/courses/{course_code}/subjects",
    response_model=list[
        SubjectResponse
    ],
)
def api_catalog_subjects(
    university_code: str,
    department_code: str,
    course_code: str,
    study_year: int | None = None,
    db: Session = Depends(
        get_db,
    ),
):
    query = (
        db.query(
            Subject,
        )
        .filter(
            Subject.university_code ==
            university_code,
            Subject.department_code ==
            department_code,
            Subject.course_code ==
            course_code,
            Subject.is_active.is_(
                True,
            ),
        )
    )

    if study_year is not None:
        query = query.filter(
            Subject.study_year ==
            study_year,
        )

    return (
        query
        .order_by(
            Subject.study_year.asc(),
            Subject.name.asc(),
        )
        .all()
    )


@app.get(
    "/users",
    response_model=list[
        UserResponse
    ],
)
def api_users(
    current_user: User = Depends(
        get_current_user,
    ),
    db: Session = Depends(
        get_db,
    ),
):
    return get_users(
        db,
    )


@app.get(
    "/user/{user_id}",
    response_model=UserResponse,
)
def api_user(
    user_id: int,
    current_user: User = Depends(
        get_current_user,
    ),
    db: Session = Depends(
        get_db,
    ),
):
    user = get_user_by_id(
        db,
        user_id,
    )

    if user is None:
        raise HTTPException(
            status_code=404,
            detail="Utente non trovato.",
        )

    return user


@app.patch(
    "/update_user/{user_id}",
    response_model=UserResponse,
)
def api_update_user(
    user_id: int,
    request: UserUpdate,
    current_user: User = Depends(
        get_current_user,
    ),
    db: Session = Depends(
        get_db,
    ),
):
    if (
        current_user.id !=
        user_id
    ):
        raise HTTPException(
            status_code=403,
            detail="Non puoi modificare questo utente.",
        )

    user = get_user_by_id(
        db,
        user_id,
    )

    if user is None:
        raise HTTPException(
            status_code=404,
            detail="Utente non trovato.",
        )

    return update_user(
        db,
        user,
        request,
    )


@app.get(
    "/user/{user_id}/academic_paths",
    response_model=list[
        UserAcademicPathResponse
    ],
)
def api_user_academic_paths(
    user_id: int,
    current_user: User = Depends(
        get_current_user,
    ),
    db: Session = Depends(
        get_db,
    ),
):
    user = get_user_by_id(
        db,
        user_id,
    )

    if user is None:
        raise HTTPException(
            status_code=404,
            detail="Utente non trovato.",
        )

    return get_user_academic_paths(
        db,
        user_id,
    )


@app.post(
    "/me/academic_paths",
    response_model=UserAcademicPathResponse,
)
def api_create_academic_path(
    request: UserAcademicPathCreate,
    current_user: User = Depends(
        get_current_user,
    ),
    db: Session = Depends(
        get_db,
    ),
):
    existing = (
        db.query(
            UserAcademicPath,
        )
        .filter(
            UserAcademicPath.user_id ==
            current_user.id,
            UserAcademicPath.university_code ==
            request.university_code,
            UserAcademicPath.department_code ==
            request.department_code,
            UserAcademicPath.course_code ==
            request.course_code,
        )
        .first()
    )

    if existing is not None:
        raise HTTPException(
            status_code=409,
            detail="Percorso accademico già presente.",
        )

    try:
        return create_academic_path(
            db,
            current_user,
            request,
        )

    except ValueError as exception:
        db.rollback()

        raise HTTPException(
            status_code=400,
            detail=str(
                exception,
            ),
        )

    except IntegrityError:
        db.rollback()

        raise HTTPException(
            status_code=409,
            detail="Impossibile aggiungere il percorso accademico.",
        )


@app.patch(
    "/me/academic_paths/{academic_path_id}",
    response_model=UserAcademicPathResponse,
)
def api_update_academic_path(
    academic_path_id: int,
    request: UserAcademicPathUpdate,
    current_user: User = Depends(
        get_current_user,
    ),
    db: Session = Depends(
        get_db,
    ),
):
    academic_path = (
        get_academic_path_by_id(
            db,
            academic_path_id,
        )
    )

    if academic_path is None:
        raise HTTPException(
            status_code=404,
            detail="Percorso accademico non trovato.",
        )

    require_academic_path_owner(
        academic_path,
        current_user,
    )

    try:
        return update_academic_path(
            db,
            current_user,
            academic_path,
            request,
        )

    except ValueError as exception:
        db.rollback()

        raise HTTPException(
            status_code=400,
            detail=str(
                exception,
            ),
        )

    except IntegrityError:
        db.rollback()

        raise HTTPException(
            status_code=409,
            detail="Impossibile modificare il percorso accademico.",
        )


@app.post(
    "/me/academic_paths/{academic_path_id}/set_current",
    response_model=UserAcademicPathResponse,
)
def api_set_current_academic_path(
    academic_path_id: int,
    current_user: User = Depends(
        get_current_user,
    ),
    db: Session = Depends(
        get_db,
    ),
):
    academic_path = (
        get_academic_path_by_id(
            db,
            academic_path_id,
        )
    )

    if academic_path is None:
        raise HTTPException(
            status_code=404,
            detail="Percorso accademico non trovato.",
        )

    require_academic_path_owner(
        academic_path,
        current_user,
    )

    try:
        return set_current_academic_path(
            db,
            current_user,
            academic_path,
        )

    except ValueError as exception:
        db.rollback()

        raise HTTPException(
            status_code=400,
            detail=str(
                exception,
            ),
        )

    except IntegrityError:
        db.rollback()

        raise HTTPException(
            status_code=409,
            detail="Impossibile impostare il percorso corrente.",
        )


@app.post(
    "/me/academic_paths/{academic_path_id}/set_primary",
    response_model=UserAcademicPathResponse,
)
def api_set_primary_academic_path(
    academic_path_id: int,
    current_user: User = Depends(
        get_current_user,
    ),
    db: Session = Depends(
        get_db,
    ),
):
    academic_path = (
        get_academic_path_by_id(
            db,
            academic_path_id,
        )
    )

    if academic_path is None:
        raise HTTPException(
            status_code=404,
            detail="Percorso accademico non trovato.",
        )

    require_academic_path_owner(
        academic_path,
        current_user,
    )

    try:
        return set_primary_academic_path(
            db,
            current_user,
            academic_path,
        )

    except IntegrityError:
        db.rollback()

        raise HTTPException(
            status_code=409,
            detail="Impossibile impostare il percorso principale.",
        )


@app.delete(
    "/me/academic_paths/{academic_path_id}",
)
def api_remove_academic_path(
    academic_path_id: int,
    current_user: User = Depends(
        get_current_user,
    ),
    db: Session = Depends(
        get_db,
    ),
):
    academic_path = (
        get_academic_path_by_id(
            db,
            academic_path_id,
        )
    )

    if academic_path is None:
        raise HTTPException(
            status_code=404,
            detail="Percorso accademico non trovato.",
        )

    require_academic_path_owner(
        academic_path,
        current_user,
    )

    try:
        remove_academic_path(
            db,
            current_user,
            academic_path,
        )

    except IntegrityError:
        db.rollback()

        raise HTTPException(
            status_code=409,
            detail="Impossibile rimuovere il percorso accademico.",
        )

    return {
        "success":
            True,
        "message":
            "Percorso accademico rimosso.",
    }


@app.get(
    "/admin/academic_paths/pending",
    response_model=list[
        UserAcademicPathResponse
    ],
)
def api_admin_pending_academic_paths(
    current_user: User = Depends(
        get_admin_user,
    ),
    db: Session = Depends(
        get_db,
    ),
):
    return (
        get_pending_academic_path_verifications(
            db,
        )
    )


@app.patch(
    "/admin/academic_paths/{academic_path_id}/verification",
    response_model=UserAcademicPathResponse,
)
def api_admin_academic_path_verification(
    academic_path_id: int,
    request: AcademicPathVerificationUpdate,
    current_user: User = Depends(
        get_admin_user,
    ),
    db: Session = Depends(
        get_db,
    ),
):
    academic_path = (
        get_academic_path_by_id(
            db,
            academic_path_id,
        )
    )

    if academic_path is None:
        raise HTTPException(
            status_code=404,
            detail="Percorso accademico non trovato.",
        )

    if (
        academic_path.status !=
        "graduated"
    ):
        raise HTTPException(
            status_code=400,
            detail="Il percorso non risulta concluso con laurea.",
        )

    try:
        if (
            request.status ==
            "verified"
        ):
            return verify_academic_path(
                db,
                academic_path,
                current_user.id,
            )

        return reject_academic_path(
            db,
            academic_path,
            current_user.id,
        )

    except ValueError as exception:
        db.rollback()

        raise HTTPException(
            status_code=400,
            detail=str(
                exception,
            ),
        )


@app.post(
    "/create_subject",
    response_model=SubjectResponse,
)
def api_create_subject(
    request: SubjectCreate,
    current_user: User = Depends(
        get_admin_user,
    ),
    db: Session = Depends(
        get_db,
    ),
):
    existing_subject = (
        get_existing_subject(
            db,
            name=request.name,
            department=request.department,
            course=request.course,
            code=request.code,
            university_code=(
                request.university_code
            ),
        )
    )

    if existing_subject is not None:
        raise HTTPException(
            status_code=409,
            detail="Materia già esistente.",
        )

    try:
        return create_subject(
            db,
            request,
        )

    except IntegrityError:
        db.rollback()

        raise HTTPException(
            status_code=409,
            detail="Materia già esistente.",
        )


@app.get(
    "/social_subjects/{department}/{course}",
    response_model=list[
        SubjectResponse
    ],
)
def api_social_subjects(
    department: str,
    course: str,
    db: Session = Depends(
        get_db,
    ),
):
    return get_subjects_by_course(
        db,
        department,
        course,
    )


@app.post(
    "/add_user_subject/{user_id}",
    response_model=UserResponse,
)
def api_add_user_subject(
    user_id: int,
    request: UserSubjectCreate,
    current_user: User = Depends(
        get_current_user,
    ),
    db: Session = Depends(
        get_db,
    ),
):
    if (
        current_user.id !=
        user_id
    ):
        raise HTTPException(
            status_code=403,
            detail="Non puoi modificare le materie di questo utente.",
        )

    user = get_user_by_id(
        db,
        user_id,
    )

    if user is None:
        raise HTTPException(
            status_code=404,
            detail="Utente non trovato.",
        )

    subject = get_subject_by_id(
        db,
        request.subject_id,
    )

    if subject is None:
        raise HTTPException(
            status_code=404,
            detail="Materia non trovata.",
        )

    existing_subject = get_user_subject(
        db,
        user_id,
        request.subject_id,
    )

    if existing_subject is not None:
        raise HTTPException(
            status_code=409,
            detail="Materia già associata all'utente.",
        )

    try:
        add_subject_to_user(
            db,
            user_id,
            request,
        )

    except ValueError as exception:
        db.rollback()

        raise HTTPException(
            status_code=409,
            detail=str(
                exception,
            ),
        )

    except IntegrityError:
        db.rollback()

        raise HTTPException(
            status_code=409,
            detail="Impossibile aggiungere la materia.",
        )

    return get_user_by_id(
        db,
        user_id,
    )


@app.delete(
    "/remove_user_subject/{user_id}/{subject_id}",
)
def api_remove_user_subject(
    user_id: int,
    subject_id: int,
    current_user: User = Depends(
        get_current_user,
    ),
    db: Session = Depends(
        get_db,
    ),
):
    if (
        current_user.id !=
        user_id
    ):
        raise HTTPException(
            status_code=403,
            detail="Non puoi modificare le materie di questo utente.",
        )

    user_subject = get_user_subject(
        db,
        user_id,
        subject_id,
    )

    if user_subject is None:
        raise HTTPException(
            status_code=404,
            detail="Materia non associata all'utente.",
        )

    remove_subject_from_user(
        db,
        user_subject,
    )

    return {
        "success":
            True,
        "message":
            "Materia rimossa.",
    }


@app.get(
    "/admin/teachers/pending",
    response_model=list[
        UserResponse
    ],
)
def api_admin_pending_teachers(
    current_user: User = Depends(
        get_admin_user,
    ),
    db: Session = Depends(
        get_db,
    ),
):
    return (
        db.query(
            User,
        )
        .filter(
            User.role ==
            "teacher",
            User.teacher_verification_status ==
            "pending",
            User.is_active.is_(
                True,
            ),
        )
        .order_by(
            User.last_name.asc(),
            User.first_name.asc(),
        )
        .all()
    )


@app.patch(
    "/admin/teachers/{user_id}/verification",
    response_model=UserResponse,
)
def api_admin_teacher_verification(
    user_id: int,
    request: TeacherVerificationUpdate,
    current_user: User = Depends(
        get_admin_user,
    ),
    db: Session = Depends(
        get_db,
    ),
):
    user = get_user_by_id(
        db,
        user_id,
    )

    if user is None:
        raise HTTPException(
            status_code=404,
            detail="Utente non trovato.",
        )

    if user.role != "teacher":
        raise HTTPException(
            status_code=400,
            detail="L'utente non è registrato come docente.",
        )

    try:
        if (
            request.status ==
            "verified"
        ):
            return verify_teacher(
                db,
                user,
                current_user.id,
            )

        return reject_teacher(
            db,
            user,
            current_user.id,
        )

    except ValueError as exception:
        raise HTTPException(
            status_code=400,
            detail=str(
                exception,
            ),
        )


@app.get(
    "/admin/grades/pending",
)
def api_admin_pending_grades(
    current_user: User = Depends(
        get_admin_user,
    ),
    db: Session = Depends(
        get_db,
    ),
):
    rows = (
        db.query(
            UserSubject,
        )
        .filter(
            UserSubject.grade_status ==
            "pending",
            UserSubject.grade.is_not(
                None,
            ),
        )
        .order_by(
            UserSubject.id.asc(),
        )
        .all()
    )

    result = []

    for user_subject in rows:
        result.append(
            {
                "id":
                    user_subject.id,
                "user_id":
                    user_subject.user_id,
                "subject_id":
                    user_subject.subject_id,
                "grade":
                    user_subject.grade,
                "grade_status":
                    user_subject.grade_status,
                "note":
                    user_subject.note,
                "can_help":
                    user_subject.can_help,
                "user": {
                    "id":
                        user_subject.user.id,
                    "first_name":
                        user_subject.user.first_name,
                    "last_name":
                        user_subject.user.last_name,
                    "email":
                        user_subject.user.email,
                },
                "subject": {
                    "id":
                        user_subject.subject.id,
                    "code":
                        user_subject.subject.code,
                    "name":
                        user_subject.subject.name,
                },
            }
        )

    return result


@app.post(
    "/admin/users/{user_id}/subjects/{subject_id}/verify_grade",
)
def api_admin_verify_grade(
    user_id: int,
    subject_id: int,
    current_user: User = Depends(
        get_admin_user,
    ),
    db: Session = Depends(
        get_db,
    ),
):
    user_subject = get_user_subject(
        db,
        user_id,
        subject_id,
    )

    if user_subject is None:
        raise HTTPException(
            status_code=404,
            detail="Materia non associata all'utente.",
        )

    if user_subject.grade is None:
        raise HTTPException(
            status_code=400,
            detail="Nessun voto da verificare.",
        )

    user_subject.grade_status = (
        "verified"
    )

    user_subject.grade_verified_by = (
        current_user.id
    )

    user_subject.grade_verified_at = (
        datetime.now(
            timezone.utc,
        )
    )

    db.commit()

    db.refresh(
        user_subject,
    )

    return {
        "success":
            True,
        "grade":
            user_subject.grade,
        "grade_status":
            user_subject.grade_status,
        "grade_verified_by":
            user_subject.grade_verified_by,
        "grade_verified_at":
            user_subject.grade_verified_at,
    }


@app.post(
    "/admin/users/{user_id}/subjects/{subject_id}/reject_grade",
)
def api_admin_reject_grade(
    user_id: int,
    subject_id: int,
    current_user: User = Depends(
        get_admin_user,
    ),
    db: Session = Depends(
        get_db,
    ),
):
    user_subject = get_user_subject(
        db,
        user_id,
        subject_id,
    )

    if user_subject is None:
        raise HTTPException(
            status_code=404,
            detail="Materia non associata all'utente.",
        )

    if user_subject.grade is None:
        raise HTTPException(
            status_code=400,
            detail="Nessun voto da verificare.",
        )

    user_subject.grade_status = (
        "rejected"
    )

    user_subject.grade_verified_by = (
        current_user.id
    )

    user_subject.grade_verified_at = (
        datetime.now(
            timezone.utc,
        )
    )

    db.commit()

    db.refresh(
        user_subject,
    )

    return {
        "success":
            True,
        "grade":
            user_subject.grade,
        "grade_status":
            user_subject.grade_status,
        "grade_verified_by":
            user_subject.grade_verified_by,
        "grade_verified_at":
            user_subject.grade_verified_at,
    }


@app.patch(
    "/admin/users/{user_id}/active_status",
    response_model=UserResponse,
)
def api_admin_user_active_status(
    user_id: int,
    request: UserAdminStatusUpdate,
    current_user: User = Depends(
        get_admin_user,
    ),
    db: Session = Depends(
        get_db,
    ),
):
    user = get_user_by_id(
        db,
        user_id,
    )

    if user is None:
        raise HTTPException(
            status_code=404,
            detail="Utente non trovato.",
        )

    if (
        user.id ==
        current_user.id
        and not request.is_active
    ):
        raise HTTPException(
            status_code=400,
            detail="Non puoi disattivare il tuo stesso account.",
        )

    if (
        user.role in [
            "admin",
            "creator",
        ]
        and current_user.role !=
        "creator"
    ):
        raise HTTPException(
            status_code=403,
            detail="Solo il creator può modificare lo stato di un amministratore.",
        )

    return set_user_active_status(
        db,
        user,
        request.is_active,
    )


@app.post(
    "/create_group",
    response_model=GroupResponse,
)
def api_create_group(
    request: GroupCreate,
    current_user: User = Depends(
        get_current_user,
    ),
    db: Session = Depends(
        get_db,
    ),
):
    if request.subject_id is not None:
        subject = get_subject_by_id(
            db,
            request.subject_id,
        )

        if subject is None:
            raise HTTPException(
                status_code=404,
                detail="Materia non trovata.",
            )

    secured_request = (
        request.model_copy(
            update={
                "created_by":
                    current_user.id,
            },
        )
    )

    try:
        return create_group(
            db,
            secured_request,
        )

    except IntegrityError:
        db.rollback()

        raise HTTPException(
            status_code=409,
            detail="Impossibile creare il gruppo.",
        )


@app.get(
    "/groups",
    response_model=list[
        GroupResponse
    ],
)
def api_groups(
    db: Session = Depends(
        get_db,
    ),
):
    return get_groups(
        db,
    )


@app.get(
    "/group/{group_id}",
    response_model=GroupDetailResponse,
)
def api_group(
    group_id: int,
    db: Session = Depends(
        get_db,
    ),
):
    group = get_group_by_id(
        db,
        group_id,
    )

    if group is None:
        raise HTTPException(
            status_code=404,
            detail="Gruppo non trovato.",
        )

    return group


@app.get(
    "/user_groups/{user_id}",
    response_model=list[
        GroupResponse
    ],
)
def api_user_groups(
    user_id: int,
    current_user: User = Depends(
        get_current_user,
    ),
    db: Session = Depends(
        get_db,
    ),
):
    if (
        current_user.id !=
        user_id
    ):
        raise HTTPException(
            status_code=403,
            detail="Non puoi visualizzare i gruppi privati di questo utente.",
        )

    return get_groups_by_user(
        db,
        current_user.id,
    )


@app.post(
    "/add_group_member/{group_id}",
    response_model=GroupMemberResponse,
)
def api_add_group_member(
    group_id: int,
    request: AddGroupMemberRequest,
    current_user: User = Depends(
        get_current_user,
    ),
    db: Session = Depends(
        get_db,
    ),
):
    group = get_group_by_id(
        db,
        group_id,
    )

    if group is None:
        raise HTTPException(
            status_code=404,
            detail="Gruppo non trovato.",
        )

    require_group_manager(
        db,
        group_id,
        current_user.id,
    )

    user = get_user_by_id(
        db,
        request.user_id,
    )

    if user is None:
        raise HTTPException(
            status_code=404,
            detail="Utente non trovato.",
        )

    existing_member = get_group_member(
        db,
        group_id,
        request.user_id,
    )

    if existing_member is not None:
        raise HTTPException(
            status_code=409,
            detail="L'utente appartiene già al gruppo.",
        )

    if request.role not in [
        "admin",
        "member",
    ]:
        raise HTTPException(
            status_code=400,
            detail="Ruolo del gruppo non valido.",
        )

    try:
        return add_group_member(
            db,
            group_id,
            request.user_id,
            request.role,
        )

    except IntegrityError:
        db.rollback()

        raise HTTPException(
            status_code=409,
            detail="Impossibile aggiungere il partecipante.",
        )


@app.delete(
    "/remove_group_member/{group_id}/{user_id}",
)
def api_remove_group_member(
    group_id: int,
    user_id: int,
    current_user: User = Depends(
        get_current_user,
    ),
    db: Session = Depends(
        get_db,
    ),
):
    group = get_group_by_id(
        db,
        group_id,
    )

    if group is None:
        raise HTTPException(
            status_code=404,
            detail="Gruppo non trovato.",
        )

    require_group_manager(
        db,
        group_id,
        current_user.id,
    )

    member = get_group_member(
        db,
        group_id,
        user_id,
    )

    if member is None:
        raise HTTPException(
            status_code=404,
            detail="Partecipante non trovato.",
        )

    if member.role == "owner":
        raise HTTPException(
            status_code=400,
            detail="Il proprietario non può essere rimosso dal gruppo.",
        )

    remove_group_member(
        db,
        member,
    )

    return {
        "success":
            True,
        "message":
            "Partecipante rimosso.",
    }


@app.patch(
    "/update_group/{group_id}",
    response_model=GroupResponse,
)
def api_update_group(
    group_id: int,
    request: GroupUpdate,
    current_user: User = Depends(
        get_current_user,
    ),
    db: Session = Depends(
        get_db,
    ),
):
    group = get_group_by_id(
        db,
        group_id,
    )

    if group is None:
        raise HTTPException(
            status_code=404,
            detail="Gruppo non trovato.",
        )

    require_group_manager(
        db,
        group_id,
        current_user.id,
    )

    if request.subject_id is not None:
        subject = get_subject_by_id(
            db,
            request.subject_id,
        )

        if subject is None:
            raise HTTPException(
                status_code=404,
                detail="Materia non trovata.",
            )

    return update_group(
        db,
        group,
        request,
    )


@app.patch(
    "/update_group_member_role/{group_id}/{user_id}",
    response_model=GroupMemberResponse,
)
def api_update_group_member_role(
    group_id: int,
    user_id: int,
    request: ChangeGroupMemberRoleRequest,
    current_user: User = Depends(
        get_current_user,
    ),
    db: Session = Depends(
        get_db,
    ),
):
    require_group_manager(
        db,
        group_id,
        current_user.id,
    )

    member = get_group_member(
        db,
        group_id,
        user_id,
    )

    if member is None:
        raise HTTPException(
            status_code=404,
            detail="Partecipante non trovato.",
        )

    if member.role == "owner":
        raise HTTPException(
            status_code=400,
            detail="Il ruolo del proprietario non può essere modificato.",
        )

    if request.role not in [
        "admin",
        "member",
    ]:
        raise HTTPException(
            status_code=400,
            detail="Ruolo non valido.",
        )

    return update_group_member_role(
        db,
        member,
        request.role,
    )


@app.delete(
    "/delete_group/{group_id}",
)
def api_delete_group(
    group_id: int,
    current_user: User = Depends(
        get_current_user,
    ),
    db: Session = Depends(
        get_db,
    ),
):
    group = get_group_by_id(
        db,
        group_id,
    )

    if group is None:
        raise HTTPException(
            status_code=404,
            detail="Gruppo non trovato.",
        )

    member = require_group_member(
        db,
        group_id,
        current_user.id,
    )

    if member.role != "owner":
        raise HTTPException(
            status_code=403,
            detail="Solo il proprietario può eliminare il gruppo.",
        )

    delete_group(
        db,
        group,
    )

    return {
        "success":
            True,
        "message":
            "Gruppo eliminato.",
    }


@app.post(
    "/request_join_group/{group_id}",
    response_model=JoinGroupResponse,
)
def api_request_join_group(
    group_id: int,
    request: GroupJoinRequestCreate,
    current_user: User = Depends(
        get_current_user,
    ),
    db: Session = Depends(
        get_db,
    ),
):
    group = get_group_by_id(
        db,
        group_id,
    )

    if group is None:
        raise HTTPException(
            status_code=404,
            detail="Gruppo non trovato.",
        )

    member = get_group_member(
        db,
        group_id,
        current_user.id,
    )

    if member is not None:
        raise HTTPException(
            status_code=409,
            detail="L'utente appartiene già al gruppo.",
        )

    existing_request = (
        get_group_join_request(
            db,
            group_id,
            current_user.id,
        )
    )

    if (
        existing_request is not None
        and existing_request.status ==
        "pending"
    ):
        raise HTTPException(
            status_code=409,
            detail="Richiesta già inviata.",
        )

    if not group.is_private:
        try:
            add_group_member(
                db,
                group_id,
                current_user.id,
                "member",
            )

            return JoinGroupResponse(
                joined=True,
                pending=False,
                message="Ingresso nel gruppo completato.",
            )

        except IntegrityError:
            db.rollback()

            raise HTTPException(
                status_code=409,
                detail="Impossibile entrare nel gruppo.",
            )

    try:
        create_group_join_request(
            db,
            group_id,
            current_user.id,
        )

        return JoinGroupResponse(
            joined=False,
            pending=True,
            message="Richiesta di partecipazione inviata.",
        )

    except IntegrityError:
        db.rollback()

        raise HTTPException(
            status_code=409,
            detail="Impossibile inviare la richiesta.",
        )


@app.get(
    "/group_requests/{group_id}",
    response_model=list[
        GroupJoinRequestResponse
    ],
)
def api_group_requests(
    group_id: int,
    current_user: User = Depends(
        get_current_user,
    ),
    db: Session = Depends(
        get_db,
    ),
):
    group = get_group_by_id(
        db,
        group_id,
    )

    if group is None:
        raise HTTPException(
            status_code=404,
            detail="Gruppo non trovato.",
        )

    require_group_manager(
        db,
        group_id,
        current_user.id,
    )

    return get_group_join_requests(
        db,
        group_id,
    )


@app.post(
    "/accept_group_request/{request_id}",
    response_model=GroupMemberResponse,
)
def api_accept_group_request(
    request_id: int,
    current_user: User = Depends(
        get_current_user,
    ),
    db: Session = Depends(
        get_db,
    ),
):
    join_request = (
        get_group_join_request_by_id(
            db,
            request_id,
        )
    )

    if join_request is None:
        raise HTTPException(
            status_code=404,
            detail="Richiesta non trovata.",
        )

    require_group_manager(
        db,
        join_request.group_id,
        current_user.id,
    )

    if (
        join_request.status !=
        "pending"
    ):
        raise HTTPException(
            status_code=400,
            detail="La richiesta è già stata elaborata.",
        )

    member = get_group_member(
        db,
        join_request.group_id,
        join_request.user_id,
    )

    if member is not None:
        raise HTTPException(
            status_code=409,
            detail="L'utente appartiene già al gruppo.",
        )

    try:
        return accept_group_join_request(
            db,
            join_request,
        )

    except IntegrityError:
        db.rollback()

        raise HTTPException(
            status_code=409,
            detail="Impossibile accettare la richiesta.",
        )


@app.post(
    "/reject_group_request/{request_id}",
    response_model=GroupJoinRequestResponse,
)
def api_reject_group_request(
    request_id: int,
    current_user: User = Depends(
        get_current_user,
    ),
    db: Session = Depends(
        get_db,
    ),
):
    join_request = (
        get_group_join_request_by_id(
            db,
            request_id,
        )
    )

    if join_request is None:
        raise HTTPException(
            status_code=404,
            detail="Richiesta non trovata.",
        )

    require_group_manager(
        db,
        join_request.group_id,
        current_user.id,
    )

    if (
        join_request.status !=
        "pending"
    ):
        raise HTTPException(
            status_code=400,
            detail="La richiesta è già stata elaborata.",
        )

    return reject_group_join_request(
        db,
        join_request,
    )


@app.post(
    "/group_material_upload_request/{group_id}",
)
def api_group_material_upload_request(
    group_id: int,
    request: GroupMaterialUploadRequest,
    current_user: User = Depends(
        get_current_user,
    ),
    db: Session = Depends(
        get_db,
    ),
):
    group = get_group_by_id(
        db,
        group_id,
    )

    if group is None:
        raise HTTPException(
            status_code=404,
            detail="Gruppo non trovato.",
        )

    require_group_member(
        db,
        group_id,
        current_user.id,
    )

    try:
        validate_material_size(
            request.size,
        )

        validate_material_mime_type(
            request.mime_type,
        )

        ensure_material_not_duplicate(
            db,
            group_id,
            request.file_hash,
        )

    except ValueError as exception:
        message = str(
            exception,
        )

        status_code = (
            409
            if "già presente" in message
            else 400
        )

        raise HTTPException(
            status_code=status_code,
            detail=message,
        )

    stored_name = generate_stored_name(
        group_id,
        request.original_name,
    )

    return {
        "allowed":
            True,
        "pathname":
            stored_name,
        "max_file_size":
            250 *
            1024 *
            1024,
    }


@app.post(
    "/group_material_complete/{group_id}",
    response_model=GroupMaterialResponse,
)
def api_group_material_complete(
    group_id: int,
    request: GroupMaterialCompleteRequest,
    current_user: User = Depends(
        get_current_user,
    ),
    db: Session = Depends(
        get_db,
    ),
):
    group = get_group_by_id(
        db,
        group_id,
    )

    if group is None:
        raise HTTPException(
            status_code=404,
            detail="Gruppo non trovato.",
        )

    require_group_member(
        db,
        group_id,
        current_user.id,
    )

    try:
        validate_material_size(
            request.size,
        )

        validate_material_mime_type(
            request.mime_type,
        )

        ensure_material_not_duplicate(
            db,
            group_id,
            request.file_hash,
        )

        return create_group_material_record(
            db=db,
            group_id=group_id,
            uploaded_by=current_user.id,
            original_name=(
                request.original_name
            ),
            stored_name=(
                request.stored_name
            ),
            file_path=(
                request.file_path
            ),
            mime_type=(
                request.mime_type
            ),
            size=request.size,
            file_hash=(
                request.file_hash
            ),
        )

    except ValueError as exception:
        message = str(
            exception,
        )

        status_code = (
            409
            if "già presente" in message
            else 400
        )

        raise HTTPException(
            status_code=status_code,
            detail=message,
        )


@app.get(
    "/group_materials/{group_id}",
    response_model=list[
        GroupMaterialResponse
    ],
)
def api_group_materials(
    group_id: int,
    current_user: User = Depends(
        get_current_user,
    ),
    db: Session = Depends(
        get_db,
    ),
):
    group = get_group_by_id(
        db,
        group_id,
    )

    if group is None:
        raise HTTPException(
            status_code=404,
            detail="Gruppo non trovato.",
        )

    require_group_member(
        db,
        group_id,
        current_user.id,
    )

    return get_group_materials(
        db,
        group_id,
    )


@app.get(
    "/group_material/{material_id}",
)
async def api_group_material(
    material_id: int,
    current_user: User = Depends(
        get_current_user,
    ),
    db: Session = Depends(
        get_db,
    ),
):
    material = get_group_material_by_id(
        db,
        material_id,
    )

    if material is None:
        raise HTTPException(
            status_code=404,
            detail="Materiale non trovato.",
        )

    require_group_member(
        db,
        material.group_id,
        current_user.id,
    )

    if not settings.blob_read_write_token:
        raise HTTPException(
            status_code=500,
            detail="Storage dei file non configurato.",
        )

    client = AsyncBlobClient(
        token=(
            settings.blob_read_write_token
        ),
    )

    result = await client.get(
        material.stored_name,
        access="private",
    )

    if (
        result is None
        or result.status_code !=
        200
    ):
        raise HTTPException(
            status_code=404,
            detail="File non disponibile.",
        )

    headers = {
        "Content-Disposition":
            (
                f'attachment; filename="{material.original_name}"'
            ),
        "X-Content-Type-Options":
            "nosniff",
    }

    return StreamingResponse(
        result.stream,
        media_type=(
            material.mime_type
        ),
        headers=headers,
    )


@app.delete(
    "/remove_group_material/{material_id}",
)
async def api_remove_group_material(
    material_id: int,
    current_user: User = Depends(
        get_current_user,
    ),
    db: Session = Depends(
        get_db,
    ),
):
    material = get_group_material_by_id(
        db,
        material_id,
    )

    if material is None:
        raise HTTPException(
            status_code=404,
            detail="Materiale non trovato.",
        )

    member = require_group_member(
        db,
        material.group_id,
        current_user.id,
    )

    can_delete = (
        material.uploaded_by ==
        current_user.id
        or member.role in [
            "owner",
            "admin",
        ]
    )

    if not can_delete:
        raise HTTPException(
            status_code=403,
            detail="Non puoi eliminare questo materiale.",
        )

    try:
        await delete_group_material(
            db,
            material,
        )

    except RuntimeError as exception:
        raise HTTPException(
            status_code=500,
            detail=str(
                exception,
            ),
        )

    return {
        "success":
            True,
        "message":
            "Materiale eliminato.",
    }


@app.post(
    "/register",
    response_model=TokenResponse,
)
def api_register(
    request: RegisterRequest,
    db: Session = Depends(
        get_db,
    ),
):
    normalized_email = (
        request.email
        .strip()
        .lower()
    )

    existing_user = get_user_by_email(
        db,
        normalized_email,
    )

    if existing_user is not None:
        raise HTTPException(
            status_code=409,
            detail="Email già registrata.",
        )

    academic_values = [
        request.university,
        request.university_code,
        request.department,
        request.department_code,
        request.course,
        request.course_code,
    ]

    has_academic_data = any(
        value is not None
        and str(
            value,
        ).strip()
        for value in academic_values
    )

    has_complete_academic_data = all(
        value is not None
        and str(
            value,
        ).strip()
        for value in academic_values
    )

    if (
        has_academic_data
        and not
        has_complete_academic_data
    ):
        raise HTTPException(
            status_code=400,
            detail="I dati del percorso accademico sono incompleti.",
        )

    role = (
        request.role
        .strip()
        .lower()
    )

    available_for_help = (
        request.available_for_help
    )

    if (
        "available_for_help"
        not in
        request.model_fields_set
    ):
        available_for_help = (
            request.available
        )

    available_for_private_lessons = (
        request.available_for_private_lessons
    )

    if (
        "available_for_private_lessons"
        not in
        request.model_fields_set
        and request.willing_to_teach
        is not None
    ):
        available_for_private_lessons = (
            request.willing_to_teach
        )

    teacher_verification_status = (
        "pending"
        if role == "teacher"
        else "not_required"
    )

    user = User(
        first_name=(
            request.first_name
            .strip()
        ),
        last_name=(
            request.last_name
            .strip()
        ),
        email=normalized_email,
        password_hash=(
            hash_password(
                request.password,
            )
        ),
        university=(
            request.university
        ),
        department=(
            request.department
        ),
        course=(
            request.course
        ),
        description=(
            request.description
        ),
        role=role,
        teacher_verification_status=(
            teacher_verification_status
        ),
        available=(
            request.available
        ),
        available_for_help=(
            available_for_help
        ),
        available_for_private_lessons=(
            available_for_private_lessons
        ),
        willing_to_teach=(
            available_for_private_lessons
        ),
        is_active=True,
    )

    db.add(
        user,
    )

    try:
        db.flush()

        if has_complete_academic_data:
            academic_status = (
                request.academic_status
            )

            academic_path = UserAcademicPath(
                user_id=user.id,
                university=(
                    request.university
                ),
                university_code=(
                    request.university_code
                ),
                department=(
                    request.department
                ),
                department_code=(
                    request.department_code
                ),
                course=(
                    request.course
                ),
                course_code=(
                    request.course_code
                ),
                degree_type=(
                    request.degree_type
                ),
                status=(
                    academic_status
                ),
                verification_status=(
                    "pending"
                    if academic_status ==
                    "graduated"
                    else "not_required"
                ),
                verified_by=None,
                verified_at=None,
                start_year=(
                    request.start_year
                ),
                graduation_year=(
                    request.graduation_year
                ),
                is_current=(
                    academic_status ==
                    "enrolled"
                ),
                is_primary=True,
            )

            db.add(
                academic_path,
            )

        db.commit()

        db.refresh(
            user,
        )

    except IntegrityError:
        db.rollback()

        raise HTTPException(
            status_code=409,
            detail="Impossibile registrare l'utente.",
        )

    token = create_access_token(
        user_id=user.id,
        secret_key=(
            settings.secret_key
        ),
    )

    return TokenResponse(
        access_token=token,
    )


@app.post(
    "/login",
    response_model=TokenResponse,
)
def api_login(
    request: LoginRequest,
    db: Session = Depends(
        get_db,
    ),
):
    user = authenticate_user(
        db,
        request.email,
        request.password,
    )

    if user is None:
        raise HTTPException(
            status_code=401,
            detail="Email o password non corrette.",
        )

    token = create_access_token(
        user_id=user.id,
        secret_key=(
            settings.secret_key
        ),
    )

    return TokenResponse(
        access_token=token,
    )


@app.get(
    "/me",
    response_model=UserResponse,
)
def api_me(
    current_user: User = Depends(
        get_current_user,
    ),
):
    return current_user


@app.get(
    "/app_version",
    response_model=AppConfigResponse,
)
def api_app_version(
    db: Session = Depends(
        get_db,
    ),
):
    return get_app_config(
        db,
    )


@app.get(
    "/users/{user_id}/reviews",
    response_model=UserReviewsResponse,
)
def api_user_reviews(
    user_id: int,
    db: Session = Depends(
        get_db,
    ),
):
    try:
        return serialize_public_user_reviews(
            db,
            reviewed_user_id=user_id,
            current_user=None,
        )

    except ValueError as exception:
        raise HTTPException(
            status_code=404,
            detail=str(
                exception,
            ),
        )


@app.get(
    "/users/{user_id}/reviews/me",
    response_model=ReviewResponse | None,
)
def api_my_review_for_user(
    user_id: int,
    current_user: User = Depends(
        get_current_user,
    ),
    db: Session = Depends(
        get_db,
    ),
):
    if current_user.id == user_id:
        return None

    review = get_review_between_users(
        db,
        reviewer_id=current_user.id,
        reviewed_user_id=user_id,
    )

    if review is None:
        return None

    return serialize_review(
        db,
        review,
    )


@app.post(
    "/users/{user_id}/reviews",
    response_model=ReviewResponse,
)
def api_create_review(
    user_id: int,
    request: ReviewCreate,
    current_user: User = Depends(
        get_current_user,
    ),
    db: Session = Depends(
        get_db,
    ),
):
    try:
        review = create_review(
            db,
            reviewer=current_user,
            reviewed_user_id=user_id,
            data=request,
        )

        return serialize_review(
            db,
            review,
        )

    except ValueError as exception:
        message = str(
            exception,
        )

        if message in [
            "Utente non trovato.",
            "Materia non trovata.",
        ]:
            status_code = 404

        elif message == "Hai già recensito questo utente.":
            status_code = 409

        else:
            status_code = 400

        raise HTTPException(
            status_code=status_code,
            detail=message,
        )


@app.put(
    "/users/{user_id}/reviews/me",
    response_model=ReviewResponse,
)
def api_update_my_review(
    user_id: int,
    request: ReviewUpdate,
    current_user: User = Depends(
        get_current_user,
    ),
    db: Session = Depends(
        get_db,
    ),
):
    try:
        review = update_review(
            db,
            reviewer=current_user,
            reviewed_user_id=user_id,
            data=request,
        )

        return serialize_review(
            db,
            review,
        )

    except ValueError as exception:
        message = str(
            exception,
        )

        if message in [
            "Recensione non trovata.",
            "Materia non trovata.",
        ]:
            status_code = 404
        else:
            status_code = 400

        raise HTTPException(
            status_code=status_code,
            detail=message,
        )


@app.delete(
    "/users/{user_id}/reviews/me",
)
def api_delete_my_review(
    user_id: int,
    current_user: User = Depends(
        get_current_user,
    ),
    db: Session = Depends(
        get_db,
    ),
):
    try:
        delete_review(
            db,
            reviewer=current_user,
            reviewed_user_id=user_id,
        )

    except ValueError as exception:
        raise HTTPException(
            status_code=404,
            detail=str(
                exception,
            ),
        )

    return {
        "success":
            True,
        "message":
            "Recensione eliminata.",
    }


@app.get(
    "/admin/reviews",
    response_model=AdminReviewsResponse,
)
def api_admin_reviews(
    moderation_status: str | None = None,
    current_user: User = Depends(
        get_admin_user,
    ),
    db: Session = Depends(
        get_db,
    ),
):
    if (
        moderation_status is not None
        and moderation_status not in [
            "pending",
            "approved",
            "rejected",
            "hidden",
        ]
    ):
        raise HTTPException(
            status_code=400,
            detail="Stato di moderazione non valido.",
        )

    return serialize_admin_reviews(
        db,
        moderation_status=moderation_status,
    )


@app.get(
    "/admin/reviews/pending",
    response_model=AdminReviewsResponse,
)
def api_admin_pending_reviews(
    current_user: User = Depends(
        get_admin_user,
    ),
    db: Session = Depends(
        get_db,
    ),
):
    return serialize_admin_reviews(
        db,
        moderation_status="pending",
    )


@app.patch(
    "/admin/reviews/{review_id}/moderation",
    response_model=ReviewResponse,
)
def api_moderate_review(
    review_id: int,
    request: ReviewModerationUpdate,
    current_user: User = Depends(
        get_admin_user,
    ),
    db: Session = Depends(
        get_db,
    ),
):
    try:
        review = moderate_review(
            db,
            review_id=review_id,
            moderator=current_user,
            status=request.status,
        )

        return serialize_review(
            db,
            review,
        )

    except ValueError as exception:
        message = str(
            exception,
        )

        if message == "Recensione non trovata.":
            status_code = 404
        else:
            status_code = 400

        raise HTTPException(
            status_code=status_code,
            detail=message,
        )


@app.post(
    "/admin/reviews/{review_id}/restore",
    response_model=ReviewResponse,
)
def api_restore_review(
    review_id: int,
    current_user: User = Depends(
        get_admin_user,
    ),
    db: Session = Depends(
        get_db,
    ),
):
    try:
        review = restore_hidden_review(
            db,
            review_id=review_id,
            moderator=current_user,
        )

        return serialize_review(
            db,
            review,
        )

    except ValueError as exception:
        message = str(
            exception,
        )

        if message == "Recensione non trovata.":
            status_code = 404
        else:
            status_code = 400

        raise HTTPException(
            status_code=status_code,
            detail=message,
        )
    
@app.get(
    "/admin/access",
)
def api_admin_access(
    current_user: User = Depends(
        get_admin_user,
    ),
):
    return {
        "authorized":
            True,
    }


@app.get(
    "/teacher/access",
)
def api_teacher_access(
    current_user: User = Depends(
        get_verified_teacher_user,
    ),
):
    return {
        "authorized":
            True,
    }

@app.post(
    "/teacher/materials",
)
async def api_teacher_material(
    current_user: User = Depends(
        get_verified_teacher_user,
    ),
    db: Session = Depends(
        get_db,
    ),
):
    return {
        "authorized":
            True,
    }

@app.get(
    "/admin/users",
    response_model=list[
        UserResponse
    ],
)
def api_admin_users(
    current_user: User = Depends(
        get_admin_user,
    ),
    db: Session = Depends(
        get_db,
    ),
):
    return (
        db.query(
            User,
        )
        .order_by(
            User.last_name.asc(),
            User.first_name.asc(),
        )
        .all()
    )
@app.get(
    "/teacher/access",
)
def api_teacher_access(
    current_user: User = Depends(
        get_verified_teacher_user,
    ),
):
    return {
        "authorized":
            True,
    }


@app.get(
    "/teacher/subjects",
)
def api_teacher_subjects(
    current_user: User = Depends(
        get_verified_teacher_user,
    ),
    db: Session = Depends(
        get_db,
    ),
):
    relations = (
        db.query(
            UserSubject,
        )
        .filter(
            UserSubject.user_id ==
            current_user.id,
        )
        .all()
    )

    result = []

    for relation in relations:
        subject = (
            db.query(
                Subject,
            )
            .filter(
                Subject.id ==
                relation.subject_id,
            )
            .first()
        )

        if subject is None:
            continue

        result.append({
            "id":
                subject.id,
            "code":
                subject.code,
            "name":
                subject.name,
            "department":
                subject.department,
            "course":
                subject.course,
        })

    return result


@app.post(
    "/teacher/materials/upload-request",
)
def api_teacher_material_upload_request(
    request:
        TeacherMaterialUploadRequest,
    current_user: User = Depends(
        get_verified_teacher_user,
    ),
    db: Session = Depends(
        get_db,
    ),
):
    try:
        require_teacher_subject(
            db,
            current_user.id,
            request.subject_id,
        )

        validate_teacher_material_size(
            request.size,
        )

        validate_teacher_material_mime_type(
            request.mime_type,
        )

        ensure_teacher_material_not_duplicate(
            db,
            current_user.id,
            request.subject_id,
            request.file_hash,
        )

        pathname = (
            generate_teacher_material_stored_name(
                current_user.id,
                request.subject_id,
                request.original_name,
            )
        )

        return {
            "allowed":
                True,
            "pathname":
                pathname,
            "file_hash":
                request.file_hash,
            "max_file_size":
                250 *
                1024 *
                1024,
        }

    except PermissionError as exc:
        raise HTTPException(
            status_code=403,
            detail=str(exc),
        )

    except ValueError as exc:
        message = str(
            exc,
        )

        raise HTTPException(
            status_code=(
                409
                if "già presente"
                in message
                else 400
            ),
            detail=message,
        )


@app.post(
    "/teacher/materials/complete",
    response_model=
        TeacherMaterialResponse,
)
def api_teacher_material_complete(
    request:
        TeacherMaterialCompleteRequest,
    current_user: User = Depends(
        get_verified_teacher_user,
    ),
    db: Session = Depends(
        get_db,
    ),
):
    try:
        return create_teacher_material(
            db,
            current_user,
            request,
        )

    except PermissionError as exc:
        raise HTTPException(
            status_code=403,
            detail=str(exc),
        )

    except ValueError as exc:
        message = str(
            exc,
        )

        raise HTTPException(
            status_code=(
                409
                if "già presente"
                in message
                else 400
            ),
            detail=message,
        )


@app.get(
    "/teacher/materials",
    response_model=list[
        TeacherMaterialResponse
    ],
)
def api_teacher_materials(
    current_user: User = Depends(
        get_verified_teacher_user,
    ),
    db: Session = Depends(
        get_db,
    ),
):
    return get_teacher_materials(
        db,
        current_user.id,
    )


@app.get(
    "/teacher/materials/{material_id}",
    response_model=
        TeacherMaterialResponse,
)
def api_teacher_material(
    material_id: int,
    current_user: User = Depends(
        get_verified_teacher_user,
    ),
    db: Session = Depends(
        get_db,
    ),
):
    material = (
        get_teacher_material_by_id(
            db,
            material_id,
        )
    )

    if material is None:
        raise HTTPException(
            status_code=404,
            detail="Materiale non trovato.",
        )

    if (
        material.uploaded_by !=
        current_user.id
    ):
        raise HTTPException(
            status_code=403,
            detail="Non puoi accedere a questo materiale.",
        )

    return material


@app.patch(
    "/teacher/materials/{material_id}",
    response_model=
        TeacherMaterialResponse,
)
def api_teacher_material_update(
    material_id: int,
    request:
        TeacherMaterialUpdate,
    current_user: User = Depends(
        get_verified_teacher_user,
    ),
    db: Session = Depends(
        get_db,
    ),
):
    material = (
        get_teacher_material_by_id(
            db,
            material_id,
        )
    )

    if material is None:
        raise HTTPException(
            status_code=404,
            detail="Materiale non trovato.",
        )

    try:
        return update_teacher_material(
            db,
            material,
            current_user,
            request,
        )

    except PermissionError as exc:
        raise HTTPException(
            status_code=403,
            detail=str(exc),
        )

    except ValueError as exc:
        raise HTTPException(
            status_code=400,
            detail=str(exc),
        )


@app.delete(
    "/teacher/materials/{material_id}",
)
def api_teacher_material_delete(
    material_id: int,
    current_user: User = Depends(
        get_verified_teacher_user,
    ),
    db: Session = Depends(
        get_db,
    ),
):
    material = (
        get_teacher_material_by_id(
            db,
            material_id,
        )
    )

    if material is None:
        raise HTTPException(
            status_code=404,
            detail="Materiale non trovato.",
        )

    try:
        delete_teacher_material(
            db,
            material,
            current_user,
        )

    except PermissionError as exc:
        raise HTTPException(
            status_code=403,
            detail=str(exc),
        )

    return {
        "success":
            True,
    }


@app.get(
    "/subjects/{subject_id}/teacher-materials",
    response_model=list[
        TeacherMaterialResponse
    ],
)
def api_subject_teacher_materials(
    subject_id: int,
    current_user: User = Depends(
        get_current_user,
    ),
    db: Session = Depends(
        get_db,
    ),
):
    return get_student_teacher_materials(
        db,
        subject_id,
    )
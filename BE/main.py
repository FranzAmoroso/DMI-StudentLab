from pathlib import Path

from fastapi import (
    Depends,
    FastAPI,
    File,
    Form,
    HTTPException,
    UploadFile,
)

from fastapi.responses import FileResponse

from fastapi.middleware.cors import CORSMiddleware

from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session



from core.database import (
    get_db,
    create_tables,
)

from core.security import (
    get_current_user,
)

from core.config import (
    settings,
)

from models.user import User

from models.subject import (
    Subject,
    UserSubject,
)

from models.group import (
    StudyGroup,
    GroupMember,
    GroupJoinRequest,
)

from models.material import (
    GroupMaterial,
)

from models.filter import (
    Answer,
    ArgumentsRequest,
    Filter,
    QuestionCountRequest,
    SubjectRequest,
)

from schemas.user import (
    UserCreate,
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
    GroupMaterialResponse,
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
    create_user,
    get_user_by_email,
    get_user_by_id,
    get_user_subject,
    get_users,
    remove_subject_from_user,
    update_user,
)

from services.subject import (
    create_subject,
    get_subjects,
    get_subject_by_id,
    get_existing_subject,
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
    is_group_admin,
    is_group_owner,
    reject_group_join_request,
    remove_group_member,
    update_group,
    update_group_member_role,
)

from services.material import (
    ALLOWED_MIME_TYPES,
    delete_group_material,
    get_group_material_by_id,
    get_group_materials,
    save_group_material,
)


app = FastAPI()

@app.on_event("startup")
def startup_event():
    create_tables()


app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/")
async def root():
    return {
        "status": "Server attivo."
    }

# Potremo successivamente limitare CORS
# al dominio reale di StudentLab invece di usare "*".



@app.post("/shuffle_filter")
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


@app.post("/validate_answer")
def api_validate_answer(
    answer: Answer,
):
    return validate_answer(
        answer.idQuestion,
        answer.idChoice,
        answer.department,
        answer.sub,
    )


@app.post("/arguments")
def api_arguments(
    request: ArgumentsRequest,
):
    return arguments(
        request.department,
        request.course,
        request.sub,
    )


@app.post("/question_count")
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
        "count": count
    }


@app.post("/subjects")
def api_subjects(
    request: SubjectRequest,
):
    return subjects(
        request.department,
        request.course,
    )

@app.post(
    "/create_user",
    response_model=UserResponse,
)
def api_create_user(
    request: UserCreate,
    db: Session = Depends(get_db),
):
    existing_user = get_user_by_email(
        db,
        request.email,
    )

    if existing_user is not None:
        raise HTTPException(
            status_code=409,
            detail="Email già registrata.",
        )

    if request.role not in [
        "student",
        "teacher",
    ]:
        raise HTTPException(
            status_code=400,
            detail="Ruolo utente non valido.",
        )

    try:
        return create_user(
            db,
            request,
        )

    except IntegrityError:
        db.rollback()

        raise HTTPException(
            status_code=409,
            detail="Impossibile creare l'utente.",
        )


@app.get(
    "/users",
    response_model=list[UserResponse],
)
def api_users(
    db: Session = Depends(get_db),
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
    db: Session = Depends(get_db),
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
    db: Session = Depends(get_db),
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
        request.role is not None
        and request.role not in [
            "student",
            "teacher",
        ]
    ):
        raise HTTPException(
            status_code=400,
            detail="Ruolo utente non valido.",
        )

    return update_user(
        db,
        user,
        request,
    )


# In seguito questi endpoint utilizzeranno
# l'utente autenticato ricavato dal token,
# quindi non sarà necessario fidarsi di user_id
# ricevuto direttamente dal client.

@app.post(
    "/create_subject",
    response_model=SubjectResponse,
)
def api_create_subject(
    request: SubjectCreate,
    db: Session = Depends(get_db),
):
    existing_subject = get_existing_subject(
        db,
        request.name,
        request.department,
        request.course,
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
    response_model=list[SubjectResponse],
)
def api_social_subjects(
    department: str,
    course: str,
    db: Session = Depends(get_db),
):
    return get_subjects_by_course(
        db,
        department,
        course,
    )


# Potremo successivamente impedire agli utenti normali
# di creare direttamente nuove materie e permettere
# soltanto una proposta da approvare.


@app.post(
    "/add_user_subject/{user_id}",
    response_model=UserResponse,
)
def api_add_user_subject(
    user_id: int,
    request: UserSubjectCreate,
    db: Session = Depends(get_db),
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

    if (
        request.grade is not None
        and (
            request.grade < 18
            or request.grade > 30
        )
    ):
        raise HTTPException(
            status_code=400,
            detail="Il voto deve essere compreso tra 18 e 30.",
        )

    try:
        add_subject_to_user(
            db,
            user_id,
            request,
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
    db: Session = Depends(get_db),
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
        "success": True,
        "message": "Materia rimossa.",
    }

@app.post(
    "/create_group",
    response_model=GroupResponse,
)
def api_create_group(
    request: GroupCreate,
    db: Session = Depends(get_db),
):
    user = get_user_by_id(
        db,
        request.created_by,
    )

    if user is None:
        raise HTTPException(
            status_code=404,
            detail="Utente non trovato.",
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

    try:
        return create_group(
            db,
            request,
        )

    except IntegrityError:
        db.rollback()

        raise HTTPException(
            status_code=409,
            detail="Impossibile creare il gruppo.",
        )


# Quando aggiungeremo l'autenticazione,
# created_by verrà ottenuto dal token
# invece di essere accettato dal client.

@app.get(
    "/groups",
    response_model=list[GroupResponse],
)
def api_groups(
    db: Session = Depends(get_db),
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
    db: Session = Depends(get_db),
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
    response_model=list[GroupResponse],
)
def api_user_groups(
    user_id: int,
    db: Session = Depends(get_db),
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

    return get_groups_by_user(
        db,
        user_id,
    )

@app.post(
    "/add_group_member/{group_id}",
    response_model=GroupMemberResponse,
)
def api_add_group_member(
    group_id: int,
    request: AddGroupMemberRequest,
    db: Session = Depends(get_db),
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


# Quando avremo l'autenticazione,
# questo endpoint verificherà automaticamente
# che chi effettua la richiesta sia owner/admin.

@app.delete(
    "/remove_group_member/{group_id}/{user_id}",
)
def api_remove_group_member(
    group_id: int,
    user_id: int,
    db: Session = Depends(get_db),
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
        "success": True,
        "message": "Partecipante rimosso.",
    }


# Dopo l'autenticazione controlleremo qui
# i privilegi dell'utente che esegue l'operazione.

@app.patch(
    "/update_group/{group_id}",
    response_model=GroupResponse,
)
def api_update_group(
    group_id: int,
    request: GroupUpdate,
    db: Session = Depends(get_db),
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


# Dopo l'autenticazione la modifica sarà
# permessa esclusivamente ad owner/admin.

@app.patch(
    "/update_group_member_role/{group_id}/{user_id}",
    response_model=GroupMemberResponse,
)
def api_update_group_member_role(
    group_id: int,
    user_id: int,
    request: ChangeGroupMemberRoleRequest,
    db: Session = Depends(get_db),
):
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


# La promozione/rimozione di un amministratore
# verrà autorizzata dal proprietario del gruppo.

@app.delete(
    "/delete_group/{group_id}",
)
def api_delete_group(
    group_id: int,
    db: Session = Depends(get_db),
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

    delete_group(
        db,
        group,
    )

    return {
        "success": True,
        "message": "Gruppo eliminato.",
    }


# Dopo l'autenticazione solo il proprietario
# potrà eliminare definitivamente il gruppo.

@app.post(
    "/request_join_group/{group_id}",
    response_model=JoinGroupResponse,
)
def api_request_join_group(
    group_id: int,
    request: GroupJoinRequestCreate,
    db: Session = Depends(get_db),
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

    user = get_user_by_id(
        db,
        request.user_id,
    )

    if user is None:
        raise HTTPException(
            status_code=404,
            detail="Utente non trovato.",
        )

    member = get_group_member(
        db,
        group_id,
        request.user_id,
    )

    if member is not None:
        raise HTTPException(
            status_code=409,
            detail="L'utente appartiene già al gruppo.",
        )

    existing_request = get_group_join_request(
        db,
        group_id,
        request.user_id,
    )

    if (
        existing_request is not None
        and existing_request.status == "pending"
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
                request.user_id,
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
            request.user_id,
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


# In seguito user_id verrà ricavato
# dall'utente autenticato invece di essere
# ricevuto direttamente dal client.

@app.get(
    "/group_requests/{group_id}",
    response_model=list[GroupJoinRequestResponse],
)
def api_group_requests(
    group_id: int,
    db: Session = Depends(get_db),
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
    db: Session = Depends(get_db),
):
    request = get_group_join_request_by_id(
        db,
        request_id,
    )

    if request is None:
        raise HTTPException(
            status_code=404,
            detail="Richiesta non trovata.",
        )

    if request.status != "pending":
        raise HTTPException(
            status_code=400,
            detail="La richiesta è già stata elaborata.",
        )

    member = get_group_member(
        db,
        request.group_id,
        request.user_id,
    )

    if member is not None:
        raise HTTPException(
            status_code=409,
            detail="L'utente appartiene già al gruppo.",
        )

    try:
        return accept_group_join_request(
            db,
            request,
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
    db: Session = Depends(get_db),
):
    request = get_group_join_request_by_id(
        db,
        request_id,
    )

    if request is None:
        raise HTTPException(
            status_code=404,
            detail="Richiesta non trovata.",
        )

    if request.status != "pending":
        raise HTTPException(
            status_code=400,
            detail="La richiesta è già stata elaborata.",
        )

    return reject_group_join_request(
        db,
        request,
    )


# Quando aggiungeremo l'autenticazione,
# group_requests, accept e reject dovranno verificare
# che l'utente corrente sia owner/admin del gruppo.

@app.post(
    "/add_group_material/{group_id}",
    response_model=GroupMaterialResponse,
)
def api_add_group_material(
    group_id: int,

    uploaded_by: int = Form(...),

    file: UploadFile = File(...),

    db: Session = Depends(get_db),
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

    user = get_user_by_id(
        db,
        uploaded_by,
    )

    if user is None:
        raise HTTPException(
            status_code=404,
            detail="Utente non trovato.",
        )

    member = get_group_member(
        db,
        group_id,
        uploaded_by,
    )

    if member is None:
        raise HTTPException(
            status_code=403,
            detail="L'utente non appartiene al gruppo.",
        )

    if (
        file.content_type
        not in ALLOWED_MIME_TYPES
    ):
        raise HTTPException(
            status_code=400,
            detail="Tipo di file non supportato.",
        )

    try:
        return save_group_material(
            db,
            group_id,
            uploaded_by,
            file,
        )

    except ValueError as exception:
        raise HTTPException(
            status_code=413,
            detail=str(exception),
        )


# In seguito uploaded_by verrà ricavato
# direttamente dall'utente autenticato.

@app.get(
    "/group_materials/{group_id}",
    response_model=list[GroupMaterialResponse],
)
def api_group_materials(
    group_id: int,
    db: Session = Depends(get_db),
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

    return get_group_materials(
        db,
        group_id,
    )

@app.get(
    "/group_material/{material_id}",
)
def api_group_material(
    material_id: int,
    db: Session = Depends(get_db),
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

    path = Path(
        material.file_path
    )

    if not path.exists():
        raise HTTPException(
            status_code=404,
            detail="File non disponibile sul server.",
        )

    return FileResponse(
        path=str(path),

        media_type=material.mime_type,

        filename=material.original_name,
    )

@app.delete(
    "/remove_group_material/{material_id}",
)
def api_remove_group_material(
    material_id: int,
    user_id: int,
    db: Session = Depends(get_db),
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

    member = get_group_member(
        db,
        material.group_id,
        user_id,
    )

    if member is None:
        raise HTTPException(
            status_code=403,
            detail="Utente non autorizzato.",
        )

    can_delete = (
        material.uploaded_by == user_id
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

    delete_group_material(
        db,
        material,
    )

    return {
        "success": True,
        "message": "Materiale eliminato.",
    }


# In seguito user_id verrà ricavato
# dall'utente autenticato.

@app.post(
    "/register",
    response_model=TokenResponse,
)
def api_register(
    request: RegisterRequest,
    db: Session = Depends(get_db),
):
    existing_user = get_user_by_email(
        db,
        request.email,
    )

    if existing_user is not None:
        raise HTTPException(
            status_code=409,
            detail="Email già registrata.",
        )

    if request.role not in [
        "student",
        "teacher",
    ]:
        raise HTTPException(
            status_code=400,
            detail="Ruolo non valido.",
        )

    user = User(
        first_name=request.first_name,
        last_name=request.last_name,
        email=request.email,

        password_hash=hash_password(
            request.password,
        ),

        department=request.department,
        course=request.course,

        description=request.description,

        role=request.role,

        available=request.available,

        willing_to_teach=(
            request.willing_to_teach
        ),

        is_active=True,
    )

    db.add(user)

    try:
        db.commit()
        db.refresh(user)

    except IntegrityError:
        db.rollback()

        raise HTTPException(
            status_code=409,
            detail="Impossibile registrare l'utente.",
        )

    token = create_access_token(
        user_id=user.id,
        secret_key=settings.secret_key,
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
    db: Session = Depends(get_db),
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

    if not user.is_active:
        raise HTTPException(
            status_code=403,
            detail="Utente non attivo.",
        )

    token = create_access_token(
        user_id=user.id,
        secret_key=settings.secret_key,
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
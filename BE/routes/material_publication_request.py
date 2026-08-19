from pathlib import Path
from uuid import uuid4

from fastapi import (
    APIRouter,
    Depends,
    HTTPException,
)

from fastapi.responses import (
    Response,
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
    get_db,
)

from core.security import (
    get_admin_user,
    get_current_user,
)

from models.user import (
    User,
)

from schemas.material_publication_request import (
    MaterialDuplicateReviewRequest,
    MaterialPublicationApproveRequest,
    MaterialPublicationCompleteRequest,
    MaterialPublicationRequestAdminResponse,
    MaterialPublicationRequestResponse,
    MaterialPublicationRejectRequest,
    MaterialPublicationUploadRequest,
)

from schemas.public_material import (
    PublicMaterialAdminResponse,
)

from services.material_publication_request import (
    MAX_PUBLIC_MATERIAL_SIZE,
    approve_material_publication_request,
    create_material_publication_request,
    find_duplicate_candidate,
    get_pending_publication_requests,
    get_publication_request_by_id,
    get_publication_requests,
    get_subject_for_publication,
    get_user_publication_requests,
    reject_material_publication_request,
    review_material_duplicate,
    validate_publication_material_mime_type,
    validate_publication_material_size,
)

from services.public_material import (
    get_public_material_by_id,
)


router = APIRouter()


def generate_publication_stored_name(
    user_id: int,
    original_name: str,
):
    extension = (
        Path(
            original_name,
        )
        .suffix
        .lower()
    )

    return (
        "material-publication/"
        f"{user_id}/"
        f"{uuid4().hex}"
        f"{extension}"
    )


def validate_publication_storage_path(
    *,
    user_id: int,
    stored_name: str,
):
    expected_prefix = (
        f"material-publication/{user_id}/"
    )

    if not stored_name.startswith(
        expected_prefix,
    ):
        raise ValueError(
            "Percorso del materiale non valido.",
        )


def require_blob_storage():
    if not settings.blob_read_write_token:
        raise HTTPException(
            status_code=500,
            detail=(
                "Servizio file temporaneamente "
                "non disponibile."
            ),
        )


async def verify_uploaded_blob(
    *,
    stored_name: str,
    expected_size: int,
    expected_mime_type: str,
):
    require_blob_storage()

    try:
        async with AsyncBlobClient(
            token=(
                settings.blob_read_write_token
            ),
        ) as client:
            result = await client.get(
                stored_name,
                access="private",
            )

    except Exception as exception:
        raise HTTPException(
            status_code=400,
            detail=(
                "Il file non risulta caricato "
                "correttamente."
            ),
        ) from exception

    if (
        result is None
        or result.status_code != 200
    ):
        raise HTTPException(
            status_code=400,
            detail=(
                "Il file caricato non è "
                "disponibile."
            ),
        )

    if (
        result.size is not None
        and result.size != expected_size
    ):
        raise HTTPException(
            status_code=400,
            detail=(
                "La dimensione del file "
                "caricato non corrisponde "
                "alla richiesta."
            ),
        )

    if result.content_type is not None:
        actual_content_type = (
            result.content_type
            .split(
                ";",
                1,
            )[0]
            .strip()
            .lower()
        )

        expected_content_type = (
            expected_mime_type
            .strip()
            .lower()
        )

        if (
            actual_content_type
            != expected_content_type
        ):
            raise HTTPException(
                status_code=400,
                detail=(
                    "Il tipo del file caricato "
                    "non corrisponde alla richiesta."
                ),
            )

    return result


async def stream_private_blob(
    *,
    stored_name: str,
    original_name: str,
    mime_type: str,
):
    require_blob_storage()

    try:
        async with AsyncBlobClient(
            token=(
                settings.blob_read_write_token
            ),
        ) as client:
            result = await client.get(
                stored_name,
                access="private",
            )

    except Exception as exception:
        raise HTTPException(
            status_code=503,
            detail=(
                "Il file è temporaneamente "
                "non disponibile."
            ),
        ) from exception

    if (
        result is None
        or result.status_code != 200
    ):
        raise HTTPException(
            status_code=404,
            detail="File non disponibile.",
        )

    response_mime_type = (
        result.content_type
        if result.content_type
        else mime_type
    )

    safe_original_name = (
        original_name
        .replace(
            '"',
            "",
        )
        .replace(
            "\r",
            "",
        )
        .replace(
            "\n",
            "",
        )
    )

    headers = {
        "Content-Disposition": (
            f'inline; filename="{safe_original_name}"'
        ),
        "X-Content-Type-Options": (
            "nosniff"
        ),
        "Cache-Control": (
            "private, no-store"
        ),
    }

    return Response(
        content=result.content,
        media_type=response_mime_type,
        headers=headers,
    )


@router.post(
    "/material_publication/upload-request",
)
def api_material_publication_upload_request(
    request: MaterialPublicationUploadRequest,
    current_user: User = Depends(
        get_current_user,
    ),
    db: Session = Depends(
        get_db,
    ),
):
    subject = get_subject_for_publication(
        db,
        request.subject_id,
    )

    if subject is None:
        raise HTTPException(
            status_code=404,
            detail="Materia non trovata.",
        )

    try:
        validate_publication_material_size(
            request.size,
        )

        validate_publication_material_mime_type(
            request.mime_type,
        )

    except ValueError as exception:
        raise HTTPException(
            status_code=400,
            detail=str(
                exception,
            ),
        )

    duplicate = find_duplicate_candidate(
        db,
        subject_id=request.subject_id,
        original_name=(
            request.original_name
        ),
        size=request.size,
        file_hash=(
            request.file_hash
            .lower()
        ),
    )

    stored_name = (
        generate_publication_stored_name(
            current_user.id,
            request.original_name,
        )
    )

    return {
        "allowed":
            True,
        "pathname":
            stored_name,
        "max_file_size":
            MAX_PUBLIC_MATERIAL_SIZE,
        "possible_duplicate":
            duplicate is not None,
        "possible_duplicate_material_id":
            (
                duplicate.id
                if duplicate is not None
                else None
            ),
    }


@router.post(
    "/material_publication/complete",
    response_model=
        MaterialPublicationRequestResponse,
)
async def api_material_publication_complete(
    request:
        MaterialPublicationCompleteRequest,
    current_user: User = Depends(
        get_current_user,
    ),
    db: Session = Depends(
        get_db,
    ),
):
    try:
        validate_publication_storage_path(
            user_id=current_user.id,
            stored_name=request.stored_name,
        )

        validate_publication_material_size(
            request.size,
        )

        validate_publication_material_mime_type(
            request.mime_type,
        )

        await verify_uploaded_blob(
            stored_name=(
                request.stored_name
            ),
            expected_size=(
                request.size
            ),
            expected_mime_type=(
                request.mime_type
            ),
        )

        publication_request = (
            create_material_publication_request(
                db,
                current_user=current_user,
                data=request,
            )
        )

        return publication_request

    except PermissionError as exception:
        raise HTTPException(
            status_code=403,
            detail=str(
                exception,
            ),
        )

    except ValueError as exception:
        message = str(
            exception,
        )

        status_code = (
            404
            if message ==
            "Materia non trovata."
            else 400
        )

        raise HTTPException(
            status_code=status_code,
            detail=message,
        )

    except IntegrityError:
        db.rollback()

        raise HTTPException(
            status_code=409,
            detail=(
                "Impossibile creare la richiesta "
                "di pubblicazione."
            ),
        )


@router.get(
    "/material_publication/me",
    response_model=list[
        MaterialPublicationRequestResponse
    ],
)
def api_my_material_publication_requests(
    current_user: User = Depends(
        get_current_user,
    ),
    db: Session = Depends(
        get_db,
    ),
):
    return get_user_publication_requests(
        db,
        current_user.id,
    )


@router.get(
    "/material_publication/me/{request_id}",
    response_model=
        MaterialPublicationRequestResponse,
)
def api_my_material_publication_request(
    request_id: int,
    current_user: User = Depends(
        get_current_user,
    ),
    db: Session = Depends(
        get_db,
    ),
):
    publication_request = (
        get_publication_request_by_id(
            db,
            request_id,
        )
    )

    if publication_request is None:
        raise HTTPException(
            status_code=404,
            detail="Richiesta non trovata.",
        )

    if (
        publication_request.user_id !=
        current_user.id
    ):
        raise HTTPException(
            status_code=404,
            detail="Richiesta non trovata.",
        )

    return publication_request


@router.get(
    "/admin/material_publications",
    response_model=list[
        MaterialPublicationRequestAdminResponse
    ],
)
def api_admin_material_publications(
    status: str | None = None,
    current_user: User = Depends(
        get_admin_user,
    ),
    db: Session = Depends(
        get_db,
    ),
):
    if (
        status is not None
        and status not in [
            "pending",
            "approved",
            "rejected",
        ]
    ):
        raise HTTPException(
            status_code=400,
            detail=(
                "Stato della richiesta non valido."
            ),
        )

    return get_publication_requests(
        db,
        status=status,
    )


@router.get(
    "/admin/material_publications/pending",
    response_model=list[
        MaterialPublicationRequestAdminResponse
    ],
)
def api_admin_pending_material_publications(
    current_user: User = Depends(
        get_admin_user,
    ),
    db: Session = Depends(
        get_db,
    ),
):
    return get_pending_publication_requests(
        db,
    )


@router.get(
    "/admin/material_publications/{request_id}",
    response_model=
        MaterialPublicationRequestAdminResponse,
)
def api_admin_material_publication_request(
    request_id: int,
    current_user: User = Depends(
        get_admin_user,
    ),
    db: Session = Depends(
        get_db,
    ),
):
    publication_request = (
        get_publication_request_by_id(
            db,
            request_id,
        )
    )

    if publication_request is None:
        raise HTTPException(
            status_code=404,
            detail="Richiesta non trovata.",
        )

    return publication_request


@router.get(
    "/admin/material_publications/{request_id}/file",
)
async def api_admin_material_publication_file(
    request_id: int,
    current_user: User = Depends(
        get_admin_user,
    ),
    db: Session = Depends(
        get_db,
    ),
):
    publication_request = (
        get_publication_request_by_id(
            db,
            request_id,
        )
    )

    if publication_request is None:
        raise HTTPException(
            status_code=404,
            detail="Richiesta non trovata.",
        )

    return await stream_private_blob(
        stored_name=(
            publication_request.stored_name
        ),
        original_name=(
            publication_request.original_name
        ),
        mime_type=(
            publication_request.mime_type
        ),
    )


@router.get(
    "/admin/material_publications/{request_id}/possible-duplicate",
    response_model=
        PublicMaterialAdminResponse,
)
def api_admin_possible_duplicate_material(
    request_id: int,
    current_user: User = Depends(
        get_admin_user,
    ),
    db: Session = Depends(
        get_db,
    ),
):
    publication_request = (
        get_publication_request_by_id(
            db,
            request_id,
        )
    )

    if publication_request is None:
        raise HTTPException(
            status_code=404,
            detail="Richiesta non trovata.",
        )

    material_id = (
        publication_request
        .possible_duplicate_material_id
    )

    if material_id is None:
        raise HTTPException(
            status_code=404,
            detail="Nessun possibile duplicato.",
        )

    material = get_public_material_by_id(
        db,
        material_id,
    )

    if material is None:
        raise HTTPException(
            status_code=404,
            detail=(
                "Materiale duplicato non trovato."
            ),
        )

    return material


@router.get(
    "/admin/material_publications/{request_id}/possible-duplicate/file",
)
async def api_admin_possible_duplicate_material_file(
    request_id: int,
    current_user: User = Depends(
        get_admin_user,
    ),
    db: Session = Depends(
        get_db,
    ),
):
    publication_request = (
        get_publication_request_by_id(
            db,
            request_id,
        )
    )

    if publication_request is None:
        raise HTTPException(
            status_code=404,
            detail="Richiesta non trovata.",
        )

    material_id = (
        publication_request
        .possible_duplicate_material_id
    )

    if material_id is None:
        raise HTTPException(
            status_code=404,
            detail="Nessun possibile duplicato.",
        )

    material = get_public_material_by_id(
        db,
        material_id,
    )

    if material is None:
        raise HTTPException(
            status_code=404,
            detail=(
                "Materiale duplicato non trovato."
            ),
        )

    return await stream_private_blob(
        stored_name=(
            material.stored_name
        ),
        original_name=(
            material.original_name
        ),
        mime_type=(
            material.mime_type
        ),
    )


@router.patch(
    "/admin/material_publications/{request_id}/duplicate",
    response_model=
        MaterialPublicationRequestAdminResponse,
)
def api_admin_review_material_duplicate(
    request_id: int,
    request:
        MaterialDuplicateReviewRequest,
    current_user: User = Depends(
        get_admin_user,
    ),
    db: Session = Depends(
        get_db,
    ),
):
    publication_request = (
        get_publication_request_by_id(
            db,
            request_id,
        )
    )

    if publication_request is None:
        raise HTTPException(
            status_code=404,
            detail="Richiesta non trovata.",
        )

    try:
        return review_material_duplicate(
            db,
            publication_request=(
                publication_request
            ),
            current_admin=current_user,
            data=request,
        )

    except ValueError as exception:
        raise HTTPException(
            status_code=400,
            detail=str(
                exception,
            ),
        )


@router.post(
    "/admin/material_publications/{request_id}/approve",
    response_model=
        PublicMaterialAdminResponse,
)
def api_admin_approve_material_publication(
    request_id: int,
    request:
        MaterialPublicationApproveRequest,
    current_user: User = Depends(
        get_admin_user,
    ),
    db: Session = Depends(
        get_db,
    ),
):
    publication_request = (
        get_publication_request_by_id(
            db,
            request_id,
        )
    )

    if publication_request is None:
        raise HTTPException(
            status_code=404,
            detail="Richiesta non trovata.",
        )

    try:
        return (
            approve_material_publication_request(
                db,
                publication_request=(
                    publication_request
                ),
                current_admin=current_user,
                data=request,
            )
        )

    except ValueError as exception:
        message = str(
            exception,
        )

        status_code = (
            409
            if message in [
                (
                    "La richiesta ha già generato "
                    "un materiale pubblico."
                ),
                (
                    "Il materiale è stato confermato "
                    "come duplicato."
                ),
            ]
            else 400
        )

        raise HTTPException(
            status_code=status_code,
            detail=message,
        )

    except IntegrityError:
        db.rollback()

        raise HTTPException(
            status_code=409,
            detail=(
                "Impossibile pubblicare "
                "il materiale."
            ),
        )


@router.post(
    "/admin/material_publications/{request_id}/reject",
    response_model=
        MaterialPublicationRequestAdminResponse,
)
def api_admin_reject_material_publication(
    request_id: int,
    request:
        MaterialPublicationRejectRequest,
    current_user: User = Depends(
        get_admin_user,
    ),
    db: Session = Depends(
        get_db,
    ),
):
    publication_request = (
        get_publication_request_by_id(
            db,
            request_id,
        )
    )

    if publication_request is None:
        raise HTTPException(
            status_code=404,
            detail="Richiesta non trovata.",
        )

    try:
        return (
            reject_material_publication_request(
                db,
                publication_request=(
                    publication_request
                ),
                current_admin=current_user,
                data=request,
            )
        )

    except ValueError as exception:
        raise HTTPException(
            status_code=400,
            detail=str(
                exception,
            ),
        )
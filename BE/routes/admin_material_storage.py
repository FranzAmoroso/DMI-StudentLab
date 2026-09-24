import json
from pydantic import BaseModel
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from core.database import get_db
from core.security import get_admin_user
from models.user import User
from models.public_material import PublicMaterial
from services.drive_material_storage import copy_public_material, drive_status, delete_public_drive_copy, preview_public_material, public_drive_response, _access_token, _session, mark_retry
from services.drive_material_catalog import clean_path, verify_under_root, FOLDER_MIME
from services.admin_material_storage import record_storage_event, utc_now
from schemas.admin_material_storage import (
    AdminMaterialStorageCleanupRequest,
    AdminMovePublicFolderRequest,
    AdminPlacePublicMaterialRequest,
    AdminPublicVisibilityRequest,
    AdminPublicAudienceRequest,
    AdminMaterialStorageDeleteBlobRequest,
    AdminMaterialStorageRenameRequest,
    AdminMaterialStorageRetireRequest,
)
from services.admin_material_storage import (
    build_storage_snapshot,
    cleanup_dry_run,
    delete_record_blob,
    execute_cleanup,
    get_admin_material_items,
    rename_material,
    retire_material,
    move_public_folder,
    place_public_file,
    set_public_visibility,
    set_public_audience,
)

router = APIRouter(
    prefix="/admin/material-storage",
    tags=["admin-material-storage"],
)


class DrivePlacementRequest(BaseModel):
    path: list[str] | None = None
    allow_duplicate: bool = False


@router.post('/public/{material_id}/drive-preview')
async def admin_preview_public_drive(material_id: int, request: DrivePlacementRequest,
    current_user: User = Depends(get_admin_user), db: Session = Depends(get_db)):
    material = db.query(PublicMaterial).filter(PublicMaterial.id == material_id).first()
    if material is None or material.status == 'removed':
        raise HTTPException(404, 'Materiale non disponibile.')
    return await preview_public_material(material, request.path)


@router.get('/drive/file/{file_id}/preview')
async def admin_preview_file_in_drive(file_id: str,
    current_user: User = Depends(get_admin_user)):
    await drive_status()
    async with await _session() as client:
        headers = {'Authorization': f'Bearer {await _access_token(client)}'}
        file = await verify_under_root(client, headers, file_id)
        if int(file.get('size') or 0) > 20 * 1024 * 1024:
            raise HTTPException(413, 'Anteprima limitata a file di 20 MB.')
        mime = file.get('mimeType')
        if mime == FOLDER_MIME or not isinstance(mime, str):
            raise HTTPException(400, 'Questa cartella non ha un’anteprima file.')
        # Keep opaque or active content as an attachment.
        inline = mime in {'application/pdf', 'image/png', 'image/jpeg',
            'image/webp', 'text/plain'}
        return await public_drive_response(drive_file_id=file_id,
            original_name=file.get('name', 'materiale'), mime_type=mime,
            inline=inline)


@router.get('/drive/status')
async def admin_drive_status(
    current_user: User = Depends(get_admin_user),
):
    return await drive_status()


@router.post('/public/{material_id}/drive-copy')
async def admin_copy_public_to_drive(
    material_id: int,
    placement: DrivePlacementRequest | None = None,
    current_user: User = Depends(get_admin_user),
    db: Session = Depends(get_db),
):
    material = db.query(PublicMaterial).filter(PublicMaterial.id == material_id).first()
    if material is None:
        raise HTTPException(status_code=404, detail='Materiale non trovato.')
    if material.drive_file_id:
        return {'id': material.id, 'copied': True}
    if placement is not None:
        if placement.path is not None:
            material.drive_path_json = json.dumps(clean_path(placement.path), ensure_ascii=False)
        material.drive_allow_duplicate = placement.allow_duplicate
        material.drive_retry_after = None
        db.commit()
    try:
        drive_id = await copy_public_material(material)
    except Exception as exc:
        db.rollback()
        if material.drive_activation_pending:
            state = mark_retry(material, exc)
            record_storage_event(db, source='public', material_id=material.id,
                action='drive_copy_pending', actor_id=current_user.id,
                details={'state': state}, commit=True)
        raise
    material.drive_file_id = drive_id
    material.drive_copied_at = utc_now()
    material.drive_retry_after = None
    if material.drive_activation_pending:
        material.drive_activation_pending = False
        material.status = 'published'
        material.is_visible = True
        material.visibility_state = 'visible'
        material.version = (material.version or 1) + 1
        material.updated_at = utc_now()
    record_storage_event(db, source='public', material_id=material.id,
        action='drive_copied', actor_id=current_user.id,
        blob_path=material.stored_name, original_name=material.original_name,
        size=material.size, details={'drive_file_id': drive_id}, commit=False)
    try:
        db.commit()
    except Exception:
        db.rollback()
        raise
    return {'id': material.id, 'copied': True}


@router.delete('/public/{material_id}/drive-copy')
async def admin_delete_public_drive_copy(
    material_id: int, confirmation: str = Query(...),
    current_user: User = Depends(get_admin_user),
    db: Session = Depends(get_db),
):
    if confirmation != 'ELIMINA':
        raise HTTPException(status_code=400, detail='Conferma ELIMINA richiesta.')
    material = db.query(PublicMaterial).filter(PublicMaterial.id == material_id).first()
    if material is None or not material.drive_file_id:
        raise HTTPException(status_code=404, detail='Copia Drive non trovata.')
    previous_id = material.drive_file_id
    if material.status != 'removed':
        raise HTTPException(status_code=409,
            detail='Ritira prima il materiale: Drive è la copia principale.')
    await delete_public_drive_copy(material)
    material.drive_file_id = None
    material.drive_copied_at = None
    record_storage_event(db, source='public', material_id=material.id,
        action='drive_deleted', actor_id=current_user.id,
        blob_path=material.stored_name, original_name=material.original_name,
        size=material.size, details={'drive_file_id': previous_id}, commit=False)
    try:
        db.commit()
    except Exception:
        db.rollback()
        raise
    return {'id': material.id, 'copied': False}


@router.get("/overview")
async def admin_material_storage_overview(
    current_user: User = Depends(get_admin_user),
    db: Session = Depends(get_db),
):
    return await build_storage_snapshot(db)


@router.get("/items")
def admin_material_storage_items(
    source: str | None = Query(default=None),
    status_filter: str | None = Query(default=None, alias="status"),
    current_user: User = Depends(get_admin_user),
    db: Session = Depends(get_db),
):
    try:
        return get_admin_material_items(
            db,
            source=source,
            status=status_filter,
        )
    except ValueError as exception:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(exception),
        )


@router.patch("/{source}/{material_id}/display-name")
def admin_material_storage_rename(
    source: str,
    material_id: int,
    request: AdminMaterialStorageRenameRequest,
    current_user: User = Depends(get_admin_user),
    db: Session = Depends(get_db),
):
    try:
        return rename_material(
            db,
            source=source,
            material_id=material_id,
            actor=current_user,
            display_name=request.display_name,
        )
    except ValueError as exception:
        message = str(exception)
        raise HTTPException(
            status_code=(
                status.HTTP_404_NOT_FOUND
                if message == "Materiale non trovato."
                else status.HTTP_400_BAD_REQUEST
            ),
            detail=message,
        )


@router.post("/{source}/{material_id}/retire")
def admin_material_storage_retire(
    source: str,
    material_id: int,
    request: AdminMaterialStorageRetireRequest,
    current_user: User = Depends(get_admin_user),
    db: Session = Depends(get_db),
):
    try:
        return retire_material(
            db,
            source=source,
            material_id=material_id,
            actor=current_user,
            reason=request.reason,
        )
    except ValueError as exception:
        message = str(exception)
        raise HTTPException(
            status_code=(
                status.HTTP_404_NOT_FOUND
                if message == "Materiale non trovato."
                else status.HTTP_400_BAD_REQUEST
            ),
            detail=message,
        )


@router.post("/{source}/{material_id}/delete-blob")
async def admin_material_storage_delete_blob(
    source: str,
    material_id: int,
    request: AdminMaterialStorageDeleteBlobRequest,
    current_user: User = Depends(get_admin_user),
    db: Session = Depends(get_db),
):
    try:
        return await delete_record_blob(
            db,
            source=source,
            material_id=material_id,
            actor=current_user,
            reason="Eliminazione file confermata dall'amministrazione.",
        )
    except ValueError as exception:
        message = str(exception)
        raise HTTPException(
            status_code=(
                status.HTTP_404_NOT_FOUND
                if message == "Materiale non trovato."
                else status.HTTP_400_BAD_REQUEST
            ),
            detail=message,
        )


@router.patch('/public/{material_id}/visibility')
def admin_public_visibility(
    material_id: int, request: AdminPublicVisibilityRequest,
    current_user: User = Depends(get_admin_user),
    db: Session = Depends(get_db),
):
    try:
        return set_public_visibility(db, material_id=material_id,
            state=request.state, actor=current_user)
    except ValueError as exception:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(exception))


@router.patch('/public/{material_id}/audience')
def admin_public_audience(
    material_id: int, request: AdminPublicAudienceRequest,
    current_user: User = Depends(get_admin_user),
    db: Session = Depends(get_db),
):
    try:
        return set_public_audience(db, material_id=material_id,
            audience_type=request.audience_type,
            audience_id=request.audience_id, actor=current_user)
    except ValueError as exception:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(exception))


@router.patch('/public/{material_id}/placement')
def admin_place_public_material(
    material_id: int,
    request: AdminPlacePublicMaterialRequest,
    current_user: User = Depends(get_admin_user),
    db: Session = Depends(get_db),
):
    try:
        return place_public_file(db, material_id=material_id,
            subject_id=request.subject_id, path=request.path_segments,
            actor=current_user)
    except ValueError as exception:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(exception))


@router.post('/folders/move')
def admin_move_public_folder(
    request: AdminMovePublicFolderRequest,
    current_user: User = Depends(get_admin_user),
    db: Session = Depends(get_db),
):
    try:
        return move_public_folder(db, source_subject_id=request.source_subject_id,
            source_path=request.source_path,
            destination_subject_id=request.destination_subject_id,
            destination_path=request.destination_path, actor=current_user)
    except ValueError as exception:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(exception))


@router.get("/cleanup/dry-run")
async def admin_material_storage_cleanup_dry_run(
    current_user: User = Depends(get_admin_user),
    db: Session = Depends(get_db),
):
    return await cleanup_dry_run(db)


@router.post("/cleanup/execute")
async def admin_material_storage_cleanup_execute(
    request: AdminMaterialStorageCleanupRequest,
    current_user: User = Depends(get_admin_user),
    db: Session = Depends(get_db),
):
    return await execute_cleanup(
        db,
        actor=current_user,
        rejected_publications=request.rejected_publications,
        removed_materials=request.removed_materials,
        orphan_blobs=request.orphan_blobs,
    )

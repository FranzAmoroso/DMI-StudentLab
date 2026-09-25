import hashlib
import json
from datetime import datetime, timezone
import httpx
from pydantic import BaseModel
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from core.database import get_db
from core.security import get_admin_user
from models.user import User
from models.public_material import PublicMaterial
from models.subject import Subject
from models.group import StudyGroup
from services.drive_material_storage import copy_public_material, drive_status, delete_public_drive_copy, preview_public_material, public_drive_response, _access_token, _session, mark_retry
from services.drive_material_catalog import clean_path, verify_under_root, FOLDER_MIME
from core.config import settings
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


class DriveImportRequest(BaseModel):
    file_id: str
    subject_id: int
    audience_type: str = 'public'
    audience_id: int | None = None


@router.get('/drive/import-options')
def admin_drive_import_options(current_user: User = Depends(get_admin_user),
        db: Session = Depends(get_db)):
    """Active catalog subjects for classifying existing Drive files."""
    subjects = db.query(Subject).filter(Subject.is_active.is_(True)).order_by(
        Subject.university, Subject.department, Subject.course,
        Subject.study_year, Subject.name).all()
    return [{'id': subject.id, 'name': subject.name,
             'university': subject.university, 'department': subject.department,
             'course': subject.course, 'year': subject.study_year}
            for subject in subjects]


@router.get('/drive/tree')
async def admin_drive_tree(folder_id: str | None = None,
    page_token: str | None = Query(default=None, max_length=512),
    current_user: User = Depends(get_admin_user), db: Session = Depends(get_db)):
    # Browsing the existing catalog needs read access; a writable root is
    # required only when creating a new Drive copy.
    folder_id = folder_id or settings.drive_folder_id
    async with await _session() as client:
        headers = {'Authorization': f'Bearer {await _access_token(client)}'}
        if folder_id != settings.drive_folder_id:
            folder = await verify_under_root(client, headers, folder_id)
            if folder.get('mimeType') != FOLDER_MIME:
                raise HTTPException(400, 'La destinazione non è una cartella.')
        try:
            response = await client.get('https://www.googleapis.com/drive/v3/files',
                headers=headers, params={'q': f"'{folder_id}' in parents and trashed = false",
                    'pageSize': 100, **({'pageToken': page_token} if page_token else {}),
                    'fields': 'nextPageToken,files(id,name,mimeType,size,parents)',
                    'supportsAllDrives': 'true', 'includeItemsFromAllDrives': 'true'})
            response.raise_for_status()
            payload = response.json()
            children = payload.get('files') or []
        except (httpx.HTTPError, ValueError) as exc:
            raise HTTPException(503, 'Impossibile leggere questa cartella Drive.') from exc
        ids = [e['id'] for e in children if e.get('mimeType') != FOLDER_MIME]
        indexed = set()
        if ids:
            indexed = {row[0] for row in db.query(PublicMaterial.drive_file_id)
                .filter(PublicMaterial.drive_file_id.in_(ids), PublicMaterial.status != 'removed').all()}
        return {'folder_id': folder_id, 'next_page_token': payload.get('nextPageToken'), 'items': [
            {'id': e['id'], 'name': e.get('name', ''), 'mime_type': e.get('mimeType'),
             'size': int(e.get('size') or 0), 'indexed': e['id'] in indexed}
            for e in sorted(children, key=lambda e: (e.get('mimeType') != FOLDER_MIME,
                e.get('name', '').casefold()))]}


@router.post('/drive/import')
async def admin_import_drive_file(request: DriveImportRequest,
    current_user: User = Depends(get_admin_user), db: Session = Depends(get_db)):
    """Index a Drive file only after its course and audience are chosen by an admin."""
    if request.audience_type not in {'public', 'course', 'subject', 'group', 'user'}:
        raise HTTPException(400, 'Destinatari non validi.')
    if request.audience_type in {'group', 'user'} and (request.audience_id is None or request.audience_id <= 0):
        raise HTTPException(400, 'Indica l’ID dello studente o del gruppo.')
    subject = db.query(Subject).filter(Subject.id == request.subject_id).first()
    if not subject or not subject.is_active:
        raise HTTPException(404, 'Materia del catalogo non trovata.')
    if request.audience_type == 'user' and not db.query(User.id).filter(
            User.id == request.audience_id, User.is_active.is_(True)).first():
        raise HTTPException(400, 'Studente destinatario non trovato.')
    if request.audience_type == 'group' and not db.query(StudyGroup.id).filter(
            StudyGroup.id == request.audience_id, StudyGroup.subject_id == subject.id,
            StudyGroup.status == 'active').first():
        raise HTTPException(400, 'Gruppo destinatario non valido per questa materia.')
    # Indexing an existing file reads Drive and writes only to our catalog.
    async with await _session() as client:
        headers = {'Authorization': f'Bearer {await _access_token(client)}'}
        entry = await verify_under_root(client, headers, request.file_id)
        mime = entry.get('mimeType', '')
        size = int(entry.get('size') or 0)
        if mime == FOLDER_MIME or mime.startswith('application/vnd.google-apps.'):
            raise HTTPException(400, 'Esporta il documento Google come file prima di importarlo.')
        if not 0 < size <= 20 * 1024 * 1024:
            raise HTTPException(413, 'Importazione diretta disponibile per file fino a 20 MB.')
        if db.query(PublicMaterial.id).filter(PublicMaterial.drive_file_id == request.file_id,
                PublicMaterial.status != 'removed').first():
            raise HTTPException(409, 'File già presente nel catalogo StudentLab.')
        digest = hashlib.sha256()
        count = 0
        try:
            async with client.stream('GET', f'https://www.googleapis.com/drive/v3/files/{request.file_id}',
                    headers=headers, params={'alt': 'media', 'supportsAllDrives': 'true'}) as response:
                response.raise_for_status()
                async for chunk in response.aiter_bytes():
                    count += len(chunk)
                    if count > 20 * 1024 * 1024:
                        raise HTTPException(413, 'File troppo grande per l’importazione diretta.')
                    digest.update(chunk)
        except httpx.HTTPError as exc:
            raise HTTPException(503, 'Impossibile leggere il file da Google Drive.') from exc
        if count != size:
            raise HTTPException(503, 'La dimensione del file Drive è cambiata. Riprova.')
        # Retain the folder hierarchy as catalog metadata; never move Drive bytes.
        folders = []
        parent_ids = entry.get('parents') or []
        for _ in range(20):
            if settings.drive_folder_id in parent_ids:
                break
            if len(parent_ids) != 1:
                raise HTTPException(400, 'Percorso del file Drive ambiguo.')
            parent = await verify_under_root(client, headers, parent_ids[0])
            if parent.get('mimeType') != FOLDER_MIME:
                raise HTTPException(400, 'Percorso del file Drive non valido.')
            folders.insert(0, parent.get('name', ''))
            parent_ids = parent.get('parents') or []
        else:
            raise HTTPException(400, 'Percorso Drive troppo profondo.')
        # A matching academic prefix is already represented by the subject card.
        expected = [subject.university, subject.department, subject.course, subject.name]
        if len(folders) >= 4 and all(str(a).casefold() == str(b).casefold()
                for a, b in zip(folders[:4], expected)):
            folders = folders[4:]
        folders = clean_path(folders)
        name = str(entry.get('name') or 'materiale')[:255]
        now = datetime.now(timezone.utc)
        row = PublicMaterial(subject_id=subject.id, uploaded_by=None,
            university=subject.university, university_code=subject.university_code or '',
            department=subject.department, department_code=subject.department_code or '',
            course=subject.course, course_code=subject.course_code or '',
            title=name[:250], original_name=name,
            stored_name=f'drive-import/{request.file_id}', file_path=f'drive://{request.file_id}',
            catalog_path_json=json.dumps(folders, ensure_ascii=False),
            mime_type=mime or 'application/octet-stream', size=size,
            file_hash=digest.hexdigest(), drive_file_id=request.file_id,
            drive_copied_at=now, audience_type=request.audience_type,
            audience_id=request.audience_id if request.audience_type in {'group', 'user'} else None,
            status='published', is_visible=True, visibility_state='visible',
            approved_by=current_user.id, approved_at=now, contributor_mode='anonymous')
        db.add(row)
        try:
            db.commit()
            db.refresh(row)
        except Exception:
            db.rollback()
            raise HTTPException(409, 'Impossibile registrare il file; verifica che non sia già presente.')
        return {'id': row.id, 'drive_file_id': request.file_id}


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
    # Previews do not require permission to add files to the root.
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

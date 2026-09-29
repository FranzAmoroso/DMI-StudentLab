"""Admin MEGA source, durable copies and catalog drafts backed by Drive."""
from types import SimpleNamespace
from fastapi import APIRouter, Depends, HTTPException, Query, Response
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session
from core.config import settings
from core.database import get_db
from core.security import get_admin_user
from models.user import User
from models.public_material import PublicMaterial
from services import mega_storage as gateway
from services.material_catalog_draft import _validate, stage_drive_import

router = APIRouter(prefix='/admin/material-storage', tags=['admin-mega-storage'])

class ConnectRequest(BaseModel):
    email: str | None = Field(default=None, max_length=320)
    password: str | None = Field(default=None, max_length=4096)
    second_factor_code: str | None = Field(default=None, max_length=12)
    root_folder: str = Field(default='/StudentLab', max_length=1000)
    public_url: str | None = Field(default=None, max_length=2000)

class CopyRequest(BaseModel):
    file_id: str = Field(pattern=r'^[\w-]{1,128}$')
    source_id: str | None = Field(default=None, max_length=64)
    path_segments: list[str] = Field(default_factory=list, max_length=12)

class ImportRequest(CopyRequest):
    subject_id: int = Field(gt=0)
    audience_type: str = 'course'
    audience_id: int | None = Field(default=None, gt=0)
    allow_duplicate: bool = False

@router.get('/mega/status')
async def mega_status(actor: User = Depends(get_admin_user)):
    return await gateway.worker('/status')

@router.post('/mega/connect')
async def mega_connect(request: ConnectRequest, actor: User = Depends(get_admin_user)):
    return await gateway.worker('/connect', method='POST', data=request.model_dump())

@router.post('/mega/verify')
async def mega_verify(actor: User = Depends(get_admin_user)):
    return await gateway.worker('/verify', method='POST')

@router.post('/mega/disconnect')
async def mega_disconnect(actor: User = Depends(get_admin_user)):
    return await gateway.worker('/disconnect', method='POST')

@router.get('/mega/tree')
async def mega_tree(folder_id: str | None = Query(default=None, pattern=r'^[\w-]{1,128}$'),
        page_token: str | None = Query(default=None, max_length=512),
        actor: User = Depends(get_admin_user), db: Session = Depends(get_db)):
    payload = await gateway.worker('/tree', params={key: val for key, val in
        {'folder_id': folder_id, 'page_token': page_token}.items() if val is not None})
    ids = [item.get('copied_drive_file_id') for item in payload['items'] if item.get('copied_drive_file_id')]
    indexed = {row[0] for row in db.query(PublicMaterial.drive_file_id).filter(
        PublicMaterial.drive_file_id.in_(ids), PublicMaterial.status != 'removed').all()} if ids else set()
    for item in payload['items']:
        item['indexed'] = item.get('copied_drive_file_id') in indexed
    return payload

@router.get('/mega/file/{file_id}/preview')
async def mega_preview(file_id: str, actor: User = Depends(get_admin_user)):
    import re
    if not re.fullmatch(r'[\w-]{1,128}', file_id):
        raise HTTPException(400, 'File non valido.')
    content, mime = await gateway.preview_bytes(file_id)
    return Response(content, media_type=mime, headers={
        'Cache-Control': 'no-store', 'X-Content-Type-Options': 'nosniff', 'Content-Disposition': 'attachment'})

@router.post('/mega/copy-drive', status_code=202)
async def mega_copy(request: CopyRequest, actor: User = Depends(get_admin_user)):
    return await gateway.worker('/jobs', method='POST', data={**request.model_dump(),
        'actor_id': actor.id, 'expected_drive_root': settings.drive_folder_id})

@router.get('/mega/jobs')
async def mega_jobs(actor: User = Depends(get_admin_user)):
    return await gateway.worker('/jobs', params={'actor_id': actor.id})

@router.get('/mega/jobs/{job_id}')
async def mega_job(job_id: str, actor: User = Depends(get_admin_user)):
    return await gateway.worker('/jobs/' + _job_id(job_id), params={'actor_id': actor.id})

def _job_id(value):
    import re
    if not re.fullmatch(r'[\w-]{1,64}', value):
        raise HTTPException(400, 'Copia non valida.')
    return value

@router.post('/mega/jobs/{job_id}/retry', status_code=202)
async def mega_retry(job_id: str, actor: User = Depends(get_admin_user)):
    return await gateway.worker('/jobs/' + _job_id(job_id) + '/retry', method='POST', params={'actor_id': actor.id})

@router.post('/catalog/mega-import', status_code=202)
async def mega_import(request: ImportRequest, actor: User = Depends(get_admin_user), db: Session = Depends(get_db)):
    try:
        _validate(db, material=SimpleNamespace(drive_file_id='pending-copy', subject_id=request.subject_id),
            subject_id=request.subject_id, path=request.path_segments, state='visible',
            audience=request.audience_type, audience_id=request.audience_id)
    except ValueError as exc:
        raise HTTPException(400, str(exc)) from exc
    options = {key: value for key, value in request.model_dump().items() if key not in {'file_id', 'source_id'}}
    job = await gateway.worker('/jobs', method='POST', data={
        'file_id': request.file_id, 'source_id': request.source_id,
        'path_segments': ['Importati da MEGA'], 'import_options': options,
        'actor_id': actor.id, 'expected_drive_root': settings.drive_folder_id})
    return {'queued': True, 'job_id': job['id'], 'staged': False}

@router.post('/mega/jobs/{job_id}/stage')
async def mega_stage_completed(job_id: str, actor: User = Depends(get_admin_user), db: Session = Depends(get_db)):
    """Recheck audience on completion, then use the existing Drive draft workflow."""
    job = await gateway.worker('/jobs/' + _job_id(job_id), params={'actor_id': actor.id})
    if job['state'] != 'completed' or not job.get('import_options'):
        raise HTTPException(409, 'Attendi il termine della copia prima di aggiungere alla bozza.')
    options = job['import_options']
    copied = [row for row in job['results'] if row.get('drive_file_id')]
    if len(copied) != 1:
        raise HTTPException(409, 'Importazione non valida: registra i file dalla struttura Drive.')
    file_id = copied[0]['drive_file_id']
    existing = db.query(PublicMaterial.id).filter(PublicMaterial.drive_file_id == file_id).first()
    if existing:
        return {'staged': False, 'already_published': True, 'material_id': existing[0]}
    try:
        return await stage_drive_import(db, admin_id=actor.id, file_id=file_id,
            subject_id=options['subject_id'], path=options['path_segments'],
            audience=options['audience_type'], audience_id=options.get('audience_id'),
            allow_duplicate=options.get('allow_duplicate', False))
    except (ValueError, RuntimeError) as exc:
        db.rollback()
        raise HTTPException(409 if isinstance(exc, RuntimeError) else 400, str(exc)) from exc

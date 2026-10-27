"""Caricamenti degli studenti verso MEGA, il raccoglitore momentaneo (v26).

Stesso percorso sicuro degli admin: il file va su Blob privato con un URL
firmato (niente limite di 4,5 MB di Vercel), poi il runner lo copia su MEGA
in /StudentLab/Caricamenti studenti/studente-<id>/ e verifica l'impronta
SHA-256. Gli admin lo vedono nell'albero MEGA del catalogo e decidono dove
copiarlo su Drive.

Si attiva solo con STUDENTLAB_STUDENT_MEGA_UPLOADS=1 (oltre alla
configurazione MEGA del runner).
"""
import os
import re
from datetime import datetime, timedelta
from uuid import uuid4

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field, field_validator
from sqlalchemy.orm import Session

from core.database import get_db
from core.security import get_admin_user, get_current_user, require_authenticated_user
from models.temporary_transfer import TemporaryTransfer as Job
from models.user import User
from routes.temporary_transfers import Prepare, view
from services.diagnostics import user_error

router = APIRouter(tags=['student-temporary-transfers'])

MAX_BYTES = 50 * 1024 * 1024
MAX_ACTIVE = 5
MAX_PER_DAY = 30
EXTENSIONS = {'pdf', 'txt', 'md', 'zip', 'docx', 'pptx', 'xlsx', 'png', 'jpg', 'jpeg'}
STUDENT_ROOT = 'Caricamenti studenti'


def _enabled():
    return (os.getenv('STUDENTLAB_STUDENT_MEGA_UPLOADS') == '1'
            and os.getenv('STUDENTLAB_TRANSFER_MEGA_ENABLED') == '1'
            and bool(os.getenv('STUDENTLAB_TRANSFER_RUNNER_TOKEN', '').strip()))


def _student(user: User = Depends(get_current_user)):
    return require_authenticated_user(user)


class StudentPrepare(BaseModel):
    filename: str = Field(min_length=1, max_length=180)
    mime_type: str = Field(min_length=1, max_length=150)
    size: int = Field(gt=0, le=MAX_BYTES)
    sha256: str = Field(pattern=r'^[a-f0-9]{64}$')
    folder: str | None = Field(default=None, max_length=80)

    @field_validator('folder')
    @classmethod
    def safe_folder(cls, value):
        if value is None or not value.strip():
            return None
        value = value.strip()
        if value in ('.', '..') or re.search(r'[/\\\x00-\x1f]', value):
            raise ValueError('Nome della cartella non valido.')
        return value


def _own(db, user, job_id):
    job = db.query(Job).filter(Job.id == job_id, Job.actor_id == user.id).with_for_update().first()
    if not job:
        raise HTTPException(404, 'Caricamento non trovato.')
    return job


def _student_view(job):
    data = view(job)
    # Allo studente non serve sapere dove finisce il file nel deposito.
    data.pop('result_id', None)
    data['path_segments'] = data.get('path_segments', [])[2:]
    return data


@router.get('/student/temporary-transfers/status')
def student_upload_status(user: User = Depends(_student)):
    return {'enabled': _enabled(), 'max_bytes': MAX_BYTES, 'max_active': MAX_ACTIVE,
            'extensions': sorted(EXTENSIONS)}


@router.get('/student/temporary-transfers')
def student_jobs(user: User = Depends(_student), db: Session = Depends(get_db)):
    rows = db.query(Job).filter(Job.actor_id == user.id, Job.destination == 'mega').order_by(
        Job.created_at.desc()).limit(200).all()
    return [_student_view(j) for j in rows
            if (j.path_segments or [None])[0] == STUDENT_ROOT][:50]


@router.post('/student/temporary-transfers/prepare', status_code=201)
def student_prepare(body: StudentPrepare, user: User = Depends(_student), db: Session = Depends(get_db)):
    if not _enabled():
        raise user_error('UPL-01', 409, area='upload', technical={'step': 'prepare'}, actor_id=user.id)
    extension = body.filename.rsplit('.', 1)[-1].lower() if '.' in body.filename else ''
    if extension not in EXTENSIONS:
        raise user_error('UPL-03', 400, area='upload',
                         technical={'step': 'prepare', 'extension': extension[:10]}, actor_id=user.id)
    # Riusa i controlli di nome e tipo degli admin.
    try:
        checked = Prepare(filename=body.filename, mime_type=body.mime_type, size=body.size,
                          sha256=body.sha256, destination='mega',
                          path_segments=[STUDENT_ROOT, f'studente-{user.id}',
                                         *([body.folder] if body.folder else [])])
    except ValueError as exc:
        raise HTTPException(400, 'Nome o tipo di file non valido. Rinomina il file e riprova.') from exc
    active = db.query(Job).filter(Job.actor_id == user.id,
        Job.state.in_(['uploading', 'pending', 'running'])).count()
    if active >= MAX_ACTIVE:
        raise HTTPException(429, 'Hai già alcuni file in attesa. Aspetta che vengano copiati e riprova.')
    today = db.query(Job).filter(Job.actor_id == user.id,
        Job.created_at >= datetime.utcnow() - timedelta(days=1)).count()
    if today >= MAX_PER_DAY:
        raise user_error('UPL-02', 429, area='upload', technical={'step': 'prepare', 'today': today},
                         actor_id=user.id)
    job_id = str(uuid4())
    job = Job(id=job_id, actor_id=user.id, blob_path=f'temporary-transfers/{user.id}/{job_id}/file',
              **checked.model_dump())
    db.add(job)
    db.commit()
    return {**_student_view(job), 'pathname': job.blob_path}


@router.post('/student/temporary-transfers/{job_id}/authorize')
def student_authorize(job_id: str, user: User = Depends(_student), db: Session = Depends(get_db)):
    job = _own(db, user, job_id)
    if not _enabled():
        raise HTTPException(409, 'I caricamenti non sono attivi in questo momento.')
    if job.state != 'uploading' or job.expires_at <= datetime.utcnow():
        raise HTTPException(409, 'Caricamento scaduto o già concluso. Riprova dall’inizio.')
    job.upload_until = datetime.utcnow() + timedelta(minutes=20)
    db.commit()
    return {'allowed': True, 'pathname': job.blob_path, 'size': job.size, 'mime_type': job.mime_type}


@router.post('/student/temporary-transfers/{job_id}/ready')
def student_ready(job_id: str, user: User = Depends(_student), db: Session = Depends(get_db)):
    job = _own(db, user, job_id)
    if job.state == 'pending':
        return _student_view(job)
    if job.state != 'uploading' or job.expires_at <= datetime.utcnow():
        raise HTTPException(409, 'Caricamento non più disponibile. Riprova dall’inizio.')
    job.state = 'pending'
    db.commit()
    return _student_view(job)


@router.post('/student/temporary-transfers/{job_id}/cancel')
def student_cancel(job_id: str, user: User = Depends(_student), db: Session = Depends(get_db)):
    job = _own(db, user, job_id)
    if job.state not in ('uploading', 'pending', 'failed'):
        raise HTTPException(409, 'Il file è già in copia o è stato copiato.')
    job.state = 'cancelled'
    db.commit()
    return _student_view(job)


@router.get('/admin/temporary-transfers/students')
def admin_student_uploads(current_user: User = Depends(get_admin_user), db: Session = Depends(get_db)):
    """Caricamenti degli studenti (ultimi 200), per sapere chi ha inviato cosa."""
    rows = db.query(Job, User).join(User, User.id == Job.actor_id).filter(
        Job.path_segments.isnot(None), Job.destination == 'mega').order_by(
        Job.created_at.desc()).limit(400).all()
    result = []
    for job, owner in rows:
        segments = job.path_segments or []
        if not segments or segments[0] != STUDENT_ROOT:
            continue
        name = ' '.join(filter(None, [owner.first_name, owner.last_name])) or f'Studente {owner.id}'
        result.append({**view(job), 'student_id': owner.id, 'student_name': name})
        if len(result) >= 200:
            break
    return result

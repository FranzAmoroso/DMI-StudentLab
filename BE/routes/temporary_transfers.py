"""Admin uploads use private Blob; Actions claims durable jobs without an SSH server."""
import os, hmac, re
from datetime import datetime, timedelta
from uuid import uuid4
from fastapi import APIRouter, Depends, HTTPException, Header
from pydantic import BaseModel, Field, field_validator
from sqlalchemy.orm import Session
from sqlalchemy import or_
from core.database import get_db
from core.security import get_admin_user
from models.temporary_transfer import TemporaryTransfer as Job

router = APIRouter(prefix='/admin/temporary-transfers', tags=['admin-temporary-transfers'])

def token():
    return os.getenv('STUDENTLAB_TRANSFER_RUNNER_TOKEN', '').strip()

def runner(authorization: str = Header(default='')):
    if not token() or not hmac.compare_digest(authorization, 'Bearer '+token()):
        raise HTTPException(403, 'Operazione non autorizzata.')

def view(j):
    return {k: getattr(j, k) for k in ('id','filename','size','destination','path_segments','state',
        'attempts','result_id','error','cleaned','created_at','expires_at')}

def own(db, actor, job_id):
    j = db.query(Job).filter(Job.id == job_id, Job.actor_id == actor.id).with_for_update().first()
    if not j: raise HTTPException(404, 'Trasferimento non disponibile.')
    return j

class Prepare(BaseModel):
    filename: str = Field(min_length=1, max_length=180)
    mime_type: str = Field(min_length=1, max_length=150)
    size: int = Field(gt=0, le=50*1024*1024)
    sha256: str = Field(pattern=r'^[a-f0-9]{64}$')
    destination: str = Field(pattern=r'^(drive|mega)$')
    path_segments: list[str] = Field(default_factory=list, max_length=8)

    @field_validator('filename')
    @classmethod
    def safe_name(cls, v):
        if v != v.strip() or v in ('.','..') or re.search(r'[/\\\x00-\x1f]', v):
            raise ValueError('Nome file non valido.')
        return v

    @field_validator('path_segments')
    @classmethod
    def safe_path(cls, v):
        if any(not s.strip() or len(s)>80 or s in ('.','..') or re.search(r'[/\\\x00-\x1f]',s) for s in v):
            raise ValueError('Percorso non valido.')
        return [s.strip() for s in v]

    @field_validator('mime_type')
    @classmethod
    def safe_mime(cls, v):
        if not re.fullmatch(r'[\w.+-]+/[\w.+-]+',v): raise ValueError('Tipo file non valido.')
        return v

@router.get('')
def jobs(actor=Depends(get_admin_user), db: Session=Depends(get_db)):
    return [view(j) for j in db.query(Job).filter(Job.actor_id==actor.id).order_by(Job.created_at.desc()).limit(100)]

@router.post('/prepare', status_code=201)
def prepare(body: Prepare, actor=Depends(get_admin_user), db: Session=Depends(get_db)):
    if not token(): raise HTTPException(503, 'Configura prima il servizio di trasferimento.')
    if body.destination=='mega' and os.getenv('STUDENTLAB_TRANSFER_MEGA_ENABLED')!='1':
        raise HTTPException(409, 'Collega prima l’account MEGA per i caricamenti.')
    # v31: gli invii interrotti (pagina chiusa) non bloccano i nuovi caricamenti.
    now=datetime.utcnow()
    count=db.query(Job).filter(Job.actor_id==actor.id, or_(Job.state.in_(['pending','running']),
        (Job.state=='uploading') & or_(Job.upload_until>=now,
            (Job.upload_until.is_(None)) & (Job.created_at>=now-timedelta(minutes=30))))).count()
    if count>=20: raise HTTPException(429, 'Completa i trasferimenti in attesa prima di aggiungerne altri.')
    jid=str(uuid4())
    j=Job(id=jid, actor_id=actor.id, blob_path=f'temporary-transfers/{actor.id}/{jid}/file', **body.model_dump())
    db.add(j); db.commit()
    return {**view(j), 'pathname':j.blob_path}

@router.post('/{job_id}/authorize')
def authorize(job_id: str, actor=Depends(get_admin_user), db: Session=Depends(get_db)):
    j=own(db,actor,job_id)
    if j.state!='uploading' or j.expires_at<=datetime.utcnow(): raise HTTPException(409,'Caricamento scaduto o già concluso.')
    j.upload_until=datetime.utcnow()+timedelta(minutes=20); db.commit()
    return {'allowed':True,'pathname':j.blob_path,'size':j.size,'mime_type':j.mime_type}

@router.post('/{job_id}/ready')
def ready(job_id: str, actor=Depends(get_admin_user), db: Session=Depends(get_db)):
    j=own(db,actor,job_id)
    if j.state=='pending': return view(j)
    if j.state!='uploading' or j.expires_at<=datetime.utcnow(): raise HTTPException(409,'Caricamento non più disponibile.')
    j.state='pending'; db.commit(); return view(j)

@router.post('/{job_id}/retry')
def retry(job_id: str, actor=Depends(get_admin_user), db: Session=Depends(get_db)):
    j=own(db,actor,job_id)
    if j.state!='failed' or j.cleaned or j.expires_at<=datetime.utcnow(): raise HTTPException(409,'Il file non può essere riprovato: ricaricalo.')
    j.state='pending'; j.attempts=0; j.error=None; db.commit(); return view(j)

@router.post('/{job_id}/cancel')
def cancel(job_id: str, actor=Depends(get_admin_user), db: Session=Depends(get_db)):
    j=own(db,actor,job_id)
    if j.state not in ('uploading','pending','failed'): raise HTTPException(409,'Trasferimento già avviato o concluso.')
    j.state='cancelled'; db.commit(); return view(j)

class Claim(BaseModel):
    destinations: list[str] = Field(default_factory=lambda:['drive'], max_length=2)

@router.post('/runner/claim', dependencies=[Depends(runner)])
def claim(body: Claim, db: Session=Depends(get_db)):
    now=datetime.utcnow()
    expired=db.query(Job).filter(Job.state=='running',Job.lease_until<now).with_for_update().all()
    for j in expired:
        j.state='pending' if j.attempts<3 else 'failed'; j.error='Trasferimento interrotto; verifica o riprova.'
    db.commit()
    j=db.query(Job).filter(Job.state=='pending',Job.destination.in_(body.destinations),Job.expires_at>now).order_by(Job.created_at).with_for_update(skip_locked=True).first()
    if not j: return {'job':None}
    j.state='running'; j.attempts+=1; j.lease_id=str(uuid4()); j.lease_until=now+timedelta(minutes=30)
    db.commit()
    return {'job':{**view(j),'pathname':j.blob_path,'sha256':j.sha256,'mime_type':j.mime_type,'lease_id':j.lease_id}}

class Finish(BaseModel):
    lease_id: str
    success: bool
    result_id: str | None = Field(default=None, max_length=150)

@router.post('/runner/{job_id}/finish', dependencies=[Depends(runner)])
def finish(job_id: str, body: Finish, db: Session=Depends(get_db)):
    j=db.query(Job).filter(Job.id==job_id).with_for_update().first()
    if not j or j.lease_id!=body.lease_id: raise HTTPException(409,'Trasferimento non assegnato a questo processo.')
    if j.state=='completed' and body.success and j.result_id==body.result_id: return view(j)
    if j.state!='running' or j.lease_until<datetime.utcnow(): raise HTTPException(409,'Assegnazione scaduta.')
    if body.success and not body.result_id: raise HTTPException(400,'Conferma della destinazione mancante.')
    j.state='completed' if body.success else 'failed'; j.result_id=body.result_id if body.success else None
    j.error=None if body.success else 'Copia non confermata. Il file temporaneo è conservato: riprova o controlla le credenziali.'
    db.commit(); return view(j)

@router.get('/runner/cleanup', dependencies=[Depends(runner)])
def cleanup(db: Session=Depends(get_db)):
    now=datetime.utcnow()
    # Never remove an active lease or an upload whose signed URL may still be valid.
    for j in db.query(Job).filter(Job.expires_at<now,Job.state.in_(['uploading','pending','failed'])).all(): j.state='expired'
    db.commit()
    rows=db.query(Job).filter(Job.cleaned==False,Job.state.in_(['completed','expired','cancelled']),or_(Job.upload_until==None,Job.upload_until<now)).limit(50).all()
    return [{'id':j.id,'pathname':j.blob_path} for j in rows]

@router.post('/runner/{job_id}/cleaned', dependencies=[Depends(runner)])
def cleaned(job_id: str, db: Session=Depends(get_db)):
    j=db.query(Job).filter(Job.id==job_id).first()
    if not j or j.state not in ('completed','expired','cancelled'): raise HTTPException(409,'Pulizia non autorizzata.')
    j.cleaned=True; db.commit(); return {'ok':True}


# ---------------------------------------------------------------------------
# v31: caricamenti interrotti (pagina chiusa durante l'invio).
# Il file può essere già tutto sul Blob ma senza conferma: si può riprendere la
# copia verso Drive/MEGA. Se è incompleto o assente, si elimina e si libera il posto.
# ---------------------------------------------------------------------------
INTERRUPTED_AFTER = timedelta(minutes=30)


def _interrupted_query(db, now):
    return db.query(Job).filter(Job.state == 'uploading', or_(
        Job.upload_until < now,
        Job.expires_at <= now,
        (Job.upload_until.is_(None)) & (Job.created_at < now - INTERRUPTED_AFTER)))


@router.get('/interrupted')
async def interrupted(actor=Depends(get_admin_user), db: Session = Depends(get_db)):
    from services.private_blob import find_private_blob
    now = datetime.utcnow()
    rows = _interrupted_query(db, now).order_by(Job.created_at).limit(200).all()
    items = []
    for j in rows:
        try:
            blob = await find_private_blob(j.blob_path)
        except HTTPException:
            blob = None
        complete = blob is not None and int(getattr(blob, 'size', 0) or 0) == int(j.size)
        segments = j.path_segments or []
        items.append({**view(j), 'blob_present': blob is not None, 'blob_complete': complete,
                      'student': bool(segments) and segments[0] == 'Caricamenti studenti'})
    return {'items': items}


class Resolve(BaseModel):
    job_ids: list[str] = Field(min_length=1, max_length=200)
    action: str = Field(pattern=r'^(resume|delete)$')


@router.post('/interrupted/resolve')
async def resolve_interrupted(body: Resolve, actor=Depends(get_admin_user), db: Session = Depends(get_db)):
    from services.private_blob import delete_private_blob, find_private_blob
    now = datetime.utcnow()
    jobs = _interrupted_query(db, now).filter(Job.id.in_(body.job_ids)).all()
    resumed, deleted, incomplete, failed = 0, 0, 0, 0
    for j in jobs:
        try:
            blob = await find_private_blob(j.blob_path)
            if body.action == 'resume':
                if blob is None or int(getattr(blob, 'size', 0) or 0) != int(j.size):
                    incomplete += 1
                    continue
                # Il runner verifica comunque l'impronta SHA-256 prima di copiare.
                j.state = 'pending'
                j.error = None
                j.expires_at = max(j.expires_at, now + timedelta(days=2))
                resumed += 1
            else:
                if blob is not None:
                    await delete_private_blob(j.blob_path)
                j.state = 'cancelled'
                j.cleaned = True
                deleted += 1
            db.commit()
        except Exception as exc:  # dettagli solo nel registro
            db.rollback()
            failed += 1
            from services.diagnostics import record
            record('BLOB-01', area='trasferimenti', actor_id=actor.id,
                   technical={'step': f'caricamento interrotto: {body.action}', 'job_id': j.id,
                              'error': str(exc)[:300]})
    return {'resumed': resumed, 'deleted': deleted, 'incomplete': incomplete, 'failed': failed,
            'not_found': len(body.job_ids) - len(jobs)}

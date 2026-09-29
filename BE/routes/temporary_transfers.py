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
    count=db.query(Job).filter(Job.actor_id==actor.id, Job.state.in_(['uploading','pending','running'])).count()
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

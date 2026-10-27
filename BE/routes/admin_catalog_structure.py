"""Correzioni della struttura del catalogo, verifica Drive e registro (v26)."""
import json
from datetime import timezone

from fastapi import APIRouter, Depends, HTTPException, Query
from fastapi.responses import PlainTextResponse
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from core.database import get_db
from core.security import get_admin_user
from models.user import User
from services.catalog_structure import (
    delete_from_drive, discard_one, list_duplicates, remove_from_structure, restore_to_structure,
)
from services.catalog_intents import create_intent, pending_count, process_intents
from services.diagnostics import read_log
from services.drive_diagnostics import diagnose_drive

router = APIRouter(prefix='/admin/material-storage', tags=['admin-catalog-structure'])
diagnostics_router = APIRouter(prefix='/admin/diagnostics', tags=['admin-diagnostics'])


class RemoveRequest(BaseModel):
    material_ids: list[int] | None = Field(default=None, max_length=500)
    subject_id: int | None = Field(default=None, gt=0)
    path_segments: list[str] | None = Field(default=None, max_length=12)
    # v27: solo cartelle e file in bozza del percorso (i file pubblicati si indicano con material_ids).
    folders_only: bool = False


class DeleteDriveRequest(BaseModel):
    material_ids: list[int] = Field(min_length=1, max_length=200)
    confirmation: str = Field(max_length=20)


@router.delete('/catalog/draft/item/{kind}/{item_id}')
def admin_discard_draft_item(kind: str, item_id: int,
        current_user: User = Depends(get_admin_user), db: Session = Depends(get_db)):
    """Annulla una sola voce della bozza, senza toccare le altre."""
    try:
        return discard_one(db, current_user.id, kind, item_id)
    except ValueError as exc:
        raise HTTPException(400, str(exc)) from exc
    except LookupError as exc:
        raise HTTPException(404, str(exc)) from exc


@router.post('/catalog/structure/remove')
def admin_remove_from_structure(request: RemoveRequest,
        current_user: User = Depends(get_admin_user), db: Session = Depends(get_db)):
    """«Togli dalla struttura»: il file resta su Drive e si può ripristinare."""
    try:
        return remove_from_structure(db, current_user, material_ids=request.material_ids,
            subject_id=request.subject_id, path=request.path_segments,
            folders_only=request.folders_only)
    except ValueError as exc:
        db.rollback()
        raise HTTPException(400, str(exc)) from exc


@router.post('/catalog/structure/restore/{material_id}')
def admin_restore_to_structure(material_id: int,
        current_user: User = Depends(get_admin_user), db: Session = Depends(get_db)):
    try:
        return restore_to_structure(db, current_user, material_id)
    except LookupError as exc:
        raise HTTPException(404, str(exc)) from exc
    except ValueError as exc:
        db.rollback()
        raise HTTPException(409, str(exc)) from exc


@router.post('/catalog/structure/delete-drive')
async def admin_delete_from_drive(request: DeleteDriveRequest,
        current_user: User = Depends(get_admin_user), db: Session = Depends(get_db)):
    """«Elimina da Drive»: richiede la parola ELIMINA scritta dall'admin."""
    if request.confirmation != 'ELIMINA':
        raise HTTPException(400, 'Per confermare scrivi ELIMINA in maiuscolo.')
    try:
        return await delete_from_drive(db, current_user, request.material_ids)
    except ValueError as exc:
        db.rollback()
        raise HTTPException(400, str(exc)) from exc


@router.get('/drive/diagnose')
async def admin_drive_diagnose(current_user: User = Depends(get_admin_user)):
    """Controlli passo per passo del collegamento Drive (senza dettagli tecnici)."""
    return await diagnose_drive(current_user.id)


@router.get('/diagnostics/log', response_class=PlainTextResponse)
@diagnostics_router.get('/log', response_class=PlainTextResponse)
def admin_diagnostic_log(days: int = Query(default=7, ge=1, le=90),
        limit: int = Query(default=1000, ge=1, le=5000),
        current_user: User = Depends(get_admin_user), db: Session = Depends(get_db)):
    """Registro diagnostico come file di testo (solo admin)."""
    rows = read_log(db, days=days, limit=limit)
    lines = [f'Registro diagnostico StudentLab · ultimi {days} giorni · {len(rows)} voci',
             'Data (UTC) | Codice | Area | Admin | Messaggio | Dettagli tecnici', '']
    for row in rows:
        try:
            details = json.loads(row.details_json or '{}')
        except ValueError:
            details = {}
        area = details.pop('area', '') if isinstance(details, dict) else ''
        when = row.created_at.astimezone(timezone.utc).strftime('%Y-%m-%d %H:%M:%S') \
            if row.created_at and row.created_at.tzinfo else str(row.created_at)
        lines.append(' | '.join([when, row.action or '', area, str(row.actor_id or '-'),
            row.reason or '', json.dumps(details, ensure_ascii=False, sort_keys=True)]))
    return PlainTextResponse('\n'.join(lines) + '\n', headers={
        'Content-Disposition': 'attachment; filename="studentlab-diagnostica.txt"',
        'Cache-Control': 'no-store', 'X-Content-Type-Options': 'nosniff'})


@router.get('/diagnostics/summary')
@diagnostics_router.get('/summary')
def admin_diagnostic_summary(days: int = Query(default=7, ge=1, le=90),
        current_user: User = Depends(get_admin_user), db: Session = Depends(get_db)):
    """Quanti problemi per codice: utile per un avviso nell'app, senza dettagli."""
    counts = {}
    last = None
    for row in read_log(db, days=days, limit=5000):
        counts[row.action] = counts.get(row.action, 0) + 1
        if last is None and row.created_at:
            last = row.created_at.isoformat()
    return {'days': days, 'total': sum(counts.values()), 'by_code': counts, 'last_at': last}


# ---------------------------------------------------------------------------
# v27: doppioni e aggiunte in attesa della copia
# ---------------------------------------------------------------------------

@router.get('/catalog/duplicates')
def admin_catalog_duplicates(current_user: User = Depends(get_admin_user), db: Session = Depends(get_db)):
    """Gruppi di file identici (stesso contenuto) ancora nella struttura."""
    return list_duplicates(db)


class IntentRequest(BaseModel):
    kind: str = Field(pattern=r'^(transfer|mega)$')
    subject_id: int = Field(gt=0)
    audience_type: str = 'course'
    audience_id: int | None = Field(default=None, gt=0)
    items: list[dict] | None = Field(default=None, max_length=500)
    mega_job_id: str | None = Field(default=None, max_length=64)
    base_path: list[str] | None = Field(default=None, max_length=8)
    skip_first: bool = False


@router.post('/catalog/intents', status_code=201)
def admin_create_intent(request: IntentRequest,
        current_user: User = Depends(get_admin_user), db: Session = Depends(get_db)):
    """Ricorda dove mettere nella struttura i file che stanno arrivando su Drive."""
    try:
        return create_intent(db, current_user, request.model_dump())
    except ValueError as exc:
        db.rollback()
        raise HTTPException(400, str(exc)) from exc


@router.post('/catalog/intents/process')
async def admin_process_intents(current_user: User = Depends(get_admin_user), db: Session = Depends(get_db)):
    """Aggiunge alla bozza i file arrivati su Drive; lascia in attesa gli altri."""
    if not pending_count(db, current_user):
        return {'staged': 0, 'waiting': 0, 'conflicts': [], 'skipped': []}
    return await process_intents(db, current_user)

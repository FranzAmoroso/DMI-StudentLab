"""Correzioni della struttura del catalogo (v26).

- annullare una singola modifica in bozza;
- «Togli dalla struttura»: il materiale esce dal catalogo, il file resta su Drive;
- «Ripristina»: torna nella struttura come nascosto;
- «Elimina da Drive»: dopo conferma scritta, il file va nel cestino di Drive
  (recuperabile per 30 giorni da Drive) e il materiale esce dal catalogo.
"""
import json
from datetime import datetime, timezone

import httpx
from sqlalchemy.orm import Session

from models.material_catalog_draft import (
    MaterialCatalogDraft, MaterialCatalogFolder, MaterialCatalogImportDraft,
)
from models.public_material import PublicMaterial
from services.admin_material_storage import record_storage_event
from services.diagnostics import drive_failure, user_error
from services.drive_material_catalog import FOLDER_MIME, verify_under_root
from services.drive_material_storage import API, _access_token, _session

REMOVAL_REASON = 'Tolto dalla struttura del catalogo'


def _now():
    return datetime.now(timezone.utc)


def _prefix_match(path, prefix):
    return len(path) >= len(prefix) and path[:len(prefix)] == prefix


def _clean(parts):
    if not isinstance(parts, list) or len(parts) > 12 or any(
            not isinstance(p, str) or not p.strip() or len(p.strip()) > 80
            or p.strip() in {'.', '..'} or '/' in p or '\\' in p for p in parts):
        raise ValueError('Percorso non valido.')
    return [p.strip() for p in parts]


# ---------------------------------------------------------------------------
# Bozza: annulla una sola voce
# ---------------------------------------------------------------------------

def discard_one(db: Session, admin_id: int, kind: str, item_id: int):
    """Annulla una voce della bozza di questo admin (file, import o cartella)."""
    if kind == 'material':
        query = db.query(MaterialCatalogDraft).filter(
            MaterialCatalogDraft.admin_id == admin_id,
            MaterialCatalogDraft.material_id == item_id)
    elif kind == 'import':
        query = db.query(MaterialCatalogImportDraft).filter(
            MaterialCatalogImportDraft.admin_id == admin_id,
            MaterialCatalogImportDraft.id == item_id)
    elif kind == 'folder':
        query = db.query(MaterialCatalogFolder).filter(
            MaterialCatalogFolder.draft_admin_id == admin_id,
            MaterialCatalogFolder.id == item_id)
    else:
        raise ValueError('Tipo di modifica non valido.')
    count = query.delete(synchronize_session=False)
    db.commit()
    if not count:
        raise LookupError('Questa modifica non è più nella bozza. Aggiorna la pagina.')
    return {'discarded': count}


# ---------------------------------------------------------------------------
# Togli dalla struttura / ripristina
# ---------------------------------------------------------------------------

def _select(db, *, material_ids=None, subject_id=None, path=None):
    rows = []
    if material_ids:
        if len(material_ids) > 500:
            raise ValueError('Seleziona al massimo 500 file alla volta.')
        rows = db.query(PublicMaterial).filter(PublicMaterial.id.in_(material_ids)).with_for_update().all()
    if subject_id is not None and path is not None:
        prefix = _clean(path)
        candidates = db.query(PublicMaterial).filter(
            PublicMaterial.subject_id == subject_id,
            PublicMaterial.status != 'removed').with_for_update().all()
        known = {r.id for r in rows}
        rows += [r for r in candidates if r.id not in known and
                 _prefix_match(json.loads(r.catalog_path_json or '[]'), prefix)]
    return rows


def remove_from_structure(db: Session, actor, *, material_ids=None, subject_id=None,
                          path=None, reason=None, commit=True, folders_only=False):
    """Il materiale esce dal catalogo; il file su Drive non viene toccato.

    v27: i file si indicano con material_ids (l'app manda quelli che vede nella
    cartella, anche se spostati in bozza); il percorso serve per cartelle e file
    in bozza. Con folders_only il percorso non seleziona file pubblicati.
    """
    if not material_ids and (subject_id is None or path is None):
        raise ValueError('Indica i file o la cartella da togliere.')
    rows = _select(db, material_ids=material_ids,
                   subject_id=None if folders_only else subject_id,
                   path=None if folders_only else path)
    now = _now()
    removed = 0
    for material in rows:
        if material.status == 'removed':
            continue
        before = {'status': material.status, 'visibility_state': material.visibility_state,
                  'path_segments': json.loads(material.catalog_path_json or '[]')}
        material.status = 'removed'
        material.is_visible = False
        material.removed_by = actor.id
        material.removed_at = now
        material.removal_reason = (reason or REMOVAL_REASON)[:500]
        material.version = (material.version or 1) + 1
        material.updated_at = now
        record_storage_event(db, source='public', material_id=material.id,
            action='catalog_removed', actor_id=actor.id, blob_path=material.stored_name,
            original_name=material.original_name, size=material.size,
            reason=material.removal_reason, details={'previous': before}, commit=False)
        removed += 1
    ids = [m.id for m in rows]
    drafts = 0
    if ids:
        drafts += db.query(MaterialCatalogDraft).filter(
            MaterialCatalogDraft.admin_id == actor.id,
            MaterialCatalogDraft.material_id.in_(ids)).delete(synchronize_session=False)
    folders = imports = 0
    if subject_id is not None and path is not None:
        prefix = _clean(path)
        for folder in db.query(MaterialCatalogFolder).filter(
                MaterialCatalogFolder.subject_id == subject_id).all():
            if folder.draft_admin_id not in (None, actor.id):
                continue
            if _prefix_match(json.loads(folder.path_json), prefix):
                db.delete(folder)
                folders += 1
        for entry in db.query(MaterialCatalogImportDraft).filter(
                MaterialCatalogImportDraft.admin_id == actor.id,
                MaterialCatalogImportDraft.subject_id == subject_id).all():
            if _prefix_match(json.loads(entry.path_json), prefix):
                db.delete(entry)
                imports += 1
    if commit:
        try:
            db.commit()
        except Exception:
            db.rollback()
            raise
    return {'removed': removed, 'folders': folders, 'drafts_discarded': drafts + imports}


def restore_to_structure(db: Session, actor, material_id: int):
    """Riporta nel catalogo un materiale tolto per errore, come «nascosto»."""
    material = db.query(PublicMaterial).filter(PublicMaterial.id == material_id).with_for_update().first()
    if material is None:
        raise LookupError('Materiale non trovato.')
    if material.status != 'removed':
        return {'restored': False, 'id': material.id}
    if not material.drive_file_id:
        from models.material_storage_event import MaterialStorageEvent
        blob_gone = (material.stored_name or '').startswith('drive-import/') or db.query(
            MaterialStorageEvent.id).filter(
            MaterialStorageEvent.source == 'public',
            MaterialStorageEvent.material_id == material.id,
            MaterialStorageEvent.action.in_(['blob_deleted', 'drive_staging_blob_deleted'])).first()
        if blob_gone:
            raise ValueError('Il file non è più disponibile né su Drive né su StudentLab: non si può ripristinare.')
    now = _now()
    material.status = 'hidden'
    material.is_visible = False
    material.visibility_state = 'hidden'
    material.removed_by = None
    material.removed_at = None
    material.removal_reason = None
    material.version = (material.version or 1) + 1
    material.updated_at = now
    record_storage_event(db, source='public', material_id=material.id,
        action='catalog_restored', actor_id=actor.id, blob_path=material.stored_name,
        original_name=material.original_name, size=material.size, commit=False)
    db.commit()
    return {'restored': True, 'id': material.id, 'visibility_state': 'hidden'}


# ---------------------------------------------------------------------------
# Elimina da Drive (cestino)
# ---------------------------------------------------------------------------

def _owned_by_studentlab(material, entry):
    props = entry.get('appProperties') or {}
    if props.get('studentlab_public_id') == str(material.id):
        return True
    # File già presenti su Drive e registrati nel catalogo (import).
    return (material.stored_name or '') == f'drive-import/{material.drive_file_id}'


async def delete_from_drive(db: Session, actor, material_ids):
    """Sposta nel cestino di Drive i file dei materiali indicati.

    Prima toglie i materiali dalla struttura (se serve), poi cestina solo i
    file che risultano di StudentLab, dentro la cartella StudentLab. Mai
    cartelle, mai file non collegati al catalogo.
    """
    if not material_ids or len(material_ids) > 200:
        raise ValueError('Seleziona da 1 a 200 file.')
    rows = db.query(PublicMaterial).filter(PublicMaterial.id.in_(material_ids)).all()
    targets = [m for m in rows if m.drive_file_id]
    if not targets:
        raise ValueError('Nessuno dei file selezionati è su Drive.')
    remove_from_structure(db, actor, material_ids=[m.id for m in targets],
                          reason='Eliminato da Drive', commit=True)
    deleted, skipped = [], []
    async with await _session() as client:
        headers = {'Authorization': f'Bearer {await _access_token(client)}'}
        for material in targets:
            try:
                entry = await verify_under_root(client, headers, material.drive_file_id)
            except Exception as exc:  # già eliminato o fuori cartella
                if getattr(exc, 'status_code', None) == 404:
                    skipped.append({'id': material.id, 'reason': 'Il file non è più su Drive.'})
                    material.drive_file_id = None
                    material.drive_copied_at = None
                    continue
                raise
            if entry.get('mimeType') == FOLDER_MIME:
                skipped.append({'id': material.id, 'reason': 'Le cartelle non vengono eliminate.'})
                continue
            if not _owned_by_studentlab(material, entry):
                user_error('DRV-11', 409, technical={'step': 'elimina da drive',
                    'material_id': material.id, 'file_id': material.drive_file_id}, actor_id=actor.id)
                skipped.append({'id': material.id,
                    'reason': 'Il file su Drive non risulta caricato da StudentLab.'})
                continue
            try:
                response = await client.patch(f'{API}/files/{material.drive_file_id}', headers=headers,
                    params={'supportsAllDrives': 'true'}, json={'trashed': True})
                if response.status_code != 404:
                    response.raise_for_status()
            except httpx.HTTPError as exc:
                db.commit()
                raise drive_failure(exc, step='elimina da drive', actor_id=actor.id,
                    extra={'material_id': material.id, 'file_id': material.drive_file_id}) from exc
            previous = material.drive_file_id
            material.drive_file_id = None
            material.drive_copied_at = None
            material.updated_at = _now()
            record_storage_event(db, source='public', material_id=material.id,
                action='drive_trashed', actor_id=actor.id, blob_path=material.stored_name,
                original_name=material.original_name, size=material.size,
                details={'drive_file_id': previous}, commit=False)
            deleted.append(material.id)
    db.commit()
    return {'deleted': deleted, 'skipped': skipped}


# ---------------------------------------------------------------------------
# v27: doppioni già pubblicati (stesso contenuto, impronta SHA-256 uguale)
# ---------------------------------------------------------------------------

def list_duplicates(db: Session, limit=200):
    from sqlalchemy import func
    from services.material_catalog_draft import _conflict_view
    hashes = [h for (h,) in db.query(PublicMaterial.file_hash).filter(
        PublicMaterial.status != 'removed', PublicMaterial.file_hash.isnot(None),
        PublicMaterial.file_hash != '').group_by(PublicMaterial.file_hash).having(
        func.count(PublicMaterial.id) > 1).limit(limit).all()]
    groups = []
    for digest in hashes:
        rows = db.query(PublicMaterial).filter(PublicMaterial.file_hash == digest,
            PublicMaterial.status != 'removed').order_by(PublicMaterial.created_at).all()
        groups.append({'files': [_conflict_view(db, m) for m in rows]})
    return {'groups': groups}

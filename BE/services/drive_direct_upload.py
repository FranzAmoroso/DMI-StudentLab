"""Caricamento diretto su Google Drive, senza Blob (v31).

1. Il server crea su Drive una «sessione di caricamento» per un solo file, nella
   cartella scelta (le cartelle mancanti vengono create), usando l'account StudentLab.
2. Il browser invia i byte direttamente a Google su quell'indirizzo, a pezzi.
   Nessun limite di dimensione e nessuna copia temporanea su Blob.
3. A fine invio il server verifica il file (sotto la cartella StudentLab, dimensione,
   impronta SHA-256) e, se richiesto, lo mette subito nella bozza della struttura.

Un invio interrotto non lascia nulla: su Drive un file esiste solo a caricamento
concluso, e la sessione scade da sola. L'indirizzo della sessione vale per quel solo
file; il token dell'account non lascia mai il server.
"""
import re

import httpx

from services.admin_material_storage import record_storage_event
from services.diagnostics import drive_failure, user_error
from services.drive_material_catalog import ensure_path, verify_under_root
from services.drive_material_storage import _access_token, _session

UPLOAD = 'https://www.googleapis.com/upload/drive/v3/files'
API = 'https://www.googleapis.com/drive/v3'

# Stesse origini ammesse dal CORS del backend (main.py).
_ORIGINS = {
    'https://studentlab.net', 'https://www.studentlab.net',
    'https://studentlab-487da.web.app', 'https://studentlab-487da.firebaseapp.com',
    'https://dmi-student-lab.vercel.app',
}
_ORIGIN_RE = re.compile(r'^https://dmi-student-lab(?:-[a-zA-Z0-9-]+)*\.vercel\.app$'
                        r'|^http://localhost(?::\d+)?$|^http://127\.0\.0\.1(?::\d+)?$')
_BAD = re.compile(r'[/\\\x00-\x1f]')


def _clean_name(value: str) -> str:
    value = (value or '').strip()
    if not value or len(value) > 180 or value in {'.', '..'} or _BAD.search(value):
        raise ValueError('Nome file non valido.')
    return value


def _clean_segments(segments) -> list[str]:
    if not isinstance(segments, list) or len(segments) > 8:
        raise ValueError('Percorso su Drive non valido: al massimo 8 cartelle.')
    out = []
    for s in segments:
        s = (s or '').strip() if isinstance(s, str) else ''
        if not s or len(s) > 80 or s in {'.', '..'} or _BAD.search(s):
            raise ValueError('Nome di cartella non valido (massimo 80 caratteri, senza / o \\).')
        out.append(s)
    return out


def allowed_origin(origin: str | None) -> str | None:
    if origin and (origin in _ORIGINS or _ORIGIN_RE.match(origin)):
        return origin
    return None


async def create_session(db, actor, *, filename, mime_type, size, sha256, path_segments, origin):
    name = _clean_name(filename)
    path = _clean_segments(path_segments)
    if not isinstance(size, int) or size <= 0:
        raise ValueError('Il file è vuoto.')
    if not re.fullmatch(r'[a-f0-9]{64}', sha256 or ''):
        raise ValueError('Impronta del file non valida.')
    if not re.fullmatch(r'[\w.+-]+/[\w.+-]+', mime_type or ''):
        mime_type = 'application/octet-stream'
    async with await _session() as client:
        headers = {'Authorization': f'Bearer {await _access_token(client)}'}
        folder_id = await ensure_path(client, headers, path)
        extra = {'Origin': origin} if origin else {}
        try:
            response = await client.post(UPLOAD, headers={
                **headers, **extra,
                'Content-Type': 'application/json; charset=UTF-8',
                'X-Upload-Content-Type': mime_type,
                'X-Upload-Content-Length': str(size)},
                params={'uploadType': 'resumable', 'supportsAllDrives': 'true',
                        'fields': 'id,name,size,sha256Checksum'},
                json={'name': name, 'parents': [folder_id], 'mimeType': mime_type,
                      'appProperties': {'studentlab_upload': 'direct', 'sha256': sha256}})
            response.raise_for_status()
            url = response.headers.get('Location') or ''
        except httpx.HTTPError as exc:
            raise drive_failure(exc, step='sessione di caricamento', actor_id=actor.id,
                                extra={'path': path, 'size': size}) from exc
    if not url.startswith('https://'):
        raise user_error('DRV-04', 503, technical={'step': 'sessione di caricamento', 'reason': 'Location mancante'})
    record_storage_event(db, source='drive_upload', material_id=None, action='session_created',
                         actor_id=actor.id, original_name=name[:255], size=size,
                         details={'path_segments': path, 'folder_id': folder_id})
    return {'upload_url': url, 'folder_id': folder_id}


async def complete(db, actor, *, file_id, size, sha256, stage=None):
    from services.material_catalog_draft import stage_drive_import
    async with await _session() as client:
        headers = {'Authorization': f'Bearer {await _access_token(client)}'}
        item = await verify_under_root(client, headers, file_id)
        try:
            meta = await client.get(f'{API}/files/{item["id"]}', headers=headers,
                params={'fields': 'id,name,size,mimeType,sha256Checksum,appProperties',
                        'supportsAllDrives': 'true'})
            meta.raise_for_status()
            data = meta.json()
        except (httpx.HTTPError, ValueError) as exc:
            raise drive_failure(exc, step='verifica caricamento', actor_id=actor.id,
                                extra={'file_id': file_id}) from exc
        props = data.get('appProperties') or {}
        if props.get('studentlab_upload') != 'direct' or props.get('sha256') != sha256:
            raise ValueError('Il file su Drive non corrisponde a quello inviato.')
        drive_sha = (data.get('sha256Checksum') or '').lower()
        if int(data.get('size') or 0) != int(size) or (drive_sha and drive_sha != sha256):
            # File arrivato rovinato: va nel cestino di Drive e si ricarica.
            try:
                await client.patch(f'{API}/files/{item["id"]}', headers=headers,
                                   params={'supportsAllDrives': 'true'}, json={'trashed': True})
            except httpx.HTTPError:
                pass
            raise ValueError(f'«{data.get("name")}» non è arrivato integro su Drive: caricalo di nuovo.')
    record_storage_event(db, source='drive_upload', material_id=None, action='uploaded',
                         actor_id=actor.id, original_name=(data.get('name') or '')[:255], size=int(size),
                         details={'file_id': data['id']})
    result = {'file_id': data['id'], 'name': data.get('name'), 'staged': None}
    if stage:
        result['staged'] = await stage_drive_import(
            db, admin_id=actor.id, file_id=data['id'], subject_id=int(stage['subject_id']),
            path=stage.get('path_segments') or [], audience=stage.get('audience_type') or 'course',
            audience_id=stage.get('audience_id'), allow_duplicate=bool(stage.get('allow_duplicate')))
    return result

"""Inspect and create paths beneath StudentLab's configured Drive folder only."""
import json
import re
from collections import deque

import httpx
from fastapi import HTTPException

from core.config import settings

API = 'https://www.googleapis.com/drive/v3'
FOLDER_MIME = 'application/vnd.google-apps.folder'
MAX_ITEMS = 15000
MAX_DEPTH = 20


def clean_path(segments):
    if not isinstance(segments, list) or len(segments) > MAX_DEPTH:
        raise HTTPException(400, 'Il percorso Drive supera il limite di cartelle.')
    cleaned = []
    for segment in segments:
        if not isinstance(segment, str):
            raise HTTPException(400, 'Percorso Drive non valido.')
        name = segment.strip()
        if not name or len(name) > 150 or name in {'.', '..'} or '/' in name or '\\' in name or any(ord(c) < 32 for c in name):
            raise HTTPException(400, 'Una cartella Drive contiene caratteri non validi.')
        cleaned.append(name)
    return cleaned


def default_path(material):
    subject = getattr(material, 'subject', None)
    labels = [material.university, material.department, material.course,
        getattr(subject, 'name', None) or 'Materiali del corso',
        *json.loads(getattr(material, 'catalog_path_json', None) or '[]')]
    return clean_path([re.sub(r'[\\/\x00-\x1f]+', ' - ', str(label)).strip()[:150]
        for label in labels])


def _safe_id(value):
    if not isinstance(value, str) or not re.fullmatch(r'[a-zA-Z0-9_-]{8,128}', value):
        raise HTTPException(400, 'Identificativo Drive non valido.')
    return value


async def _children(client, headers, parent):
    token = None
    while True:
        try:
            params = {
                'q': f"'{_safe_id(parent)}' in parents and trashed = false",
                'pageSize': 1000,
                'fields': 'nextPageToken,files(id,name,mimeType,size,modifiedTime,md5Checksum,appProperties,parents)',
                'supportsAllDrives': 'true', 'includeItemsFromAllDrives': 'true',
            }
            if token:
                params['pageToken'] = token
            response = await client.get(f'{API}/files', headers=headers, params={
                **params})
            response.raise_for_status()
            data = response.json()
        except (httpx.HTTPError, ValueError) as exc:
            raise HTTPException(503, 'Impossibile controllare tutte le cartelle Drive.') from exc
        for entry in data.get('files', []):
            yield entry
        token = data.get('nextPageToken')
        if not token:
            break


async def scan_tree(client, headers):
    queue = deque([(settings.drive_folder_id, [])])
    nodes = []
    while queue:
        folder, path = queue.popleft()
        async for entry in _children(client, headers, folder):
            if len(nodes) >= MAX_ITEMS:
                raise HTTPException(503, 'L’albero Drive è troppo grande per una verifica completa.')
            name = entry.get('name', '')
            if not isinstance(name, str) or not name:
                continue
            current_path = [*path, name]
            nodes.append((entry, current_path))
            if entry.get('mimeType') == FOLDER_MIME:
                if len(current_path) >= MAX_DEPTH:
                    raise HTTPException(503, 'Una cartella Drive supera la profondità supportata.')
                queue.append((entry['id'], current_path))
    return nodes


def describe(entry, path, wanted_path):
    props = entry.get('appProperties') or {}
    return {'id': entry['id'], 'name': entry.get('name'), 'path': '/'.join(path),
        'size': int(entry['size']) if entry.get('size') is not None else None,
        'mime_type': entry.get('mimeType'), 'modified_at': entry.get('modifiedTime'),
        'sha256': props.get('sha256'), 'same_folder': path[:-1] == wanted_path,
        'preview_available': entry.get('mimeType') not in (FOLDER_MIME, None)}


def matches(material, nodes, path):
    path = clean_path(path)
    conflicts = []
    for entry, current in nodes:
        if entry.get('mimeType') == FOLDER_MIME:
            continue
        props = entry.get('appProperties') or {}
        same_hash = props.get('sha256', '').lower() == material.file_hash.lower()
        same_name = entry.get('name', '').casefold() == material.original_name.casefold()
        if same_hash or same_name:
            item = describe(entry, current, path)
            item['reason'] = 'same_content' if same_hash else 'same_name'
            conflicts.append(item)
    return conflicts


def find_path(nodes, path):
    parent = settings.drive_folder_id
    exists = []
    for index, name in enumerate(path):
        folders = [entry for entry, current in nodes
            if entry.get('mimeType') == FOLDER_MIME and current == [*exists, name]]
        if len(folders) > 1:
            raise HTTPException(409, 'Esistono più cartelle Drive con lo stesso percorso; scegli un’altra cartella.')
        if not folders:
            return parent, path[index:], exists
        parent = folders[0]['id']; exists.append(name)
    return parent, [], exists


async def preview(client, headers, material, path):
    path = clean_path(path)
    nodes = await scan_tree(client, headers)
    parent, missing, existing = find_path(nodes, path)
    return {'path': path, 'existing_path': existing, 'missing_folders': missing,
        'target_folder_id': parent if not missing else None,
        'proposed_file': {'name': material.original_name, 'path': '/'.join([*path, material.original_name]),
            'size': material.size, 'mime_type': material.mime_type, 'sha256': material.file_hash},
        'conflicts': matches(material, nodes, path)}


async def ensure_path(client, headers, path):
    path = clean_path(path)
    # Recheck under every parent before creating the next folder.
    parent = settings.drive_folder_id
    for name in path:
        matches_found = [e async for e in _children(client, headers, parent)
            if e.get('name') == name and e.get('mimeType') == FOLDER_MIME]
        if len(matches_found) > 1:
            raise HTTPException(409, 'Cartelle Drive omonime: scegli un altro percorso.')
        if matches_found:
            parent = matches_found[0]['id']; continue
        try:
            response = await client.post(f'{API}/files', headers=headers,
                params={'fields': 'id', 'supportsAllDrives': 'true'},
                json={'name': name, 'mimeType': FOLDER_MIME, 'parents': [parent]})
            response.raise_for_status()
            parent = response.json()['id']
        except (httpx.HTTPError, KeyError, ValueError) as exc:
            raise HTTPException(503, 'Non è stato possibile creare la cartella Drive.') from exc
    return parent


async def verify_under_root(client, headers, file_id):
    """An admin preview cannot read files outside the configured folder."""
    file_id = _safe_id(file_id)
    original = None
    for _ in range(MAX_DEPTH + 1):
        try:
            response = await client.get(f'{API}/files/{file_id}', headers=headers,
                params={'fields': 'id,name,mimeType,size,parents,trashed,appProperties', 'supportsAllDrives': 'true'})
            response.raise_for_status()
            item = response.json()
        except (httpx.HTTPError, ValueError) as exc:
            raise HTTPException(404, 'File Drive non disponibile.') from exc
        if item.get('trashed'):
            raise HTTPException(404, 'File Drive non disponibile.')
        if original is None:
            original = item
        parents = item.get('parents') or []
        if settings.drive_folder_id in parents:
            return original
        if len(parents) != 1:
            break
        file_id = _safe_id(parents[0])
    raise HTTPException(404, 'File esterno alla cartella StudentLab.')

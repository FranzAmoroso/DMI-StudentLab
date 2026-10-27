"""«Verifica collegamento Drive»: controlli passo per passo per l'admin.

Ogni controllo restituisce solo etichetta, esito e suggerimento. I dettagli
tecnici di un controllo fallito vanno nel registro diagnostico.
"""
import httpx

from core.config import settings
from services.diagnostics import MESSAGES, drive_code_for, google_reason, record
from services.drive_material_storage import API, TOKEN, _session

FOLDER_MIME = 'application/vnd.google-apps.folder'


def _check(label, ok, code=None, note=None):
    message, suggestion = MESSAGES.get(code, ('', '')) if code else ('', '')
    return {'label': label, 'ok': ok, 'code': code,
            'message': note or message, 'suggestion': suggestion if not ok else ''}


async def diagnose_drive(actor_id=None):
    try:
        return await _diagnose(actor_id)
    except httpx.HTTPError as exc:
        record('DRV-04', area='drive', technical={'step': 'diagnosi', 'error_type': type(exc).__name__},
               actor_id=actor_id)
        return {'ok': False, 'checks': [_check('Collegamento a Google', False, 'DRV-04')]}


async def _diagnose(actor_id):
    checks = []
    missing = [name for name, value in (
        ('cartella', settings.drive_folder_id), ('client', settings.drive_client_id),
        ('segreto', settings.drive_client_secret), ('autorizzazione', settings.drive_refresh_token),
        ('account', settings.drive_account_email)) if not value]
    if missing:
        record('DRV-01', area='drive', technical={'step': 'diagnosi', 'missing': missing}, actor_id=actor_id)
        return {'ok': False, 'checks': [_check('Impostazioni sul server', False, 'DRV-01')]}
    checks.append(_check('Impostazioni sul server', True, note='Presenti'))
    async with await _session() as client:
        # 1. Autorizzazione (refresh token)
        try:
            response = await client.post(TOKEN, data={
                'grant_type': 'refresh_token', 'client_id': settings.drive_client_id,
                'client_secret': settings.drive_client_secret,
                'refresh_token': settings.drive_refresh_token})
        except httpx.HTTPError as exc:
            record('DRV-04', area='drive', technical={'step': 'diagnosi token', 'error_type': type(exc).__name__},
                   actor_id=actor_id)
            checks.append(_check('Autorizzazione Google', False, 'DRV-04'))
            return {'ok': False, 'checks': checks}
        if response.status_code != 200:
            reason = google_reason(response)
            error = reason.get('google_error')
            code = ('DRV-02' if error == 'invalid_grant' else
                    'DRV-03' if error in {'invalid_client', 'unauthorized_client'} else 'DRV-04')
            record(code, area='drive', technical={'step': 'diagnosi token', **reason}, actor_id=actor_id)
            checks.append(_check('Autorizzazione Google', False, code))
            return {'ok': False, 'checks': checks}
        token = response.json().get('access_token', '')
        scope = response.json().get('scope', '')
        headers = {'Authorization': f'Bearer {token}'}
        checks.append(_check('Autorizzazione Google', True, note='Valida'))
        scopes = scope.split()
        if scopes and 'https://www.googleapis.com/auth/drive' not in scopes:
            # Permesso limitato (es. drive.file): i file caricati a mano non sono visibili.
            record('DRV-06', area='drive', technical={'step': 'diagnosi permessi', 'scope': scope},
                   actor_id=actor_id)
            checks.append(_check('Permessi su Drive', False, 'DRV-06',
                                 note='L’autorizzazione vede solo i file creati da StudentLab.'))
        # 2. Account
        about = await client.get(f'{API}/about', headers=headers, params={'fields': 'user(emailAddress)'})
        if about.status_code != 200:
            code = drive_code_for(about)
            record(code, area='drive', technical={'step': 'diagnosi account', **google_reason(about)},
                   actor_id=actor_id)
            checks.append(_check('Account Google', False, code))
            return {'ok': False, 'checks': checks}
        account = (about.json().get('user') or {}).get('emailAddress', '')
        if account.lower() != settings.drive_account_email.lower():
            record('DRV-05', area='drive', technical={'step': 'diagnosi account',
                   'expected': settings.drive_account_email, 'actual': account}, actor_id=actor_id)
            checks.append(_check('Account Google', False, 'DRV-05'))
            return {'ok': False, 'checks': checks}
        checks.append(_check('Account Google', True, note='È l’account di StudentLab'))
        # 3. Cartella principale
        folder = await client.get(f'{API}/files/{settings.drive_folder_id}', headers=headers,
            params={'fields': 'id,mimeType,trashed,capabilities(canAddChildren,canListChildren)',
                    'supportsAllDrives': 'true'})
        if folder.status_code != 200:
            code = drive_code_for(folder)
            record(code, area='drive', technical={'step': 'diagnosi cartella',
                   'folder_id': settings.drive_folder_id, **google_reason(folder)}, actor_id=actor_id)
            checks.append(_check('Cartella StudentLab', False, code))
            return {'ok': False, 'checks': checks}
        item = folder.json()
        if item.get('mimeType') != FOLDER_MIME or item.get('trashed'):
            record('DRV-07', area='drive', technical={'step': 'diagnosi cartella',
                   'folder_id': settings.drive_folder_id, 'mime_type': item.get('mimeType'),
                   'trashed': item.get('trashed')}, actor_id=actor_id)
            checks.append(_check('Cartella StudentLab', False, 'DRV-07'))
            return {'ok': False, 'checks': checks}
        checks.append(_check('Cartella StudentLab', True, note='Trovata'))
        # 4. Lettura dei file
        listing = await client.get(f'{API}/files', headers=headers, params={
            'q': f"'{settings.drive_folder_id}' in parents and trashed = false",
            'pageSize': 1, 'fields': 'files(id)', 'supportsAllDrives': 'true',
            'includeItemsFromAllDrives': 'true'})
        if listing.status_code != 200:
            code = drive_code_for(listing)
            record(code, area='drive', technical={'step': 'diagnosi elenco', **google_reason(listing)},
                   actor_id=actor_id)
            checks.append(_check('Lettura dei file', False, code))
            return {'ok': False, 'checks': checks}
        checks.append(_check('Lettura dei file', True, note='Funziona'))
        # 5. Scrittura
        can_add = (item.get('capabilities') or {}).get('canAddChildren')
        if not can_add:
            record('DRV-10', area='drive', technical={'step': 'diagnosi scrittura',
                   'folder_id': settings.drive_folder_id}, actor_id=actor_id)
        checks.append(_check('Caricamento nuovi file', bool(can_add), None if can_add else 'DRV-10',
                             note='Consentito' if can_add else None))
    return {'ok': all(c['ok'] for c in checks), 'checks': checks}

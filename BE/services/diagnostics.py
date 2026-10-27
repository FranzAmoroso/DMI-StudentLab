"""Errori mostrati all'utente e registro diagnostico per gli amministratori.

Regola (Play Store e privacy): nell'app compaiono solo una frase semplice,
un suggerimento e un codice breve (es. DRV-02). Il motivo tecnico (risposta
di Google, stato HTTP, passaggio fallito, ID dei file) resta nel registro del
server e nel file scaricabile dagli admin. Token, segreti e password non
vengono mai scritti, nemmeno nel registro.

Il registro usa la tabella esistente material_storage_events
(source='diagnostic'): nessuna migrazione.
"""
import json
import logging
import re
import time
from datetime import datetime, timedelta, timezone

from fastapi import HTTPException

logger = logging.getLogger('studentlab.diagnostics')
_recent: dict = {}

# codice -> (frase semplice, suggerimento)
MESSAGES = {
    'DRV-01': ('Google Drive non è ancora collegato a StudentLab.',
               'Completa il collegamento dalla pagina Sorgenti.'),
    'DRV-02': ('L’accesso a Google Drive è scaduto o è stato revocato.',
               'Ricollega l’account Google di StudentLab e aggiorna l’autorizzazione sul server.'),
    'DRV-03': ('Le credenziali dell’app Google non sono valide.',
               'Controlla il client OAuth nelle impostazioni del server.'),
    'DRV-04': ('Google Drive non risponde in questo momento.',
               'Riprova tra qualche minuto.'),
    'DRV-05': ('L’account Google collegato non è quello di StudentLab.',
               'Ricollega Drive usando l’account di StudentLab.'),
    'DRV-06': ('StudentLab non ha il permesso di leggere questa cartella.',
               'Condividi la cartella con l’account di StudentLab oppure ricollega Drive.'),
    'DRV-07': ('Il file o la cartella non si trova più su Drive.',
               'Aggiorna la pagina: potrebbe essere stato spostato o eliminato.'),
    'DRV-08': ('Il file si trova fuori dalla cartella StudentLab.',
               'Spostalo nella cartella StudentLab su Drive e riprova.'),
    'DRV-09': ('Lo spazio o il limite giornaliero di Google Drive è esaurito.',
               'Libera spazio su Drive oppure riprova più tardi.'),
    'DRV-10': ('L’account collegato non può aggiungere file nella cartella principale.',
               'Dai all’account di StudentLab il permesso di modifica sulla cartella.'),
    'DRV-11': ('Il file su Drive non risulta caricato da StudentLab.',
               'Eliminalo direttamente da Google Drive se sei sicuro.'),
    'MEGA-01': ('Il servizio MEGA non è raggiungibile.',
                'Riprova tra poco. Se il problema continua, controlla il servizio MEGA sul server.'),
    'MEGA-02': ('Il servizio MEGA non è configurato sul server.',
                'Imposta indirizzo e chiave del servizio MEGA nelle variabili del server.'),
    'UPL-01': ('I caricamenti verso MEGA non sono attivi.',
               'Chiedi a un amministratore di attivarli.'),
    'UPL-02': ('Hai raggiunto il limite di caricamenti per oggi.',
               'Riprova domani o completa quelli in attesa.'),
    'UPL-03': ('Questo tipo di file non è accettato.',
               'Carica PDF, documenti, presentazioni, immagini, testo o ZIP.'),
}

_SECRETS = [
    re.compile(r'ya29\.[\w.-]+'),                 # access token Google
    re.compile(r'1//[\w.-]{20,}'),                # refresh token Google
    re.compile(r'GOCSPX-[\w-]+'),                 # client secret Google
    re.compile(r'(?i)bearer\s+[\w.~+/=-]+'),
    re.compile(r'(?i)(password|secret|token|session|sid|key)(["\']?\s*[:=]\s*["\']?)[^\s,"\'}]+'),
    re.compile(r'[A-Za-z0-9+/_-]{48,}={0,2}'),   # blob lunghi (chiavi, sessioni)
]


def scrub(value):
    """Toglie token e segreti da testi e strutture prima di registrarli."""
    if isinstance(value, dict):
        return {str(k)[:60]: ('[nascosto]' if re.search(r'(?i)token|secret|password|session|sid|^key$', str(k))
                              else scrub(v)) for k, v in list(value.items())[:40]}
    if isinstance(value, (list, tuple)):
        return [scrub(v) for v in list(value)[:40]]
    if isinstance(value, (int, float, bool)) or value is None:
        return value
    text = str(value)[:600]
    for pattern in _SECRETS:
        text = pattern.sub(lambda m: (m.group(1) + m.group(2) + '[nascosto]')
                           if m.re.groups >= 2 else '[nascosto]', text)
    return text


def user_message(code):
    message, suggestion = MESSAGES.get(code, ('Operazione non completata.', 'Riprova tra poco.'))
    return f'{message} {suggestion} (codice {code})'


def record(code, *, area, technical=None, actor_id=None, level=logging.WARNING):
    """Scrive nel log del server e, se possibile, nel registro consultabile."""
    clean = scrub(technical or {})
    message = MESSAGES.get(code, ('Operazione non completata.', ''))[0]
    try:
        logger.log(level, 'diagnostic code=%s area=%s actor=%s details=%s', code, area, actor_id,
                   json.dumps(clean, ensure_ascii=False, sort_keys=True))
    except Exception:  # il log non deve mai bloccare la richiesta
        pass
    # Lo stesso problema ripetuto (es. a ogni apertura di cartella) si salva al massimo una volta al minuto.
    key = (code, area, str((clean or {}).get('step') if isinstance(clean, dict) else ''))
    now = time.monotonic()
    if now - _recent.get(key, -1e9) < 60:
        return
    _recent[key] = now
    if len(_recent) > 500:
        _recent.clear()
    try:
        from core.database import SessionLocal
        from models.material_storage_event import MaterialStorageEvent
        db = SessionLocal()
        try:
            db.add(MaterialStorageEvent(source='diagnostic', material_id=None, action=code[:50],
                actor_id=actor_id, reason=message,
                details_json=json.dumps({'area': area, **(clean if isinstance(clean, dict) else {'detail': clean})},
                                        ensure_ascii=False, sort_keys=True)[:8000]))
            db.commit()
        finally:
            db.close()
    except Exception:
        logger.debug('diagnostic_store_skipped code=%s', code)


def user_error(code, status=503, *, area='drive', technical=None, actor_id=None):
    """HTTPException con frase semplice + suggerimento; il resto va nel registro."""
    record(code, area=area, technical=technical, actor_id=actor_id)
    return HTTPException(status, user_message(code), headers={'X-StudentLab-Error': code})


def google_reason(response):
    """Motivo tecnico di una risposta Google (solo per il registro)."""
    try:
        data = response.json()
    except Exception:
        return {'http_status': getattr(response, 'status_code', None)}
    error = data.get('error') if isinstance(data, dict) else None
    if isinstance(error, dict):
        reasons = [e.get('reason') for e in error.get('errors') or [] if isinstance(e, dict)]
        return {'http_status': response.status_code, 'google_status': error.get('status'),
                'google_reason': ','.join(r for r in reasons if r) or None,
                'google_message': str(error.get('message') or '')[:200]}
    return {'http_status': response.status_code, 'google_error': error,
            'google_message': str(data.get('error_description') or '')[:200] if isinstance(data, dict) else None}


def drive_code_for(response):
    """Codice utente per una risposta d'errore delle API Drive."""
    status = getattr(response, 'status_code', 0)
    reason = (google_reason(response).get('google_reason') or '') if response is not None else ''
    if status == 401:
        return 'DRV-02'
    if status == 404:
        return 'DRV-07'
    if status == 403:
        if any(r in reason for r in ('storageQuotaExceeded', 'dailyLimitExceeded', 'quotaExceeded')):
            return 'DRV-09'
        if any(r in reason for r in ('rateLimitExceeded', 'userRateLimitExceeded')):
            return 'DRV-04'
        return 'DRV-06'
    return 'DRV-04'


def drive_failure(exc, *, step, actor_id=None, extra=None):
    """Converte un errore httpx delle API Drive in HTTPException per l'utente."""
    import httpx
    response = getattr(exc, 'response', None) if isinstance(exc, httpx.HTTPStatusError) else None
    technical = {'step': step, 'error_type': type(exc).__name__, **(extra or {})}
    if response is not None:
        technical.update(google_reason(response))
        code = drive_code_for(response)
    else:
        code = 'DRV-04'
    status = {'DRV-07': 404, 'DRV-06': 403, 'DRV-09': 507}.get(code, 503)
    return user_error(code, status, area='drive', technical=technical, actor_id=actor_id)


def read_log(db, *, days=7, limit=1000):
    from models.material_storage_event import MaterialStorageEvent
    since = datetime.now(timezone.utc) - timedelta(days=max(1, min(days, 90)))
    return db.query(MaterialStorageEvent).filter(
        MaterialStorageEvent.source == 'diagnostic',
        MaterialStorageEvent.created_at >= since,
    ).order_by(MaterialStorageEvent.id.desc()).limit(max(1, min(limit, 5000))).all()

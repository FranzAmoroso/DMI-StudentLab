"""Aggiunte alla struttura «in attesa di copia» (v27), senza migrazioni.

Quando l'admin trascina file o cartelle dal PC nella struttura, oppure copia
una cartella da MEGA, i file arrivano su Drive solo dopo qualche minuto (li
copia un servizio separato). Qui si ricorda dove vanno messi nella struttura:
una riga in material_storage_events con source='catalog_intent'.

Ogni volta che l'admin apre il catalogo, process_intents() controlla le copie
terminate e aggiunge i file alla bozza, rispettando cartelle e sottocartelle.
"""
import json
from datetime import datetime, timezone

from sqlalchemy.orm import Session

from models.material_storage_event import MaterialStorageEvent
from models.subject import Subject
from models.temporary_transfer import TemporaryTransfer
from services.material_catalog_draft import _path, stage_drive_import

SOURCE = 'catalog_intent'
AUDIENCES = {'public', 'course', 'subject', 'group', 'user'}


def _check_target(db, subject_id, audience_type, audience_id):
    if db.query(Subject.id).filter(Subject.id == subject_id, Subject.is_active.is_(True)).first() is None:
        raise ValueError('Materia non disponibile.')
    if audience_type not in AUDIENCES:
        raise ValueError('Destinatari non validi.')
    if audience_type in {'group', 'user'} and not audience_id:
        raise ValueError('Indica il gruppo o lo studente.')


def create_intent(db: Session, actor, body: dict):
    kind = body.get('kind')
    subject_id = int(body.get('subject_id') or 0)
    audience_type = body.get('audience_type') or 'course'
    audience_id = body.get('audience_id')
    _check_target(db, subject_id, audience_type, audience_id)
    details = {'kind': kind, 'subject_id': subject_id, 'audience_type': audience_type,
               'audience_id': audience_id, 'created_at': datetime.now(timezone.utc).isoformat()}
    if kind == 'transfer':
        items = []
        for item in (body.get('items') or [])[:500]:
            job_id = str(item.get('job_id') or '')
            job = db.query(TemporaryTransfer).filter(TemporaryTransfer.id == job_id,
                TemporaryTransfer.actor_id == actor.id).first()
            if job is None or job.destination != 'drive':
                raise ValueError('Caricamento non trovato. Riprova a trascinare i file.')
            items.append({'job_id': job_id, 'name': job.filename,
                          'path_segments': _path(list(item.get('path_segments') or [])),
                          'state': 'waiting'})
        if not items:
            raise ValueError('Nessun file da aggiungere.')
        details['items'] = items
    elif kind == 'mega':
        job_id = str(body.get('mega_job_id') or '')
        if not job_id or len(job_id) > 64:
            raise ValueError('Copia MEGA non valida.')
        details.update({'mega_job_id': job_id,
                        'base_path': _path(list(body.get('base_path') or [])),
                        'skip_first': bool(body.get('skip_first')), 'state': 'waiting'})
    else:
        raise ValueError('Tipo di aggiunta non valido.')
    row = MaterialStorageEvent(source=SOURCE, material_id=None, action='pending', actor_id=actor.id,
                               reason='Aggiunta alla struttura in attesa della copia',
                               details_json=json.dumps(details, ensure_ascii=False))
    db.add(row)
    db.commit()
    return {'id': row.id, 'waiting': len(details.get('items') or []) or 1}


def pending_count(db: Session, actor) -> int:
    return db.query(MaterialStorageEvent.id).filter(MaterialStorageEvent.source == SOURCE,
        MaterialStorageEvent.action == 'pending', MaterialStorageEvent.actor_id == actor.id).count()


async def _stage(db, actor, details, file_id, path, name, summary):
    try:
        result = await stage_drive_import(db, admin_id=actor.id, file_id=file_id,
            subject_id=details['subject_id'], path=path, audience=details['audience_type'],
            audience_id=details.get('audience_id'))
    except (ValueError, RuntimeError) as exc:
        db.rollback()
        summary['skipped'].append({'name': name, 'reason': str(exc)})
        return 'skipped'
    except Exception as exc:  # Drive non raggiungibile: si riprova alla prossima apertura
        db.rollback()
        if getattr(exc, 'status_code', None) in (404, 403):
            summary['skipped'].append({'name': name, 'reason': getattr(exc, 'detail', 'File non disponibile.')})
            return 'skipped'
        return 'waiting'
    if result.get('staged'):
        summary['staged'] += 1
        return 'staged'
    if result.get('conflicts') or result.get('already_in_catalog'):
        summary['conflicts'].append({'name': name, 'file_id': file_id, 'path_segments': path,
            'conflicts': result.get('conflicts') or [result.get('already_in_catalog')]})
        return 'conflict'
    return 'skipped'


async def process_intents(db: Session, actor):
    """Aggiunge alla bozza i file delle copie terminate. Non tocca le copie in corso."""
    from services import mega_storage as gateway

    summary = {'staged': 0, 'waiting': 0, 'conflicts': [], 'skipped': []}
    rows = db.query(MaterialStorageEvent).filter(MaterialStorageEvent.source == SOURCE,
        MaterialStorageEvent.action == 'pending', MaterialStorageEvent.actor_id == actor.id).order_by(
        MaterialStorageEvent.id).limit(50).all()
    for row in rows:
        details = json.loads(row.details_json or '{}')
        if details.get('kind') == 'transfer':
            for item in details.get('items') or []:
                if item.get('state') != 'waiting':
                    continue
                job = db.query(TemporaryTransfer).filter(TemporaryTransfer.id == item['job_id']).first()
                if job is None or job.state in {'cancelled', 'expired'} or (job.state == 'failed' and job.cleaned):
                    item['state'] = 'skipped'
                    summary['skipped'].append({'name': item.get('name'), 'reason': 'Caricamento annullato o scaduto.'})
                elif job.state == 'completed' and job.result_id:
                    item['state'] = await _stage(db, actor, details, job.result_id,
                                                 item['path_segments'], item.get('name'), summary)
                if item['state'] == 'waiting':
                    summary['waiting'] += 1
            done = all(i.get('state') != 'waiting' for i in details.get('items') or [])
        elif details.get('kind') == 'mega':
            try:
                job = await gateway.worker('/jobs/' + details['mega_job_id'], params={'actor_id': actor.id})
            except Exception:
                summary['waiting'] += 1
                continue
            if job.get('state') in {'queued', 'running'}:
                summary['waiting'] += 1
                done = False
            else:
                destination = list(job.get('destination') or [])
                for result in job.get('results') or []:
                    if not result.get('drive_file_id'):
                        continue
                    relative = list(result.get('path_segments') or [])[len(destination):]
                    if details.get('skip_first') and relative:
                        relative = relative[1:]
                    try:
                        path = _path(details['base_path'] + relative)
                    except ValueError:
                        summary['skipped'].append({'name': result.get('name'),
                                                   'reason': 'Troppe cartelle una dentro l’altra (massimo 8).'})
                        continue
                    await _stage(db, actor, details, result['drive_file_id'], path, result.get('name'), summary)
                details['state'] = job.get('state')
                done = True
        else:
            done = True
        row.details_json = json.dumps(details, ensure_ascii=False)
        if done:
            row.action = 'done'
        db.commit()
    return summary

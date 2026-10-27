"""Impostazioni del catalogo (v30), senza migrazioni.

Si salvano come righe di material_storage_events (source='catalog_setting'):
vale l'ultima. Ogni cambio resta nello storico, con chi l'ha fatto.

guest_entry: da dove partono le Dispense per chi non ha fatto l'accesso.
  level = 'university' | 'department' | 'course' | 'subject'
  university / department / course = i livelli sopra quello di partenza.
È solo una vista: non tocca file né cartelle, si cambia quando si vuole.
"""
import json

from sqlalchemy.orm import Session

from models.material_storage_event import MaterialStorageEvent

SOURCE = 'catalog_setting'
LEVELS = ('university', 'department', 'course', 'subject')
DEFAULT_GUEST_ENTRY = {'level': 'university', 'university': None, 'department': None, 'course': None}


def get_guest_entry(db: Session):
    row = db.query(MaterialStorageEvent).filter(MaterialStorageEvent.source == SOURCE,
        MaterialStorageEvent.action == 'guest_entry').order_by(MaterialStorageEvent.id.desc()).first()
    if row is None:
        return dict(DEFAULT_GUEST_ENTRY)
    try:
        value = json.loads(row.details_json or '{}')
    except ValueError:
        return dict(DEFAULT_GUEST_ENTRY)
    return {**DEFAULT_GUEST_ENTRY, **{k: value.get(k) for k in DEFAULT_GUEST_ENTRY}}


def set_guest_entry(db: Session, actor, body: dict):
    level = body.get('level')
    if level not in LEVELS:
        raise ValueError('Livello di partenza non valido.')
    clean = {'level': level}
    needed = {'university': 1, 'department': 2, 'course': 3, 'subject': 3}[level] if level != 'university' else 0
    for i, key in enumerate(('university', 'department', 'course')):
        value = (body.get(key) or '').strip()[:255] or None
        if i < needed and not value:
            raise ValueError('Indica ' + {'university': 'l’ateneo', 'department': 'il dipartimento',
                                         'course': 'il corso'}[key] + ' da cui partire.')
        clean[key] = value if i < needed else None
    db.add(MaterialStorageEvent(source=SOURCE, material_id=None, action='guest_entry', actor_id=actor.id,
                                reason='Partenza delle Dispense per gli ospiti',
                                details_json=json.dumps(clean, ensure_ascii=False)))
    db.commit()
    return clean

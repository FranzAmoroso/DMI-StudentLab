"""Materie doppie (v30): stesso corso con due nomi (es. «Informatica» e
«Scienze e tecnologie informatiche», entrambi L-31) e materie scritte in due modi
(«Programmazione 1» e «PROGRAMMAZIONE I E LABORATORIO»).

L'unione sposta tutto ciò che è collegato alla materia doppia (file, quiz,
calendario, dizionario, gruppi…) sulla materia da tenere, poi disattiva la
doppia. Avviene in una sola transazione per coppia: se una tabella non accetta
lo spostamento, quella coppia resta com'era. Nessuna migrazione.
"""
import json
import re
import unicodedata

from sqlalchemy import inspect, text
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from models.public_material import PublicMaterial
from models.subject import Subject
from services.admin_material_storage import record_storage_event

STOP = {'e', 'di', 'del', 'della', 'dei', 'degli', 'and', 'the', 'of', 'per', 'a', 'in', 'la', 'il', 'lo',
        'laboratorio', 'laboratory', 'lab'}
ROMAN = {'i': '1', 'ii': '2', 'iii': '3', 'iv': '4'}
SYNONYMS = {'database': ['basi', 'dati'], 'db': ['basi', 'dati']}


def _tokens(name: str):
    text_ = unicodedata.normalize('NFKD', name or '').encode('ascii', 'ignore').decode().lower()
    words = re.findall(r'[a-z0-9]+', text_)
    out = []
    for i, w in enumerate(words):
        if w in SYNONYMS:
            out.extend(SYNONYMS[w])
            continue
        # «i», «ii» come numeri solo dopo la prima parola (Programmazione I)
        if i > 0 and w in ROMAN:
            w = ROMAN[w]
        if w not in STOP:
            out.append(w)
    return out


def _match(a: str, b: str) -> bool:
    if a == b or a.startswith(b) or b.startswith(a):
        return True
    common = 0
    for x, y in zip(a, b):
        if x != y:
            break
        common += 1
    return common >= max(4, int(0.8 * min(len(a), len(b))))


def similarity(a: str, b: str):
    ta, tb = _tokens(a), _tokens(b)
    if not ta or not tb:
        return 0.0, 0
    short, long_ = (ta, tb) if len(ta) <= len(tb) else (tb, ta)
    used, matched = set(), 0
    for t in short:
        for j, u in enumerate(long_):
            if j not in used and _match(t, u):
                used.add(j)
                matched += 1
                break
    # i numeri devono coincidere (Programmazione 1 ≠ Programmazione 2)
    nums_a = {t for t in ta if t.isdigit()}
    nums_b = {t for t in tb if t.isdigit()}
    if nums_a != nums_b and nums_a and nums_b:
        return 0.0, 0
    return matched / len(short), matched


def _references(db: Session):
    """(tabella, colonna) che puntano a subjects.id, letti dal database."""
    insp = inspect(db.get_bind())
    refs = set()
    for table in insp.get_table_names():
        if table == 'subjects':
            continue
        for fk in insp.get_foreign_keys(table):
            if fk.get('referred_table') == 'subjects' and fk.get('referred_columns') == ['id']:
                refs.update((table, col) for col in fk.get('constrained_columns') or [])
        for col in insp.get_columns(table):
            if col['name'] == 'subject_id':
                refs.add((table, col['name']))
    return sorted(refs)


def reference_counts(db: Session, subject_id: int, refs=None):
    counts = {}
    for table, col in refs or _references(db):
        n = db.execute(text(f'SELECT count(*) FROM "{table}" WHERE "{col}" = :sid'),
                       {'sid': subject_id}).scalar() or 0
        if n:
            counts[table] = counts.get(table, 0) + int(n)
    return counts


def _view(db, s, refs):
    files = db.query(PublicMaterial.id).filter(PublicMaterial.subject_id == s.id,
                                              PublicMaterial.status != 'removed').count()
    return {'id': s.id, 'name': s.name, 'course': s.course, 'course_code': s.course_code or '',
            'department': s.department, 'university': s.university, 'study_year': s.study_year,
            'degree_type': s.degree_type, 'files': files,
            'linked': reference_counts(db, s.id, refs) if refs is not None else {}}


def find_duplicates(db: Session):
    """Corsi con lo stesso codice ma nome diverso: per le materie del nome «minore»
    propone la materia corrispondente del nome principale."""
    refs = _references(db)
    subjects = db.query(Subject).filter(Subject.is_active.is_(True)).all()
    groups = {}
    for s in subjects:
        code = (s.course_code or '').strip().upper()
        if not code:
            continue
        groups.setdefault(((s.university or '').lower(), (s.department or '').lower(), code), []).append(s)
    result = []
    for (_, _, code), items in groups.items():
        names = {}
        for s in items:
            names.setdefault(s.course or '', []).append(s)
        if len(names) < 2:
            continue
        # nome principale: quello con più file, poi con più materie
        def weight(name):
            ids = [s.id for s in names[name]]
            files = db.query(PublicMaterial.id).filter(PublicMaterial.subject_id.in_(ids)).count()
            return (files, len(ids))
        main = max(names, key=weight)
        targets = names[main]
        for name, subs in names.items():
            if name == main:
                continue
            for s in subs:
                best, best_key = None, (0.0, 0)
                for t in targets:
                    score, matched = similarity(s.name, t.name)
                    if score >= 0.75 and (score, matched) > best_key:
                        best, best_key = t, (score, matched)
                result.append({
                    'course_code': code, 'main_course': main, 'other_course': name,
                    'duplicate': _view(db, s, refs),
                    'suggested': _view(db, best, None) if best else None,
                    'score': round(best_key[0], 2),
                    'options': [{'id': t.id, 'name': t.name, 'study_year': t.study_year} for t in
                                sorted(targets, key=lambda t: (t.name or '').lower())],
                })
    result.sort(key=lambda r: (r['course_code'], (r['duplicate']['name'] or '').lower()))
    return {'items': result}


def merge_subject(db: Session, actor, from_id: int, into_id: int | None):
    """Sposta i collegamenti da from_id a into_id e disattiva from_id.
    Con into_id = None la materia si disattiva solo se non ha nulla di collegato."""
    source = db.query(Subject).filter(Subject.id == from_id).first()
    if source is None:
        raise ValueError('Materia non trovata.')
    refs = _references(db)
    moved = {}
    if into_id is None:
        linked = reference_counts(db, from_id, refs)
        if linked:
            raise ValueError(f'«{source.name}» ha elementi collegati: scegli in quale materia spostarli.')
    else:
        target = db.query(Subject).filter(Subject.id == into_id, Subject.is_active.is_(True)).first()
        if target is None or target.id == source.id:
            raise ValueError('Materia di destinazione non valida.')
        insp = inspect(db.get_bind())
        try:
            for table, col in refs:
                has_id = any(c['name'] == 'id' for c in insp.get_columns(table))
                ids = [r[0] for r in db.execute(text(f'SELECT id FROM "{table}" WHERE "{col}" = :sid'),
                                                {'sid': from_id}).fetchall()] if has_id else []
                result = db.execute(text(f'UPDATE "{table}" SET "{col}" = :into WHERE "{col}" = :sid'),
                                    {'into': into_id, 'sid': from_id})
                if result.rowcount:
                    moved[table] = {'rows': result.rowcount, 'ids': ids[:500]}
        except IntegrityError as exc:
            db.rollback()
            from services.diagnostics import record
            record('SUBJ-01', area='catalogo', actor_id=actor.id,
                   technical={'step': 'unione materie', 'from_id': from_id, 'into_id': into_id,
                              'error': str(getattr(exc, 'orig', exc))[:300]})
            raise ValueError(f'«{source.name}»: alcuni elementi esistono già nella materia di destinazione. '
                             'Nessuna modifica fatta per questa materia (dettagli nel registro diagnostico).') from exc
    source.is_active = False
    record_storage_event(db, source='subject_merge', material_id=None, action='merged' if into_id else 'deactivated',
                         actor_id=actor.id, original_name=(source.name or '')[:255],
                         details={'from_id': from_id, 'into_id': into_id, 'moved': moved}, commit=False)
    try:
        db.commit()
    except IntegrityError as exc:
        db.rollback()
        raise ValueError(f'«{source.name}»: alcuni elementi esistono già nella materia di destinazione. '
                         'Nessuna modifica fatta per questa materia.') from exc
    return {'from_id': from_id, 'into_id': into_id, 'moved': {k: v['rows'] for k, v in moved.items()}}


def merge_many(db: Session, actor, pairs):
    done, errors = [], []
    for pair in pairs[:200]:
        try:
            done.append(merge_subject(db, actor, int(pair['from_id']),
                                      int(pair['into_id']) if pair.get('into_id') else None))
        except ValueError as exc:
            db.rollback()
            errors.append({'from_id': pair.get('from_id'), 'reason': str(exc)})
        except Exception:
            db.rollback()
            errors.append({'from_id': pair.get('from_id'), 'reason': 'Unione non riuscita: nessuna modifica fatta.'})
    return {'merged': done, 'errors': errors}

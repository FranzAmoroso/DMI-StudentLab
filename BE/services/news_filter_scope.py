"""Known aliases for the academic paths used by public notices."""
import re
import unicodedata

from sqlalchemy import or_


COURSES = {
    'L-31': ('DMI', ('Informatica L-31', 'L-31 Informatica', 'Informatica',
                     'Scienze e Tecnologie Informatiche')),
    'LM-18': ('DMI', ('Informatica magistrale (LM-18)', 'Informatica magistrale')),
    'L-35': ('DMI', ('Matematica L-35', 'L-35 Matematica', 'Matematica')),
    'LM-40': ('DMI', ('Matematica magistrale (LM-40)', 'Matematica magistrale')),
    'L-13': ('DSBGA', ('Scienze Biologiche L-13', 'Scienze Biologiche')),
}
DEPARTMENTS = {
    'DMI': ('Dipartimento di Matematica e Informatica',),
    'DSBGA': ('Dipartimento di Scienze Biologiche, Geologiche e Ambientali',),
}
UNIVERSITIES = {'UNICT': ('Università di Catania', 'Università degli Studi di Catania')}


def _key(value: str) -> str:
    folded = unicodedata.normalize('NFKD', value.casefold())
    return re.sub(r'[^a-z0-9]+', ' ', ''.join(c for c in folded if not unicodedata.combining(c))).strip()


def code(value: str, dimension: str) -> str | None:
    options = {'course': COURSES, 'department': DEPARTMENTS, 'university': UNIVERSITIES}[dimension]
    normalized = _key(value)
    for name, entries in options.items():
        if normalized in {_key(item) for item in (name, *(entries[1] if dimension == 'course' else entries))}:
            return name
    return None


def matches(name_column, code_column, value: str, dimension: str):
    known = code(value, dimension)
    if known is None:
        # Unknown manually entered courses must never silently match L-31.
        return name_column.ilike(value.strip())
    options = {'course': COURSES, 'department': DEPARTMENTS, 'university': UNIVERSITIES}[dimension]
    aliases = options[known][1] if dimension == 'course' else options[known]
    return or_(code_column.ilike(known), *(name_column.ilike(alias) for alias in (known, *aliases)))

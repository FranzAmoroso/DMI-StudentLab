import hashlib
import hmac
import os
from datetime import datetime
from urllib.parse import urlsplit

from fastapi import APIRouter, Depends, Header, HTTPException, Query
from sqlalchemy.orm import Session

from core.database import get_db
from models.dmi_external_notice import DmiExternalNotice, utc_now
from schemas.dmi_external_notice import DmiNoticeResponse, DmiNoticeSyncRequest


router = APIRouter(prefix="/institutional-notices", tags=["Institutional notices"])

SOURCES = {
    ("www.unict.it", "/it/news/"): ("ateneo", None, None),
    ("web.dmi.unict.it", "/corsi/l-31/avvisi/"): ("corso", "DMI", "L-31"),
    ("web.dmi.unict.it", "/corsi/l-31/avvisi-docente/"): ("docente", "DMI", "L-31"),
    ("web.dmi.unict.it", "/corsi/l-35/avvisi/"): ("corso", "DMI", "L-35"),
    ("web.dmi.unict.it", "/corsi/l-35/avvisi-docente/"): ("docente", "DMI", "L-35"),
    ("web.dmi.unict.it", "/corsi/lm-40/avvisi/"): ("corso", "DMI", "LM-40"),
    ("web.dmi.unict.it", "/corsi/lm-40/avvisi-docente/"): ("docente", "DMI", "LM-40"),
    ("web.dmi.unict.it", "/corsi/lm-18/avvisi/"): ("corso", "DMI", "LM-18"),
    ("web.dmi.unict.it", "/corsi/lm-18/avvisi-docente/"): ("docente", "DMI", "LM-18"),
    ("www.dsbga.unict.it", "/corsi/l-13/avvisi/"): ("corso", "DSBGA", "L-13"),
    ("www.dsbga.unict.it", "/corsi/l-13/avvisi-docente/"): ("docente", "DSBGA", "L-13"),
}


def _scope(value: str, dimension: str = "course") -> str:
    import re
    text = value.casefold()
    if dimension == "department":
        if "dsbga" in text or "scienze biologiche" in text or "dipbiogeo" in text:
            return "dsbga"
        if "dmi" in text or "matematica" in text:
            return "dmi"
        return text.strip()
    if dimension == "university":
        return "unict" if "catania" in text or "unict" in text else text.strip()
    if re.search(r"\blm[\s-]*40\b", text) or ("matematica" in text and "magistrale" in text):
        return "lm-40"
    if re.search(r"\blm[\s-]*18\b", text) or ("informatica" in text and "magistrale" in text):
        return "lm-18"
    match = re.search(r"\bl[\s-]*(31|35|13)\b", text)
    if match:
        return f"l-{match.group(1)}"
    if "informatica" in text:
        return "l-31"
    if "matematica" in text and "informatica" not in text:
        return "l-35"
    if "scienze biologiche" in text:
        return "l-13"
    if "dsbga" in text or "scienze biologiche" in text or "dipbiogeo" in text:
        return "dsbga"
    if "dmi" in text or "matematica" in text:
        return "dmi"
    if "catania" in text or "unict" in text:
        return "unict"
    return text.strip()


@router.get("", response_model=list[DmiNoticeResponse])
def list_notices(limit: int = Query(default=200, ge=1, le=500),
                 university: str | None = None, department: str | None = None,
                 course: str | None = None, db: Session = Depends(get_db)):
    rows = (db.query(DmiExternalNotice)
            .order_by(DmiExternalNotice.published_on.desc(), DmiExternalNotice.id.desc())
            .limit(limit).all())
    if university and _scope(university, "university") != "unict":
        return []
    if not department and not course:
        return [row for row in rows if row.department is None]
    return [row for row in rows if row.department is None or
            (not department or _scope(department, "department") == _scope(row.department or "", "department")) and
            (not course or row.course is None or _scope(course) == _scope(row.course))]


@router.get("/sources")
def notice_sources():
    return [{"university": "Università di Catania", "department": department, "course": course}
            for _, department, course in dict.fromkeys(SOURCES.values())]


@router.post("/sync")
def sync_notices(request: DmiNoticeSyncRequest,
                 token: str | None = Header(default=None, alias="X-StudentLab-Sync-Token"),
                 db: Session = Depends(get_db)):
    expected = os.getenv("STUDENTLAB_NOTICE_SYNC_TOKEN", "")
    if not expected or not token or not hmac.compare_digest(token, expected):
        raise HTTPException(403, "Sincronizzazione non autorizzata.")

    prepared = {}
    for item in request.notices:
        url = item.url.strip()
        parts = urlsplit(url)
        if parts.scheme != "https" or parts.username or parts.password or parts.port not in (None, 443):
            raise HTTPException(422, "Fonte dell'avviso non valida.")
        path = parts.path.lower().removeprefix("/it/corsi/")
        if path != parts.path.lower():
            path = "/corsi/" + path
        match = next(((kind, dep, crs) for (host, prefix), (kind, dep, crs) in SOURCES.items()
                      if parts.hostname == host and path.startswith(prefix)), None)
        if match is None or item.fonte != match[0] or not parts.path.strip("/").split("/")[-1]:
            raise HTTPException(422, "Percorso dell'avviso non valido.")
        try:
            published = datetime.strptime(item.data, "%d/%m/%Y").date()
        except ValueError as exc:
            raise HTTPException(422, "Data dell'avviso non valida.") from exc
        canonical_url = f"https://{parts.hostname}{parts.path}"
        original_url = canonical_url + (f"?{parts.query}" if parts.query else "")
        external_id = hashlib.sha256(canonical_url.encode()).hexdigest()
        title = " ".join(item.titolo.split())[:160]
        content = " ".join(item.testo.split())[:30000]
        content_hash = hashlib.sha256(f"{title}|{content}".encode()).hexdigest()
        prepared[external_id] = dict(external_id=external_id, source_kind=item.fonte,
                                     university="Università di Catania", department=match[1], course=match[2],
                                     title=title, content=content,
                                     teacher=item.docente.strip() if item.docente else None,
                                     category=item.tipo, published_on=published,
                                     original_url=original_url, content_hash=content_hash)

    inserted = updated = 0
    seen_at = utc_now()
    try:
        existing = {row.external_id: row for row in db.query(DmiExternalNotice)
                    .filter(DmiExternalNotice.external_id.in_(prepared)).all()} if prepared else {}
        for external_id, values in prepared.items():
            row = existing.get(external_id)
            if row is None:
                db.add(DmiExternalNotice(**values, created_at=seen_at, updated_at=seen_at, last_seen_at=seen_at))
                inserted += 1
                continue
            if any(getattr(row, field) != value for field, value in values.items() if field != "external_id"):
                for field, value in values.items():
                    setattr(row, field, value)
                row.updated_at = seen_at
                updated += 1
            row.last_seen_at = seen_at
        db.commit()
    except Exception:
        db.rollback()
        raise
    return {"received": len(prepared), "inserted": inserted, "updated": updated}

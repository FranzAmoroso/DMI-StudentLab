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


@router.get("", response_model=list[DmiNoticeResponse])
def list_notices(limit: int = Query(default=100, ge=1, le=200), db: Session = Depends(get_db)):
    return (db.query(DmiExternalNotice)
            .order_by(DmiExternalNotice.published_on.desc(), DmiExternalNotice.id.desc())
            .limit(limit).all())


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
        if parts.scheme != "https" or parts.hostname != "web.dmi.unict.it" or parts.username or parts.password:
            raise HTTPException(422, "Fonte dell'avviso non valida.")
        path = parts.path.lower()
        if item.fonte == "corso" and not (path.startswith("/corsi/l-31/avvisi/") or path.startswith("/it/corsi/l-31/avvisi/")):
            raise HTTPException(422, "Percorso dell'avviso non valido.")
        if item.fonte == "docente" and "/avvisi-docente/" not in path:
            raise HTTPException(422, "Percorso docente non valido.")
        try:
            published = datetime.strptime(item.data, "%d/%m/%Y").date()
        except ValueError as exc:
            raise HTTPException(422, "Data dell'avviso non valida.") from exc
        canonical_url = f"https://web.dmi.unict.it{parts.path}"
        original_url = canonical_url + (f"?{parts.query}" if parts.query else "")
        external_id = hashlib.sha256(canonical_url.encode()).hexdigest()
        title = " ".join(item.titolo.split())[:160]
        content = " ".join(item.testo.split())[:30000]
        content_hash = hashlib.sha256(f"{title}|{content}".encode()).hexdigest()
        prepared[external_id] = dict(external_id=external_id, source_kind=item.fonte,
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

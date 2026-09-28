from datetime import date, datetime
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field


class DmiNoticeImport(BaseModel):
    fonte: Literal["corso", "docente"]
    data: str
    titolo: str = Field(min_length=1, max_length=500)
    testo: str = Field(min_length=1, max_length=50000)
    docente: str | None = Field(default=None, max_length=255)
    tipo: str = Field(default="altro", max_length=40)
    url: str = Field(min_length=1, max_length=2048)


class DmiNoticeSyncRequest(BaseModel):
    notices: list[DmiNoticeImport] = Field(max_length=300)


class DmiNoticeResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    source_kind: str
    title: str
    content: str
    teacher: str | None
    category: str
    published_on: date
    original_url: str
    updated_at: datetime

from datetime import datetime

from typing import Literal

from pydantic import (
    BaseModel,
    Field,
    field_validator,
)


NewsCategory = Literal[
    "avvisi",
    "gruppi",
    "private",
]


def _normalize_text(
    value: str,
    label: str,
) -> str:
    normalized = value.strip()

    if not normalized:
        raise ValueError(
            f"{label} non può essere vuoto.",
        )

    return normalized


class NewsReplyCreate(
    BaseModel,
):
    content: str = Field(
        min_length=1,
        max_length=5000,
    )

    @field_validator(
        "content",
    )
    @classmethod
    def normalize_content(
        cls,
        value: str,
    ) -> str:
        return _normalize_text(
            value,
            "Il contenuto della risposta",
        )


class NewsReplyResponse(
    BaseModel,
):
    id: str
    author_id: int
    author_name: str
    content: str
    created_at: datetime
    write_token: str | None = None


class AvvisoCreate(
    BaseModel,
):
    title: str = Field(
        min_length=1,
        max_length=160,
    )

    content: str = Field(
        min_length=1,
        max_length=5000,
    )

    @field_validator(
        "title",
    )
    @classmethod
    def normalize_title(
        cls,
        value: str,
    ) -> str:
        return _normalize_text(
            value,
            "Il titolo dell'avviso",
        )

    @field_validator(
        "content",
    )
    @classmethod
    def normalize_content(
        cls,
        value: str,
    ) -> str:
        return _normalize_text(
            value,
            "Il contenuto dell'avviso",
        )


class AvvisoResponse(
    BaseModel,
):
    id: str
    author_id: int
    author_name: str
    author_role: str
    title: str
    content: str
    created_at: datetime
    updated_at: datetime
    replies: list[NewsReplyResponse] = []
    can_delete: bool = False
    write_token: str | None = None


class AvvisoListResponse(
    BaseModel,
):
    items: list[AvvisoResponse]
    total: int


class GroupNewsFileCreate(
    BaseModel,
):
    content: str = Field(
        min_length=1,
        max_length=5000,
    )

    @field_validator(
        "content",
    )
    @classmethod
    def normalize_content(
        cls,
        value: str,
    ) -> str:
        return _normalize_text(
            value,
            "Il contenuto della news",
        )


class GroupNewsFileResponse(
    BaseModel,
):
    id: str
    group_id: int
    group_name: str
    author_id: int
    author_name: str
    author_role: str
    content: str
    created_at: datetime
    updated_at: datetime
    replies: list[NewsReplyResponse] = []
    can_delete: bool = False
    write_token: str | None = None


class GroupNewsFileListResponse(
    BaseModel,
):
    items: list[GroupNewsFileResponse]
    total: int


class PrivateNewsCreate(
    BaseModel,
):
    recipient_id: int = Field(
        gt=0,
    )

    ciphertext: str = Field(
        min_length=1,
        max_length=200000,
    )

    algo: str = Field(
        min_length=1,
        max_length=64,
    )

    metadata: dict = Field(
        default_factory=dict,
    )

    @field_validator(
        "ciphertext",
    )
    @classmethod
    def normalize_ciphertext(
        cls,
        value: str,
    ) -> str:
        return _normalize_text(
            value,
            "Il contenuto cifrato",
        )

    @field_validator(
        "algo",
    )
    @classmethod
    def normalize_algo(
        cls,
        value: str,
    ) -> str:
        return _normalize_text(
            value,
            "L'algoritmo di cifratura",
        )


class PrivateNewsResponse(
    BaseModel,
):
    id: str
    conversation_id: str
    sender_id: int
    recipient_id: int
    sender_name: str = ""
    recipient_name: str = ""
    algo: str
    ciphertext: str
    metadata: dict = {}
    created_at: datetime
    can_delete: bool = False
    write_token: str | None = None


class PrivateNewsListResponse(
    BaseModel,
):
    items: list[PrivateNewsResponse]
    total: int


class NewsDeleteResponse(
    BaseModel,
):
    success: bool
    message: str
    news_id: str

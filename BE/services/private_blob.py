from fastapi import (
    HTTPException,
)

from fastapi.responses import (
    Response,
)

from vercel.blob import (
    AsyncBlobClient,
)

from core.config import (
    settings,
)


def require_blob_storage():
    if not settings.blob_read_write_token:
        raise HTTPException(
            status_code=503,
            detail=(
                "Il servizio dei materiali "
                "è temporaneamente non disponibile."
            ),
        )


def safe_download_name(
    original_name: str,
) -> str:
    value = (
        original_name
        .replace(
            '"',
            "",
        )
        .replace(
            "\r",
            "",
        )
        .replace(
            "\n",
            "",
        )
        .strip()
    )

    if not value:
        return "materiale"

    return value


async def get_private_blob(
    stored_name: str,
):
    require_blob_storage()

    try:
        async with AsyncBlobClient(
            token=(
                settings.blob_read_write_token
            ),
        ) as client:
            result = await client.get(
                stored_name,
                access="private",
            )

    except Exception as exception:
        raise HTTPException(
            status_code=503,
            detail=(
                "Il file è temporaneamente "
                "non disponibile."
            ),
        ) from exception

    if (
        result is None
        or result.status_code != 200
    ):
        raise HTTPException(
            status_code=404,
            detail="File non disponibile.",
        )

    return result


async def verify_private_blob(
    *,
    stored_name: str,
    expected_size: int,
    expected_mime_type: str,
):
    require_blob_storage()

    try:
        async with AsyncBlobClient(
            token=(
                settings.blob_read_write_token
            ),
        ) as client:
            result = await client.get(
                stored_name,
                access="private",
            )

    except Exception as exception:
        raise HTTPException(
            status_code=400,
            detail=(
                "Il file non risulta caricato "
                "correttamente."
            ),
        ) from exception

    if (
        result is None
        or result.status_code != 200
    ):
        raise HTTPException(
            status_code=400,
            detail=(
                "Il file caricato non è "
                "disponibile."
            ),
        )

    if (
        result.size is not None
        and result.size != expected_size
    ):
        raise HTTPException(
            status_code=400,
            detail=(
                "La dimensione del file "
                "caricato non corrisponde "
                "alla richiesta."
            ),
        )

    if result.content_type is not None:
        actual_content_type = (
            result.content_type
            .split(
                ";",
                1,
            )[0]
            .strip()
            .lower()
        )

        expected_content_type = (
            expected_mime_type
            .strip()
            .lower()
        )

        if (
            actual_content_type
            != expected_content_type
        ):
            raise HTTPException(
                status_code=400,
                detail=(
                    "Il tipo del file caricato "
                    "non corrisponde alla richiesta."
                ),
            )

    return result


async def private_blob_response(
    *,
    stored_name: str,
    original_name: str,
    mime_type: str,
    inline: bool = False,
):
    result = await get_private_blob(
        stored_name,
    )

    disposition = (
        "inline"
        if inline
        else "attachment"
    )

    filename = safe_download_name(
        original_name,
    )

    response_mime_type = (
        result.content_type
        if result.content_type
        else mime_type
    )

    headers = {
        "Content-Disposition": (
            f'{disposition}; '
            f'filename="{filename}"'
        ),
        "X-Content-Type-Options": (
            "nosniff"
        ),
        "Cache-Control": (
            "private, no-store"
        ),
    }

    return Response(
        content=result.content,
        media_type=response_mime_type,
        headers=headers,
    )
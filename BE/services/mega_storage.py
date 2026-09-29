"""Private MEGA worker gateway. The browser only reaches authenticated FastAPI."""
import os
from urllib.parse import urlparse
import httpx
from fastapi import HTTPException


def worker_config():
    url = os.getenv('STUDENTLAB_MEGA_WORKER_URL', '').rstrip('/')
    token = os.getenv('STUDENTLAB_MEGA_WORKER_TOKEN', '')
    parsed = urlparse(url)
    local = parsed.scheme == 'http' and parsed.hostname in {'127.0.0.1', 'localhost'}
    if not url or len(token) < 32:
        raise HTTPException(503, 'Il servizio MEGA deve essere configurato sul server.')
    if (parsed.scheme != 'https' and not local) or parsed.username or parsed.password or parsed.query or parsed.fragment:
        raise HTTPException(503, 'Configurazione del servizio MEGA non valida.')
    return url, token


async def worker(path, *, method='GET', data=None, params=None):
    url, token = worker_config()
    try:
        async with httpx.AsyncClient(timeout=httpx.Timeout(120, connect=10), follow_redirects=False) as client:
            response = await client.request(method, url + path,
                headers={'Authorization': 'Bearer ' + token}, json=data, params=params)
        payload = response.json()
        if response.status_code >= 400:
            detail = payload.get('detail') if isinstance(payload, dict) else None
            raise HTTPException(response.status_code if response.status_code in {400, 404, 409, 413, 429} else 503,
                detail if isinstance(detail, str) else 'Servizio MEGA non disponibile.')
        return payload
    except (httpx.HTTPError, ValueError) as exc:
        raise HTTPException(503, 'Servizio MEGA non raggiungibile. Riprova tra poco.') from exc


async def preview_bytes(file_id):
    url, token = worker_config()
    chunks, total = [], 0
    try:
        async with httpx.AsyncClient(timeout=httpx.Timeout(120, connect=10), follow_redirects=False) as client:
            async with client.stream('GET', url + '/file/' + file_id + '/preview',
                    headers={'Authorization': 'Bearer ' + token}) as response:
                if response.status_code != 200:
                    await response.aread()
                    try:
                        detail = response.json().get('detail', 'File MEGA non disponibile.')
                    except ValueError:
                        detail = 'File MEGA non disponibile.'
                    raise HTTPException(response.status_code if response.status_code in {400, 404, 409, 413} else 503, detail)
                async for chunk in response.aiter_bytes():
                    total += len(chunk)
                    if total > 20 * 1024 * 1024:
                        raise HTTPException(413, 'Anteprima limitata a 20 MB.')
                    chunks.append(chunk)
                return b''.join(chunks), response.headers.get('content-type', 'application/octet-stream')
    except httpx.HTTPError as exc:
        raise HTTPException(503, 'Download MEGA interrotto.') from exc

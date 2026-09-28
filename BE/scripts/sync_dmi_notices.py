"""Import DMI L-31 notices into StudentLab. Run with an hourly external scheduler."""

import os
import sys
from pathlib import Path

import requests

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from services.dmi_notice_scraper import URLS, remove_duplicates, scrape_source  # noqa: E402


def main() -> int:
    endpoint = os.getenv("STUDENTLAB_NOTICE_API_URL", "").strip()
    token = os.getenv("STUDENTLAB_NOTICE_SYNC_TOKEN", "").strip()
    if not endpoint.startswith("https://") or not endpoint.endswith("/institutional-notices/sync") or not token:
        print("Imposta STUDENTLAB_NOTICE_API_URL (HTTPS) e STUDENTLAB_NOTICE_SYNC_TOKEN.", file=sys.stderr)
        return 2

    notices = []
    failed = []
    for source, url in URLS.items():
        try:
            notices.extend(scrape_source(source, url))
        except Exception as exc:
            failed.append(source)
            print(f"Fonte {source} non disponibile: {exc}", file=sys.stderr)
    notices = [item for item in remove_duplicates(notices)
               if item.get("titolo", "").strip() and item.get("testo", "").strip()]
    if not notices:
        print("Nessun avviso estratto: sincronizzazione annullata.", file=sys.stderr)
        return 1

    totals = {"received": 0, "inserted": 0, "updated": 0}
    for index in range(0, len(notices), 100):
        response = requests.post(
            endpoint,
            json={"notices": notices[index:index + 100]},
            headers={"X-StudentLab-Sync-Token": token},
            timeout=45,
        )
        response.raise_for_status()
        result = response.json()
        for key in totals:
            totals[key] += int(result.get(key, 0))
    print(f"Sincronizzati {totals['received']} avvisi; nuovi {totals['inserted']}; aggiornati {totals['updated']}.")
    if failed:
        print(f"Fonti temporaneamente non disponibili: {', '.join(failed)}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())

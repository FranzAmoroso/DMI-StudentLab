from __future__ import annotations

from dataclasses import (
    dataclass,
)

from hashlib import (
    sha256,
)

from pathlib import (
    Path,
)

import os
import subprocess


DEFAULT_IGNORED_DIRECTORIES = {
    ".dart_tool",
    ".git",
    ".idea",
    ".pytest_cache",
    ".venv",
    ".vscode",
    "__pycache__",
    "build",
    "coverage",
    "dist",
    "node_modules",
    "storage",
}

DEFAULT_IGNORED_FILES = {
    ".env",
    ".env.local",
    ".env.production",
    ".env.development",
}

DEFAULT_IGNORED_SUFFIXES = {
    ".db",
    ".sqlite",
    ".sqlite3",
    ".key",
    ".pem",
    ".p12",
    ".pfx",
    ".jks",
    ".keystore",
    ".png",
    ".jpg",
    ".jpeg",
    ".gif",
    ".webp",
    ".ico",
    ".pdf",
    ".zip",
    ".jar",
    ".class",
    ".so",
    ".dll",
    ".dylib",
    ".mp4",
    ".mov",
    ".avi",
}

DEFAULT_SOURCE_SUFFIXES = {
    ".py",
    ".dart",
    ".md",
    ".txt",
    ".json",
    ".yaml",
    ".yml",
    ".toml",
    ".xml",
    ".gradle",
    ".kts",
    ".sql",
    ".html",
    ".css",
    ".js",
    ".ts",
    ".tsx",
    ".jsx",
    ".sh",
}

MAX_INDEXED_FILE_SIZE = (
    2 * 1024 * 1024
)


@dataclass(
    frozen=True,
)
class RepositoryFile:
    path: str
    absolute_path: Path
    size_bytes: int
    modified_at: float
    content_hash: str


def resolve_repository_root() -> Path:
    configured = os.getenv(
        "STUDENTLAB_REPOSITORY_ROOT",
    )

    if configured:
        root = Path(
            configured,
        ).expanduser()
    else:
        root = (
            Path(__file__)
            .resolve()
            .parents[2]
        )

    root = root.resolve()

    if not root.exists():
        raise RuntimeError(
            "Repository StudentLab non trovato.",
        )

    if not root.is_dir():
        raise RuntimeError(
            "Il percorso repository non è "
            "una cartella.",
        )

    return root


def ensure_path_inside_repository(
    repository_root: Path,
    relative_path: str,
) -> Path:
    candidate = (
        repository_root
        / relative_path
    ).resolve()

    try:
        candidate.relative_to(
            repository_root,
        )
    except ValueError as exception:
        raise ValueError(
            "Percorso repository non valido.",
        ) from exception

    return candidate


def should_index_file(
    path: Path,
) -> bool:
    if path.name in DEFAULT_IGNORED_FILES:
        return False

    if path.suffix.lower() in (
        DEFAULT_IGNORED_SUFFIXES
    ):
        return False

    if (
        path.suffix.lower()
        not in DEFAULT_SOURCE_SUFFIXES
        and path.name not in {
            "Dockerfile",
            "Procfile",
        }
    ):
        return False

    try:
        if (
            path.stat().st_size
            > MAX_INDEXED_FILE_SIZE
        ):
            return False
    except OSError:
        return False

    return True


def iter_repository_files(
    repository_root: Path,
) -> list[RepositoryFile]:
    result: list[
        RepositoryFile
    ] = []

    for current_root, directories, names in os.walk(
        repository_root,
    ):
        directories[:] = [
            name
            for name in directories
            if name
            not in DEFAULT_IGNORED_DIRECTORIES
        ]

        current = Path(
            current_root,
        )

        for name in names:
            absolute = current / name

            if not should_index_file(
                absolute,
            ):
                continue

            try:
                raw = absolute.read_bytes()
                stat = absolute.stat()
            except OSError:
                continue

            relative = (
                absolute
                .relative_to(
                    repository_root,
                )
                .as_posix()
            )

            result.append(
                RepositoryFile(
                    path=relative,
                    absolute_path=absolute,
                    size_bytes=stat.st_size,
                    modified_at=stat.st_mtime,
                    content_hash=(
                        sha256(
                            raw,
                        ).hexdigest()
                    ),
                ),
            )

    result.sort(
        key=lambda item: item.path,
    )

    return result


def _run_git(
    repository_root: Path,
    *args: str,
) -> str | None:
    try:
        process = subprocess.run(
            [
                "git",
                "-C",
                str(repository_root),
                *args,
            ],
            capture_output=True,
            text=True,
            timeout=5,
            check=False,
        )
    except (
        OSError,
        subprocess.SubprocessError,
    ):
        return None

    if process.returncode != 0:
        return None

    return process.stdout.strip()


def git_branch(
    repository_root: Path,
) -> str | None:
    value = _run_git(
        repository_root,
        "branch",
        "--show-current",
    )

    return value or None


def git_head_commit(
    repository_root: Path,
) -> str | None:
    value = _run_git(
        repository_root,
        "rev-parse",
        "HEAD",
    )

    return value or None


def git_changed_paths(
    repository_root: Path,
) -> set[str]:
    value = _run_git(
        repository_root,
        "status",
        "--porcelain=v1",
        "-z",
        "--untracked-files=all",
    )

    if not value:
        return set()

    chunks = value.split(
        "\x00",
    )

    changed: set[str] = set()

    for chunk in chunks:
        if not chunk:
            continue

        if len(chunk) < 4:
            continue

        path = chunk[3:]

        if " -> " in path:
            path = path.split(
                " -> ",
                1,
            )[1]

        changed.add(
            path.replace(
                "\\",
                "/",
            ),
        )

    return changed


def git_available(
    repository_root: Path,
) -> bool:
    return (
        _run_git(
            repository_root,
            "rev-parse",
            "--is-inside-work-tree",
        )
        == "true"
    )

from __future__ import annotations

from dataclasses import (
    dataclass,
    field,
)

from pathlib import (
    Path,
)

from typing import (
    Any,
)

import ast
import re

from services.developer_repository import (
    RepositoryFile,
    git_changed_paths,
    iter_repository_files,
    resolve_repository_root,
)


SECURITY_PATH_PATTERNS = (
    "auth",
    "security",
    "permission",
    "role",
    "token",
    "password",
    "secret",
    "oauth",
    "admin",
    "moderation",
    "report",
)

SECURITY_SYMBOL_PATTERNS = (
    "authenticate",
    "authorize",
    "permission",
    "verified",
    "admin",
    "creator",
    "role",
    "password",
    "token",
    "secret",
    "jwt",
    "hmac",
    "hash",
    "login",
    "verify",
)

LAYER_RULES = (
    ("fe/lib", "Frontend"),
    ("BE/routes", "Backend API"),
    ("BE/services", "Backend Service"),
    ("BE/models", "Database Model"),
    ("BE/schemas", "API Schema"),
    ("BE/core", "Core / Infrastructure"),
    ("BE/tests", "Tests"),
    ("BE", "Backend"),
)

LANGUAGES = {
    ".py": "Python",
    ".dart": "Dart",
    ".md": "Markdown",
    ".txt": "Text",
    ".json": "JSON",
    ".yaml": "YAML",
    ".yml": "YAML",
    ".toml": "TOML",
    ".xml": "XML",
    ".sql": "SQL",
    ".js": "JavaScript",
    ".ts": "TypeScript",
    ".tsx": "TypeScript",
    ".jsx": "JavaScript",
    ".sh": "Shell",
}


@dataclass
class IndexedFunction:
    id: str
    name: str
    signature: str
    description: str = ""
    line_start: int | None = None
    line_end: int | None = None
    is_async: bool = False
    calls: list[str] = field(
        default_factory=list,
    )
    called_by: list[str] = field(
        default_factory=list,
    )
    flows: list[str] = field(
        default_factory=list,
    )
    security: list[str] = field(
        default_factory=list,
    )
    inputs: list[str] = field(
        default_factory=list,
    )
    outputs: list[str] = field(
        default_factory=list,
    )
    risk: str = "medium"


@dataclass
class IndexedFile:
    id: str
    path: str
    name: str
    extension: str
    language: str
    layer: str
    module: str
    description: str
    importance: str
    documented: bool
    outdated: bool
    changed: bool
    security_critical: bool
    risk: str
    size_bytes: int
    modified_at: float
    content_hash: str
    functions: list[
        IndexedFunction
    ] = field(
        default_factory=list,
    )
    imports: list[str] = field(
        default_factory=list,
    )
    relations: list[
        dict[str, Any]
    ] = field(
        default_factory=list,
    )
    flows: list[str] = field(
        default_factory=list,
    )
    security_notes: list[str] = field(
        default_factory=list,
    )


@dataclass
class ArchitectureIndex:
    repository_root: Path
    files: list[
        IndexedFile
    ]
    changed_paths: set[str]

    @property
    def by_path(
        self,
    ) -> dict[str, IndexedFile]:
        return {
            file.path: file
            for file in self.files
        }


def _node_call_name(
    node: ast.Call,
) -> str | None:
    try:
        return ast.unparse(
            node.func,
        )
    except Exception:
        if isinstance(
            node.func,
            ast.Name,
        ):
            return node.func.id

    return None


def _annotation_text(
    node: ast.AST | None,
) -> str:
    if node is None:
        return ""

    try:
        return ast.unparse(
            node,
        )
    except Exception:
        return ""


def _function_signature(
    node: (
        ast.FunctionDef
        | ast.AsyncFunctionDef
    ),
) -> str:
    arguments: list[str] = []

    positional = list(
        node.args.posonlyargs,
    ) + list(
        node.args.args,
    )

    defaults = (
        [None]
        * (
            len(positional)
            - len(node.args.defaults)
        )
        + list(node.args.defaults)
    )

    for argument, default in zip(
        positional,
        defaults,
    ):
        item = argument.arg

        annotation = _annotation_text(
            argument.annotation,
        )

        if annotation:
            item += (
                f": {annotation}"
            )

        if default is not None:
            try:
                item += (
                    " = "
                    + ast.unparse(
                        default,
                    )
                )
            except Exception:
                item += " = ..."

        arguments.append(
            item,
        )

    if node.args.vararg is not None:
        arguments.append(
            "*"
            + node.args.vararg.arg,
        )

    for argument, default in zip(
        node.args.kwonlyargs,
        node.args.kw_defaults,
    ):
        item = argument.arg

        annotation = _annotation_text(
            argument.annotation,
        )

        if annotation:
            item += (
                f": {annotation}"
            )

        if default is not None:
            try:
                item += (
                    " = "
                    + ast.unparse(
                        default,
                    )
                )
            except Exception:
                item += " = ..."

        arguments.append(
            item,
        )

    if node.args.kwarg is not None:
        arguments.append(
            "**"
            + node.args.kwarg.arg,
        )

    return_annotation = (
        _annotation_text(
            node.returns,
        )
    )

    signature = (
        f"{node.name}("
        + ", ".join(
            arguments,
        )
        + ")"
    )

    if return_annotation:
        signature += (
            f" -> {return_annotation}"
        )

    return signature


def _python_functions(
    path: str,
    text: str,
) -> tuple[
    list[IndexedFunction],
    list[str],
]:
    try:
        tree = ast.parse(
            text,
        )
    except SyntaxError:
        return (
            [],
            [],
        )

    functions: list[
        IndexedFunction
    ] = []

    imports: list[str] = []

    for node in ast.walk(
        tree,
    ):
        if isinstance(
            node,
            ast.Import,
        ):
            for alias in node.names:
                imports.append(
                    alias.name,
                )

        elif isinstance(
            node,
            ast.ImportFrom,
        ):
            module = (
                node.module
                or ""
            )

            for alias in node.names:
                imports.append(
                    (
                        f"{module}.{alias.name}"
                        if module
                        else alias.name
                    ),
                )

    for node in tree.body:
        if not isinstance(
            node,
            (
                ast.FunctionDef,
                ast.AsyncFunctionDef,
            ),
        ):
            continue

        calls: list[str] = []

        for child in ast.walk(
            node,
        ):
            if not isinstance(
                child,
                ast.Call,
            ):
                continue

            name = _node_call_name(
                child,
            )

            if (
                name
                and name not in calls
            ):
                calls.append(
                    name,
                )

        security: list[str] = []

        haystack = (
            node.name
            + " "
            + " ".join(
                calls,
            )
        ).lower()

        for keyword in (
            SECURITY_SYMBOL_PATTERNS
        ):
            if keyword in haystack:
                security.append(
                    keyword,
                )

        inputs = [
            argument.arg
            for argument in (
                list(
                    node.args.posonlyargs,
                )
                + list(
                    node.args.args,
                )
                + list(
                    node.args.kwonlyargs,
                )
            )
            if argument.arg
            not in {
                "self",
                "cls",
            }
        ]

        risk = (
            "critical"
            if any(
                keyword
                in haystack
                for keyword in (
                    "password",
                    "token",
                    "secret",
                    "authenticate",
                    "login",
                )
            )
            else "high"
            if security
            else "medium"
        )

        functions.append(
            IndexedFunction(
                id=(
                    f"{path}::{node.name}"
                ),
                name=node.name,
                signature=(
                    _function_signature(
                        node,
                    )
                ),
                description=(
                    ast.get_docstring(
                        node,
                    )
                    or ""
                ),
                line_start=node.lineno,
                line_end=getattr(
                    node,
                    "end_lineno",
                    node.lineno,
                ),
                is_async=isinstance(
                    node,
                    ast.AsyncFunctionDef,
                ),
                calls=calls,
                security=security,
                inputs=inputs,
                outputs=(
                    [
                        _annotation_text(
                            node.returns,
                        ),
                    ]
                    if node.returns
                    is not None
                    else []
                ),
                risk=risk,
            ),
        )

    return (
        functions,
        sorted(
            set(
                imports,
            ),
        ),
    )


_DART_FUNCTION_PATTERN = re.compile(
    r"(?m)^[ \t]*"
    r"(?:Future<[^>]+>|Future<void>|"
    r"Future|void|bool|int|double|String|"
    r"Widget|Map<[^>]+>|List<[^>]+>|"
    r"[A-Z][A-Za-z0-9_<>?, ]*)"
    r"[ \t]+"
    r"([a-zA-Z_][a-zA-Z0-9_]*)"
    r"[ \t]*\(([^)]*)\)"
)


def _dart_functions(
    path: str,
    text: str,
) -> tuple[
    list[IndexedFunction],
    list[str],
]:
    functions: list[
        IndexedFunction
    ] = []

    for match in (
        _DART_FUNCTION_PATTERN
        .finditer(
            text,
        )
    ):
        name = match.group(
            1,
        )

        signature = (
            f"{name}("
            f"{match.group(2).strip()}"
            ")"
        )

        line_start = (
            text.count(
                "\n",
                0,
                match.start(),
            )
            + 1
        )

        haystack = (
            name.lower()
        )

        security = [
            keyword
            for keyword in (
                SECURITY_SYMBOL_PATTERNS
            )
            if keyword in haystack
        ]

        functions.append(
            IndexedFunction(
                id=(
                    f"{path}::{name}"
                ),
                name=name,
                signature=signature,
                line_start=line_start,
                line_end=line_start,
                security=security,
                risk=(
                    "high"
                    if security
                    else "medium"
                ),
            ),
        )

    imports = re.findall(
        r"""(?m)^\s*import\s+['"]([^'"]+)['"]""",
        text,
    )

    return (
        functions,
        sorted(
            set(
                imports,
            ),
        ),
    )


def _layer_for_path(
    path: str,
) -> str:
    for prefix, layer in (
        LAYER_RULES
    ):
        if path.startswith(
            prefix,
        ):
            return layer

    return "Repository"


def _module_for_path(
    path: str,
) -> str:
    parts = Path(
        path,
    ).parts

    if len(parts) <= 1:
        return "Root"

    if parts[0] == "BE":
        if len(parts) >= 2:
            return parts[1]

    if (
        len(parts) >= 3
        and parts[0] == "fe"
        and parts[1] == "lib"
    ):
        return parts[2]

    return parts[
        max(
            0,
            len(parts) - 2,
        )
    ]


def _documentation_candidates(
    repository_root: Path,
    source_path: str,
) -> list[Path]:
    safe = (
        source_path
        .replace(
            "/",
            "__",
        )
    )

    source = (
        repository_root
        / source_path
    )

    return [
        source.with_suffix(
            source.suffix
            + ".md",
        ),
        source.with_suffix(
            source.suffix
            + ".txt",
        ),
        repository_root
        / "docs"
        / "architecture"
        / "files"
        / f"{safe}.md",
        repository_root
        / "docs"
        / "architecture"
        / "files"
        / f"{safe}.txt",
    ]


def _documentation_state(
    repository_root: Path,
    file: RepositoryFile,
) -> tuple[
    bool,
    bool,
]:
    existing = [
        path
        for path in (
            _documentation_candidates(
                repository_root,
                file.path,
            )
        )
        if path.exists()
        and path.is_file()
    ]

    if not existing:
        return (
            False,
            False,
        )

    latest_documentation = max(
        path.stat().st_mtime
        for path in existing
    )

    return (
        True,
        file.modified_at
        > latest_documentation,
    )


def _security_critical(
    path: str,
    functions: list[
        IndexedFunction
    ],
) -> bool:
    normalized = path.lower()

    if any(
        keyword in normalized
        for keyword in (
            SECURITY_PATH_PATTERNS
        )
    ):
        return True

    return any(
        function.security
        for function in functions
    )


def _description_for(
    path: str,
    layer: str,
    function_count: int,
) -> str:
    return (
        f"{layer}: {path}. "
        f"Contiene {function_count} "
        "funzioni indicizzate."
    )


def _importance_for(
    security_critical: bool,
    layer: str,
) -> str:
    if security_critical:
        return (
            "Nodo sensibile: modifiche possono "
            "influire su autenticazione, "
            "autorizzazioni o protezione dati."
        )

    if layer in {
        "Backend API",
        "Backend Service",
        "Database Model",
    }:
        return (
            "Nodo applicativo backend: "
            "verificare chiamanti, dati e "
            "contratti prima delle modifiche."
        )

    if layer == "Frontend":
        return (
            "Nodo frontend: verificare "
            "navigazione, stato e contratti API."
        )

    return (
        "Nodo del repository indicizzato "
        "dalla Developer Area."
    )


def build_architecture_index(
) -> ArchitectureIndex:
    repository_root = (
        resolve_repository_root()
    )

    changed_paths = (
        git_changed_paths(
            repository_root,
        )
    )

    indexed: list[
        IndexedFile
    ] = []

    for repository_file in (
        iter_repository_files(
            repository_root,
        )
    ):
        try:
            text = (
                repository_file
                .absolute_path
                .read_text(
                    encoding="utf-8",
                    errors="replace",
                )
            )
        except OSError:
            continue

        suffix = (
            repository_file
            .absolute_path
            .suffix
            .lower()
        )

        if suffix == ".py":
            functions, imports = (
                _python_functions(
                    repository_file.path,
                    text,
                )
            )
        elif suffix == ".dart":
            functions, imports = (
                _dart_functions(
                    repository_file.path,
                    text,
                )
            )
        else:
            functions = []
            imports = []

        layer = _layer_for_path(
            repository_file.path,
        )

        documented, outdated = (
            _documentation_state(
                repository_root,
                repository_file,
            )
        )

        security_critical = (
            _security_critical(
                repository_file.path,
                functions,
            )
        )

        risk = (
            "critical"
            if security_critical
            else "high"
            if layer
            in {
                "Backend API",
                "Database Model",
            }
            else "medium"
        )

        security_notes: list[str] = []

        if security_critical:
            security_notes.append(
                "File classificato "
                "security-critical "
                "dall'indicizzatore."
            )

        indexed.append(
            IndexedFile(
                id=repository_file.path,
                path=repository_file.path,
                name=(
                    repository_file
                    .absolute_path
                    .name
                ),
                extension=suffix,
                language=(
                    LANGUAGES.get(
                        suffix,
                        "Unknown",
                    )
                ),
                layer=layer,
                module=_module_for_path(
                    repository_file.path,
                ),
                description=(
                    _description_for(
                        repository_file.path,
                        layer,
                        len(
                            functions,
                        ),
                    )
                ),
                importance=(
                    _importance_for(
                        security_critical,
                        layer,
                    )
                ),
                documented=documented,
                outdated=outdated,
                changed=(
                    repository_file.path
                    in changed_paths
                ),
                security_critical=(
                    security_critical
                ),
                risk=risk,
                size_bytes=(
                    repository_file
                    .size_bytes
                ),
                modified_at=(
                    repository_file
                    .modified_at
                ),
                content_hash=(
                    repository_file
                    .content_hash
                ),
                functions=functions,
                imports=imports,
                security_notes=(
                    security_notes
                ),
            ),
        )

    index = ArchitectureIndex(
        repository_root=repository_root,
        files=indexed,
        changed_paths=changed_paths,
    )

    _link_internal_calls(
        index,
    )

    _build_relations(
        index,
    )

    return index


def _link_internal_calls(
    index: ArchitectureIndex,
) -> None:
    functions_by_name: dict[
        str,
        list[
            tuple[
                IndexedFile,
                IndexedFunction,
            ]
        ],
    ] = {}

    for file in index.files:
        for function in file.functions:
            functions_by_name.setdefault(
                function.name,
                [],
            ).append(
                (
                    file,
                    function,
                ),
            )

    for caller_file in index.files:
        for caller in (
            caller_file.functions
        ):
            for raw_call in caller.calls:
                short = (
                    raw_call
                    .split(".")[-1]
                )

                targets = (
                    functions_by_name.get(
                        short,
                        [],
                    )
                )

                if not targets:
                    continue

                for target_file, target in (
                    targets
                ):
                    reference = (
                        f"{caller_file.path} "
                        f"→ {caller.name}"
                    )

                    if (
                        reference
                        not in target.called_by
                    ):
                        target.called_by.append(
                            reference,
                        )


def _module_to_path(
    module: str,
) -> str:
    if module.startswith(
        "package:",
    ):
        return module

    normalized = (
        module.split(
            ".",
        )
    )

    return "/".join(
        normalized,
    )


def _build_relations(
    index: ArchitectureIndex,
) -> None:
    available = {
        file.path
        for file in index.files
    }

    for file in index.files:
        relations: list[
            dict[str, Any]
        ] = []

        for imported in file.imports:
            target = (
                _module_to_path(
                    imported,
                )
            )

            candidates = [
                f"BE/{target}.py",
                f"{target}.py",
                f"{target}.dart",
            ]

            if target.startswith(
                "package:",
            ):
                continue

            resolved = next(
                (
                    candidate
                    for candidate in candidates
                    if candidate in available
                ),
                None,
            )

            if resolved is None:
                continue

            relations.append(
                {
                    "type": "imports",
                    "label": imported,
                    "target_path": resolved,
                    "target_function": None,
                },
            )

        file.relations = relations


def get_indexed_file(
    index: ArchitectureIndex,
    path: str,
) -> IndexedFile | None:
    return index.by_path.get(
        path,
    )

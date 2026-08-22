from fastapi import (
    APIRouter,
    Depends,
    HTTPException,
    Query,
)

from models.user import (
    User,
)

from core.developer_security import (
    get_developer_system_user,
)

from schemas.developer_architecture import (
    DeveloperFileResponse,
    DeveloperGraphResponse,
    DeveloperRepositoryStatusResponse,
    DeveloperSearchResultResponse,
    DeveloperTreeNodeResponse,
)

from services.developer_graph import (
    build_graph,
)

from services.developer_indexer import (
    ArchitectureIndex,
    build_architecture_index,
    get_indexed_file,
)

from services.developer_repository import (
    git_available,
    git_branch,
    git_head_commit,
)

from services.developer_search import (
    search_architecture,
)


router = APIRouter(
    prefix="/developer",
    tags=[
        "developer",
    ],
)


def _index() -> ArchitectureIndex:
    try:
        return build_architecture_index()

    except RuntimeError as exception:
        raise HTTPException(
            status_code=503,
            detail=str(
                exception,
            ),
        ) from exception


def _tree_node(
    name: str,
    path: str,
    node_type: str,
    *,
    documented: bool = False,
    outdated: bool = False,
    changed: bool = False,
    security_critical: bool = False,
    function_count: int | None = None,
    children: list[dict] | None = None,
) -> dict:
    return {
        "id": (
            path
            if path
            else "root"
        ),
        "name": name,
        "path": path,
        "type": node_type,
        "documented": documented,
        "outdated": outdated,
        "changed": changed,
        "security_critical": (
            security_critical
        ),
        "function_count": (
            function_count
        ),
        "children": (
            children
            or []
        ),
    }


def _build_tree(
    index: ArchitectureIndex,
) -> dict:
    root = {
        "directories": {},
        "files": {},
    }

    by_path = index.by_path

    for file in index.files:
        parts = file.path.split(
            "/",
        )

        cursor = root

        for part in parts[:-1]:
            cursor = (
                cursor[
                    "directories"
                ]
                .setdefault(
                    part,
                    {
                        "directories": {},
                        "files": {},
                    },
                )
            )

        cursor[
            "files"
        ][
            parts[-1]
        ] = file.path

    def convert(
        node: dict,
        current_path: str,
        display_name: str,
    ) -> dict:
        children: list[
            dict
        ] = []

        for directory_name in sorted(
            node["directories"],
            key=str.lower,
        ):
            child_path = (
                f"{current_path}/"
                f"{directory_name}"
                if current_path
                else directory_name
            )

            children.append(
                convert(
                    node[
                        "directories"
                    ][
                        directory_name
                    ],
                    child_path,
                    directory_name,
                ),
            )

        for file_name in sorted(
            node["files"],
            key=str.lower,
        ):
            file_path = (
                node["files"][
                    file_name
                ]
            )

            file = by_path[
                file_path
            ]

            children.append(
                _tree_node(
                    file_name,
                    file.path,
                    "file",
                    documented=(
                        file.documented
                    ),
                    outdated=(
                        file.outdated
                    ),
                    changed=(
                        file.changed
                    ),
                    security_critical=(
                        file.security_critical
                    ),
                    function_count=len(
                        file.functions,
                    ),
                ),
            )

        return _tree_node(
            display_name,
            current_path,
            "folder",
            children=children,
        )

    return convert(
        root,
        "",
        index.repository_root.name,
    )


def _serialize_function(
    function,
) -> dict:
    return {
        "id": function.id,
        "name": function.name,
        "signature": (
            function.signature
        ),
        "description": (
            function.description
        ),
        "line_start": (
            function.line_start
        ),
        "line_end": (
            function.line_end
        ),
        "is_async": (
            function.is_async
        ),
        "calls": function.calls,
        "called_by": (
            function.called_by
        ),
        "flows": function.flows,
        "security": (
            function.security
        ),
        "inputs": function.inputs,
        "outputs": function.outputs,
        "risk": function.risk,
    }


def _serialize_file(
    file,
) -> dict:
    return {
        "id": file.id,
        "path": file.path,
        "name": file.name,
        "extension": (
            file.extension
        ),
        "language": (
            file.language
        ),
        "layer": file.layer,
        "module": file.module,
        "description": (
            file.description
        ),
        "importance": (
            file.importance
        ),
        "source_type": "local",
        "documented": (
            file.documented
        ),
        "outdated": file.outdated,
        "changed": file.changed,
        "security_critical": (
            file.security_critical
        ),
        "risk": file.risk,
        "size_bytes": (
            file.size_bytes
        ),
        "modified_at": (
            file.modified_at
        ),
        "content_hash": (
            file.content_hash
        ),
        "functions": [
            _serialize_function(
                function,
            )
            for function
            in file.functions
        ],
        "imports": file.imports,
        "relations": (
            file.relations
        ),
        "flows": file.flows,
        "security_notes": (
            file.security_notes
        ),
    }


@router.get(
    "/access",
)
def developer_access(
    current_user: User = Depends(
        get_developer_system_user,
    ),
):
    return {
        "authorized": True,
        "role": current_user.role,
    }


@router.get(
    "/status",
    response_model=(
        DeveloperRepositoryStatusResponse
    ),
)
def developer_status(
    current_user: User = Depends(
        get_developer_system_user,
    ),
):
    index = _index()

    root = index.repository_root

    functions_indexed = sum(
        len(
            file.functions,
        )
        for file in index.files
    )

    return {
        "repository_name": (
            root.name
        ),
        "repository_root": (
            str(root)
        ),
        "source_type": "local",
        "git_available": (
            git_available(
                root,
            )
        ),
        "branch": git_branch(
            root,
        ),
        "head_commit": (
            git_head_commit(
                root,
            )
        ),
        "files_indexed": len(
            index.files,
        ),
        "functions_indexed": (
            functions_indexed
        ),
        "documented_files": sum(
            1
            for file in index.files
            if file.documented
        ),
        "outdated_files": sum(
            1
            for file in index.files
            if file.outdated
        ),
        "changed_files": sum(
            1
            for file in index.files
            if file.changed
        ),
        "security_critical_files": sum(
            1
            for file in index.files
            if file.security_critical
        ),
    }


@router.get(
    "/tree",
    response_model=(
        DeveloperTreeNodeResponse
    ),
)
def developer_tree(
    current_user: User = Depends(
        get_developer_system_user,
    ),
):
    index = _index()

    return _build_tree(
        index,
    )


@router.get(
    "/files",
    response_model=list[
        DeveloperFileResponse
    ],
)
def developer_files(
    current_user: User = Depends(
        get_developer_system_user,
    ),
):
    index = _index()

    return [
        _serialize_file(
            file,
        )
        for file in index.files
    ]


@router.get(
    "/file",
    response_model=(
        DeveloperFileResponse
    ),
)
def developer_file(
    path: str = Query(
        ...,
        min_length=1,
        max_length=600,
    ),
    current_user: User = Depends(
        get_developer_system_user,
    ),
):
    index = _index()

    file = get_indexed_file(
        index,
        path,
    )

    if file is None:
        raise HTTPException(
            status_code=404,
            detail=(
                "File non presente "
                "nell'indice Developer."
            ),
        )

    return _serialize_file(
        file,
    )


@router.get(
    "/search",
    response_model=list[
        DeveloperSearchResultResponse
    ],
)
def developer_search(
    q: str = Query(
        ...,
        min_length=2,
        max_length=200,
    ),
    limit: int = Query(
        30,
        ge=1,
        le=100,
    ),
    current_user: User = Depends(
        get_developer_system_user,
    ),
):
    index = _index()

    return search_architecture(
        index,
        q,
        limit,
    )


@router.get(
    "/graph",
    response_model=(
        DeveloperGraphResponse
    ),
)
def developer_graph(
    current_user: User = Depends(
        get_developer_system_user,
    ),
):
    index = _index()

    return build_graph(
        index,
    )

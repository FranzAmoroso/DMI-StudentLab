from __future__ import annotations

from collections import (
    deque,
)

from services.developer_flows import (
    resolve_flows,
)

from services.developer_indexer import (
    ArchitectureIndex,
    IndexedFile,
    IndexedFunction,
)


RISK_WEIGHT = {
    "low": 1,
    "medium": 2,
    "high": 3,
    "critical": 4,
}


def _function_by_name(
    file: IndexedFile,
    name: str,
) -> IndexedFunction | None:
    normalized = (
        name
        .strip()
        .lower()
    )

    for function in file.functions:
        if (
            function.name.lower()
            == normalized
        ):
            return function

    return None


def _all_functions(
    index: ArchitectureIndex,
) -> list[
    tuple[
        IndexedFile,
        IndexedFunction,
    ]
]:
    return [
        (
            file,
            function,
        )
        for file in index.files
        for function in file.functions
    ]


def _matching_functions(
    index: ArchitectureIndex,
    call_name: str,
) -> list[
    tuple[
        IndexedFile,
        IndexedFunction,
    ]
]:
    short_name = (
        call_name
        .split(".")[-1]
        .strip()
        .lower()
    )

    if not short_name:
        return []

    return [
        (
            file,
            function,
        )
        for file, function
        in _all_functions(
            index,
        )
        if (
            function.name.lower()
            == short_name
        )
    ]


def _direct_callers(
    index: ArchitectureIndex,
    function_name: str,
) -> list[dict]:
    result: list[dict] = []
    target = (
        function_name
        .strip()
        .lower()
    )

    for file, function in (
        _all_functions(
            index,
        )
    ):
        for call in function.calls:
            short_name = (
                call
                .split(".")[-1]
                .strip()
                .lower()
            )

            if short_name != target:
                continue

            result.append(
                {
                    "file":
                        file.path,
                    "function":
                        function.name,
                    "layer":
                        file.layer,
                    "security_critical":
                        (
                            file.security_critical
                            or bool(
                                function.security,
                            )
                        ),
                    "risk":
                        function.risk,
                },
            )

            break

    return result


def _direct_callees(
    index: ArchitectureIndex,
    function: IndexedFunction,
) -> list[dict]:
    result: list[dict] = []
    seen: set[
        tuple[str, str]
    ] = set()

    for call in function.calls:
        matches = _matching_functions(
            index,
            call,
        )

        for file, target in matches:
            key = (
                file.path,
                target.name,
            )

            if key in seen:
                continue

            seen.add(
                key,
            )

            result.append(
                {
                    "file":
                        file.path,
                    "function":
                        target.name,
                    "layer":
                        file.layer,
                    "security_critical":
                        (
                            file.security_critical
                            or bool(
                                target.security,
                            )
                        ),
                    "risk":
                        target.risk,
                },
            )

    return result


def _file_relations(
    index: ArchitectureIndex,
    target_path: str,
) -> list[str]:
    affected: set[str] = set()

    for file in index.files:
        if file.path == target_path:
            continue

        for relation in file.relations:
            relation_target = (
                relation.get(
                    "target_path",
                )
                or relation.get(
                    "target",
                )
            )

            if relation_target == target_path:
                affected.add(
                    file.path,
                )
                break

    return sorted(
        affected,
    )


def _flow_impacts(
    index: ArchitectureIndex,
    path: str,
    function_name: str | None,
) -> list[dict]:
    result: list[dict] = []

    for flow in resolve_flows(
        index,
    ):
        matched_steps = []

        for step in flow[
            "steps"
        ]:
            if (
                step["file"]
                != path
            ):
                continue

            if (
                function_name
                is not None
                and step.get(
                    "function",
                )
                != function_name
            ):
                continue

            matched_steps.append(
                step["order"],
            )

        if not matched_steps:
            continue

        result.append(
            {
                "id":
                    flow["id"],
                "name":
                    flow["name"],
                "risk":
                    flow["risk"],
                "matched_steps":
                    matched_steps,
            },
        )

    return result


def _transitive_callers(
    index: ArchitectureIndex,
    function_name: str,
    *,
    max_depth: int = 3,
) -> list[dict]:
    queue = deque(
        [
            (
                function_name,
                0,
            ),
        ],
    )

    seen_names = {
        function_name.lower(),
    }

    result: list[dict] = []
    seen_nodes: set[
        tuple[str, str]
    ] = set()

    while queue:
        target_name, depth = (
            queue.popleft()
        )

        if depth >= max_depth:
            continue

        callers = _direct_callers(
            index,
            target_name,
        )

        for caller in callers:
            key = (
                caller["file"],
                caller["function"],
            )

            if key in seen_nodes:
                continue

            seen_nodes.add(
                key,
            )

            result.append(
                {
                    **caller,
                    "depth":
                        depth + 1,
                },
            )

            caller_name = (
                caller[
                    "function"
                ]
                .strip()
                .lower()
            )

            if (
                caller_name
                not in seen_names
            ):
                seen_names.add(
                    caller_name,
                )

                queue.append(
                    (
                        caller[
                            "function"
                        ],
                        depth + 1,
                    ),
                )

    return result


def _overall_risk(
    file: IndexedFile,
    function: IndexedFunction | None,
    flow_impacts: list[dict],
    direct_callers: list[dict],
    transitive_callers: list[dict],
) -> str:
    candidates = [
        file.risk,
    ]

    if function is not None:
        candidates.append(
            function.risk,
        )

    candidates.extend(
        flow["risk"]
        for flow in flow_impacts
    )

    candidates.extend(
        caller["risk"]
        for caller
        in direct_callers
    )

    if (
        file.security_critical
        or (
            function is not None
            and bool(
                function.security,
            )
        )
    ):
        candidates.append(
            "critical",
        )

    if len(
        transitive_callers,
    ) >= 8:
        candidates.append(
            "high",
        )

    return max(
        candidates,
        key=lambda item: (
            RISK_WEIGHT.get(
                item,
                2,
            )
        ),
    )


def build_impact_analysis(
    index: ArchitectureIndex,
    *,
    path: str,
    function_name: str | None = None,
) -> dict | None:
    file = index.by_path.get(
        path,
    )

    if file is None:
        return None

    function = None

    if function_name is not None:
        function = _function_by_name(
            file,
            function_name,
        )

        if function is None:
            return None

    direct_callers: list[
        dict
    ] = []

    direct_callees: list[
        dict
    ] = []

    transitive_callers: list[
        dict
    ] = []

    if function is not None:
        direct_callers = (
            _direct_callers(
                index,
                function.name,
            )
        )

        direct_callees = (
            _direct_callees(
                index,
                function,
            )
        )

        transitive_callers = (
            _transitive_callers(
                index,
                function.name,
            )
        )

    flow_impacts = (
        _flow_impacts(
            index,
            file.path,
            (
                function.name
                if function
                is not None
                else None
            ),
        )
    )

    related_files = set(
        _file_relations(
            index,
            file.path,
        ),
    )

    for item in (
        direct_callers
        + direct_callees
        + transitive_callers
    ):
        related_files.add(
            item[
                "file"
            ],
        )

    security_flags = list(
        file.security_notes,
    )

    if function is not None:
        security_flags.extend(
            function.security,
        )

    security_flags = sorted(
        set(
            flag
            for flag
            in security_flags
            if flag
        ),
    )

    overall_risk = (
        _overall_risk(
            file,
            function,
            flow_impacts,
            direct_callers,
            transitive_callers,
        )
    )

    summary_parts = [
        (
            f"{len(direct_callers)} "
            "chiamanti diretti"
        ),
        (
            f"{len(direct_callees)} "
            "dipendenze in uscita"
        ),
        (
            f"{len(flow_impacts)} "
            "flow coinvolti"
        ),
        (
            f"{len(related_files)} "
            "file potenzialmente coinvolti"
        ),
    ]

    return {
        "path":
            file.path,
        "function":
            (
                function.name
                if function is not None
                else None
            ),
        "risk":
            overall_risk,
        "summary":
            ", ".join(
                summary_parts,
            )
            + ".",
        "direct_callers":
            direct_callers,
        "direct_callees":
            direct_callees,
        "transitive_callers":
            transitive_callers,
        "related_files":
            sorted(
                related_files,
            ),
        "flows":
            flow_impacts,
        "security_flags":
            security_flags,
        "security_critical":
            (
                file.security_critical
                or (
                    function is not None
                    and bool(
                        function.security,
                    )
                )
            ),
    }
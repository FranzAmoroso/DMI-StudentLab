from __future__ import annotations

from collections import (
    deque,
)

from pathlib import (
    PurePosixPath,
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


def _normalize_name(
    value: str,
) -> str:
    return (
        value
        .strip()
        .lower()
        .replace("-", "_")
        .replace(" ", "_")
    )


def _function_by_name(
    file: IndexedFile,
    name: str,
) -> IndexedFunction | None:
    normalized = _normalize_name(
        name,
    )

    for function in file.functions:
        if (
            _normalize_name(
                function.name,
            )
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
    short_name = _normalize_name(
        call_name.split(".")[-1],
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
            _normalize_name(
                function.name,
            )
            == short_name
        )
    ]


def _direct_callers(
    index: ArchitectureIndex,
    function_name: str,
) -> list[dict]:
    result: list[dict] = []
    target = _normalize_name(
        function_name,
    )

    for file, function in (
        _all_functions(
            index,
        )
    ):
        for call in function.calls:
            short_name = (
                _normalize_name(
                    call.split(".")[-1],
                )
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
        _normalize_name(
            function_name,
        ),
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
                _normalize_name(
                    caller[
                        "function"
                    ],
                )
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


def _endpoint_refs(
    index: ArchitectureIndex,
    *,
    path: str,
    function: IndexedFunction | None,
    direct_callers: list[dict],
    transitive_callers: list[dict],
) -> list[dict]:
    candidates: set[
        tuple[str, str]
    ] = set()

    if (
        function is not None
        and (
            function.name.startswith(
                "api_",
            )
            or file_is_api(
                path,
            )
        )
    ):
        candidates.add(
            (
                path,
                function.name,
            ),
        )

    for caller in (
        direct_callers
        + transitive_callers
    ):
        caller_function = (
            caller["function"]
        )
        caller_file = (
            caller["file"]
        )

        if (
            caller_function.startswith(
                "api_",
            )
            or file_is_api(
                caller_file,
            )
        ):
            candidates.add(
                (
                    caller_file,
                    caller_function,
                ),
            )

    result: list[dict] = []

    for file_path, function_name in sorted(
        candidates,
    ):
        result.append(
            {
                "file":
                    file_path,
                "function":
                    function_name,
                "method":
                    None,
                "path":
                    None,
                "confidence":
                    "inferred",
            },
        )

    return result


def file_is_api(
    path: str,
) -> bool:
    normalized = (
        path
        .replace("\\", "/")
        .lower()
    )

    return (
        normalized == "be/main.py"
        or "/routes/" in normalized
        or normalized.startswith(
            "be/routes/",
        )
    )


def _model_refs(
    index: ArchitectureIndex,
    *,
    file: IndexedFile,
    function: IndexedFunction | None,
    direct_callees: list[dict],
) -> list[dict]:
    model_paths: set[str] = set()

    def add_model_path(
        value: str,
    ) -> None:
        normalized = (
            value
            .replace("\\", "/")
            .strip()
        )

        if (
            normalized.startswith(
                "BE/models/",
            )
            or "/models/" in normalized
        ):
            model_paths.add(
                normalized,
            )

    for relation in file.relations:
        target = (
            relation.get(
                "target_path",
            )
            or relation.get(
                "target",
            )
            or ""
        )

        if isinstance(
            target,
            str,
        ):
            add_model_path(
                target,
            )

    for imported in file.imports:
        normalized_import = (
            imported
            .replace(".", "/")
            .strip()
        )

        if (
            normalized_import.startswith(
                "models/"
            )
        ):
            candidate = (
                "BE/"
                + normalized_import
                + ".py"
            )

            if candidate in index.by_path:
                model_paths.add(
                    candidate,
                )

    for callee in direct_callees:
        add_model_path(
            callee["file"],
        )

    result: list[dict] = []

    for path in sorted(
        model_paths,
    ):
        model_file = index.by_path.get(
            path,
        )

        result.append(
            {
                "file":
                    path,
                "name":
                    (
                        PurePosixPath(
                            path,
                        ).stem
                    ),
                "layer":
                    (
                        model_file.layer
                        if model_file
                        is not None
                        else "Database Model"
                    ),
                "confidence":
                    "observed",
            },
        )

    return result


def _test_refs(
    index: ArchitectureIndex,
    *,
    target_file: IndexedFile,
    function: IndexedFunction | None,
) -> list[dict]:
    file_stem = _normalize_name(
        PurePosixPath(
            target_file.path,
        ).stem,
    )

    function_name = (
        _normalize_name(
            function.name,
        )
        if function is not None
        else ""
    )

    result: list[dict] = []

    for file in index.files:
        normalized_path = (
            file.path.lower()
        )

        is_test = (
            "/test" in normalized_path
            or "/tests/" in normalized_path
            or normalized_path.startswith(
                "test/"
            )
            or normalized_path.startswith(
                "be/tests/"
            )
            or normalized_path.endswith(
                "_test.dart"
            )
            or PurePosixPath(
                normalized_path,
            ).name.startswith(
                "test_",
            )
        )

        if not is_test:
            continue

        tokens = {
            _normalize_name(
                PurePosixPath(
                    file.path,
                ).stem,
            ),
        }

        tokens.update(
            _normalize_name(
                function_item.name,
            )
            for function_item
            in file.functions
        )

        matches_file = any(
            file_stem
            and file_stem in token
            for token in tokens
        )

        matches_function = any(
            function_name
            and function_name in token
            for token in tokens
        )

        calls_target = False

        if function is not None:
            for test_function in (
                file.functions
            ):
                if any(
                    _normalize_name(
                        call.split(".")[-1],
                    )
                    == function_name
                    for call
                    in test_function.calls
                ):
                    calls_target = True
                    break

        if not (
            matches_file
            or matches_function
            or calls_target
        ):
            continue

        confidence = (
            "observed"
            if calls_target
            else "inferred"
        )

        result.append(
            {
                "file":
                    file.path,
                "confidence":
                    confidence,
                "reason":
                    (
                        "Calls target function."
                        if calls_target
                        else (
                            "Test name matches "
                            "the impacted file/function."
                        )
                    ),
            },
        )

    return result


def _recommendations(
    *,
    file: IndexedFile,
    function: IndexedFunction | None,
    direct_callers: list[dict],
    direct_callees: list[dict],
    flows: list[dict],
    models: list[dict],
    tests: list[dict],
    security_flags: list[str],
) -> list[str]:
    recommendations: list[str] = []

    if direct_callers:
        recommendations.append(
            "Review direct callers before changing "
            "the function contract or return value.",
        )

    if direct_callees:
        recommendations.append(
            "Keep compatibility with outgoing "
            "dependencies or update them together.",
        )

    if flows:
        flow_names = ", ".join(
            flow["name"]
            for flow in flows
        )

        recommendations.append(
            "Retest affected application flows: "
            f"{flow_names}.",
        )

    if models:
        model_names = ", ".join(
            model["name"]
            for model in models
        )

        recommendations.append(
            "Check database/model contracts used by "
            f"this path: {model_names}.",
        )

    if tests:
        recommendations.append(
            "Run and update the related tests "
            "listed in this impact analysis.",
        )
    else:
        recommendations.append(
            "No related test was resolved; consider "
            "adding a focused regression test.",
        )

    if (
        file.security_critical
        or security_flags
        or (
            function is not None
            and function.security
        )
    ):
        recommendations.append(
            "Treat the change as security-sensitive "
            "and verify authorization, validation "
            "and failure paths.",
        )

    return recommendations


def _semantic_answer(
    *,
    file: IndexedFile,
    function: IndexedFunction | None,
    risk: str,
    direct_callers: list[dict],
    direct_callees: list[dict],
    flows: list[dict],
    models: list[dict],
    tests: list[dict],
    recommendations: list[str],
) -> str:
    target = (
        f"{file.path} → {function.name}()"
        if function is not None
        else file.path
    )

    flow_names = [
        flow["name"]
        for flow in flows
    ]

    pieces = [
        (
            f"Changing {target} has "
            f"{risk.upper()} impact."
        ),
        (
            f"It has {len(direct_callers)} direct "
            f"caller(s) and {len(direct_callees)} "
            "resolved outgoing dependency/dependencies."
        ),
    ]

    if flow_names:
        pieces.append(
            "Affected application flow(s): "
            + ", ".join(
                flow_names,
            )
            + ".",
        )

    if models:
        pieces.append(
            "Review the related DB/model contract(s): "
            + ", ".join(
                model["name"]
                for model in models
            )
            + ".",
        )

    if tests:
        pieces.append(
            f"{len(tests)} related test file(s) "
            "were resolved and should be run.",
        )
    else:
        pieces.append(
            "No related test file was resolved, "
            "so a regression test is recommended.",
        )

    if recommendations:
        pieces.append(
            "Modify together: "
            + " ".join(
                recommendations[:3],
            ),
        )

    return " ".join(
        pieces,
    )


def _overall_risk(
    file: IndexedFile,
    function: IndexedFunction | None,
    flow_impacts: list[dict],
    direct_callers: list[dict],
    transitive_callers: list[dict],
    endpoints: list[dict],
    models: list[dict],
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

    if endpoints:
        candidates.append(
            "high",
        )

    if models:
        candidates.append(
            "medium",
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

    endpoints = _endpoint_refs(
        index,
        path=file.path,
        function=function,
        direct_callers=direct_callers,
        transitive_callers=(
            transitive_callers
        ),
    )

    models = _model_refs(
        index,
        file=file,
        function=function,
        direct_callees=direct_callees,
    )

    tests = _test_refs(
        index,
        target_file=file,
        function=function,
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

    related_files.update(
        endpoint["file"]
        for endpoint in endpoints
    )

    related_files.update(
        model["file"]
        for model in models
    )

    related_files.update(
        test["file"]
        for test in tests
    )

    related_files.discard(
        file.path,
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
            endpoints,
            models,
        )
    )

    recommendations = (
        _recommendations(
            file=file,
            function=function,
            direct_callers=(
                direct_callers
            ),
            direct_callees=(
                direct_callees
            ),
            flows=flow_impacts,
            models=models,
            tests=tests,
            security_flags=(
                security_flags
            ),
        )
    )

    semantic_answer = (
        _semantic_answer(
            file=file,
            function=function,
            risk=overall_risk,
            direct_callers=(
                direct_callers
            ),
            direct_callees=(
                direct_callees
            ),
            flows=flow_impacts,
            models=models,
            tests=tests,
            recommendations=(
                recommendations
            ),
        )
    )

    summary_parts = [
        (
            f"{len(direct_callers)} "
            "direct caller(s)"
        ),
        (
            f"{len(direct_callees)} "
            "outgoing dependency/dependencies"
        ),
        (
            f"{len(flow_impacts)} "
            "flow(s)"
        ),
        (
            f"{len(endpoints)} "
            "endpoint(s)"
        ),
        (
            f"{len(models)} "
            "DB model(s)"
        ),
        (
            f"{len(tests)} "
            "test file(s)"
        ),
        (
            f"{len(related_files)} "
            "related file(s)"
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
        "semantic_answer":
            semantic_answer,
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
        "endpoints":
            endpoints,
        "models":
            models,
        "tests":
            tests,
        "recommendations":
            recommendations,
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
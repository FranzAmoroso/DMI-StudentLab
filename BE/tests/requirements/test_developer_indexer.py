from pathlib import (
    Path,
)

from services.developer_indexer import (
    _dart_functions,
    _python_functions,
)


def test_python_function_indexing():
    source = """
def verify_password(value: str) -> bool:
    return check(value)

def login(email: str):
    return verify_password(email)
"""

    functions, imports = (
        _python_functions(
            "BE/services/example.py",
            source,
        )
    )

    names = {
        function.name
        for function in functions
    }

    assert names == {
        "verify_password",
        "login",
    }

    login = next(
        function
        for function in functions
        if function.name == "login"
    )

    assert (
        "verify_password"
        in login.calls
    )


def test_dart_function_indexing():
    source = """
import 'package:flutter/material.dart';

Future<void> login(String email) async {
}

bool canAccess(String role) {
  return role == 'creator';
}
"""

    functions, imports = (
        _dart_functions(
            "fe/lib/example.dart",
            source,
        )
    )

    names = {
        function.name
        for function in functions
    }

    assert "login" in names
    assert "canAccess" in names
    assert (
        "package:flutter/material.dart"
        in imports
    )

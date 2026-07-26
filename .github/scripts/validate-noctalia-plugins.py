#!/usr/bin/env python3
"""Validate Noctalia v5 plugin manifests and Luau entries.

Checks grounded in noctalia 5.0.0 (src/scripting/plugin_manifest.cpp):
  * plugin.toml must parse and declare id (author/plugin), name, plugin_api.
  * settings require key + label_key (no bare label/description).
  * entry .luau files referenced by manifest must exist.
  * launcher_provider entries should define onQuery; service entries update().
No network, no Nix — pure static sanity so CI catches breakage fast.
"""
import sys
import tomllib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ENTRY_KINDS = {
    "widget",
    "panel",
    "shortcut",
    "desktop_widget",
    "launcher_provider",
    "service",
}

errors: list[str] = []


def err(msg: str) -> None:
    errors.append(msg)


def balanced_luau(path: Path) -> bool:
    src = path.read_text(encoding="utf-8")
    depth = 0
    in_str: str | None = None
    in_line_comment = False
    in_block = False
    i = 0
    while i < len(src):
        c = src[i]
        nxt = src[i + 1] if i + 1 < len(src) else ""
        if in_line_comment:
            if c == "\n":
                in_line_comment = False
            i += 1
            continue
        if in_block:
            if c == "]" and nxt == "]":
                in_block = False
                i += 2
                continue
            i += 1
            continue
        if in_str:
            if c == "\\":
                i += 2
                continue
            if c == in_str:
                in_str = None
            i += 1
            continue
        if c == "-" and nxt == "-":
            in_line_comment = True
            i += 2
            continue
        if c == "[" and nxt == "[":
            in_block = True
            i += 2
            continue
        if c in ("'", '"'):
            in_str = c
            i += 1
            continue
        if c == "{":
            depth += 1
        elif c == "}":
            depth -= 1
            if depth < 0:
                return False
        i += 1
    return depth == 0 and not in_str


def luau_defines(path: Path, fn: str) -> bool:
    return f"function {fn}" in path.read_text(encoding="utf-8")


def validate_plugin(toml_path: Path) -> None:
    try:
        data = tomllib.loads(toml_path.read_text(encoding="utf-8"))
    except Exception as e:  # noqa: BLE001
        err(f"{toml_path}: TOML parse error: {e}")
        return

    pid = data.get("id")
    if not pid or "/" not in str(pid):
        err(f"{toml_path}: missing/invalid 'id' (expected author/plugin)")
    if not data.get("name"):
        err(f"{toml_path}: missing 'name'")
    if not isinstance(data.get("plugin_api"), int) or data["plugin_api"] < 3:
        err(f"{toml_path}: missing/invalid 'plugin_api' (>= 3)")

    for s in data.get("setting", []):
        if not s.get("key"):
            err(f"{toml_path}: setting missing 'key'")
        if not s.get("label_key"):
            err(f"{toml_path}: setting '{s.get('key')}' missing 'label_key'")
        if "label" in s:
            err(f"{toml_path}: setting '{s.get('key')}' uses 'label'; use 'label_key'")

    for kind in ENTRY_KINDS:
        for entry in data.get(kind, []):
            entry_file = entry.get("entry")
            if not entry_file:
                err(f"{toml_path}: {kind} '{entry.get('id')}' missing 'entry'")
                continue
            fpath = toml_path.parent / entry_file
            if not fpath.exists():
                err(f"{toml_path}: entry file '{entry_file}' not found")
                continue
            if not balanced_luau(fpath):
                err(f"{fpath}: unbalanced braces/strings")
            if kind == "launcher_provider" and not luau_defines(fpath, "onQuery"):
                err(f"{fpath}: launcher_provider must define onQuery(text)")
            if kind == "service" and not luau_defines(fpath, "update"):
                err(f"{fpath}: service must define update()")


def main() -> int:
    plugins_dir = ROOT / "plugins"
    if not plugins_dir.exists():
        print("no plugins/ dir, nothing to validate")
        return 0
    for toml_path in plugins_dir.rglob("plugin.toml"):
        validate_plugin(toml_path)
    if errors:
        print("Validation FAILED:")
        for e in errors:
            print(f"  - {e}")
        return 1
    print("All Noctalia plugin manifests valid.")
    return 0


if __name__ == "__main__":
    sys.exit(main())

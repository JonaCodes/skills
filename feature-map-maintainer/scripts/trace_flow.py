#!/usr/bin/env python3
"""Deterministic file and symbol tracer for repository navigation."""

from __future__ import annotations

import argparse
import json
import re
from collections import defaultdict
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

CODE_EXTENSIONS = {".js", ".jsx", ".ts", ".tsx", ".mjs", ".cjs", ".py"}
JS_EXTENSIONS = {".js", ".jsx", ".ts", ".tsx", ".mjs", ".cjs"}
PY_EXTENSIONS = {".py"}
SKIP_DIRS = {
    ".git",
    ".hg",
    ".svn",
    ".next",
    ".turbo",
    ".venv",
    "__pycache__",
    "build",
    "coverage",
    "dist",
    "node_modules",
    "target",
    "tmp",
    "vendor",
}
EDGE_PRIORITY = {
    "imports": 0,
    "imported_by": 1,
    "symbol_ref": 2,
    "related_test": 3,
}

JS_IMPORT_RE = re.compile(
    r"""(?x)
    (?:import|export)\s+(?:[^'"]+?\s+from\s+)?["']([^"']+)["']
    |require\(\s*["']([^"']+)["']\s*\)
    |import\(\s*["']([^"']+)["']\s*\)
    """
)
PY_FROM_RE = re.compile(r"^\s*from\s+([.\w]+)\s+import\s+", re.MULTILINE)
PY_IMPORT_RE = re.compile(r"^\s*import\s+([A-Za-z0-9_.,\s]+)", re.MULTILINE)


@dataclass(frozen=True)
class Edge:
    file: str
    edge: str
    detail: str


def iter_code_files(root: Path) -> list[Path]:
    files: list[Path] = []
    for path in root.rglob("*"):
        if not path.is_file():
            continue
        rel_parts = path.relative_to(root).parts
        if any(part in SKIP_DIRS for part in rel_parts):
            continue
        if path.suffix in CODE_EXTENSIONS:
            files.append(path)
    return sorted(files)


def relpath(path: Path, root: Path) -> str:
    return path.relative_to(root).as_posix()


def is_test_file(path: Path) -> bool:
    value = path.as_posix().lower()
    name = path.name.lower()
    return (
        "/tests/" in value
        or "/test/" in value
        or "__tests__" in value
        or ".spec." in name
        or ".test." in name
        or name.startswith("test_")
    )


def read_text(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        return path.read_text(encoding="utf-8", errors="ignore")


def python_module_map(files: Iterable[Path], root: Path) -> dict[str, Path]:
    module_map: dict[str, Path] = {}
    for path in files:
        if path.suffix not in PY_EXTENSIONS:
            continue
        rel = path.relative_to(root).with_suffix("")
        parts = list(rel.parts)
        if parts[-1] == "__init__":
            parts = parts[:-1]
        if parts:
            module_map[".".join(parts)] = path
    return module_map


def resolve_js_import(spec: str, source: Path, root: Path) -> Path | None:
    if spec.startswith("/"):
        base = root / spec.lstrip("/")
    elif spec.startswith("."):
        base = (source.parent / spec).resolve()
    else:
        return None

    candidates = [base]
    candidates.extend(base.with_suffix(ext) for ext in JS_EXTENSIONS if base.suffix == "")
    if base.suffix == "":
        candidates.extend(base / f"index{ext}" for ext in JS_EXTENSIONS)

    for candidate in candidates:
        if not candidate.is_file():
            continue
        try:
            candidate.relative_to(root)
        except ValueError:
            continue
        return candidate
    return None


def resolve_python_import(spec: str, source: Path, root: Path, module_map: dict[str, Path]) -> list[Path]:
    if not spec:
        return []
    if spec.startswith("."):
        source_rel = source.relative_to(root).with_suffix("")
        source_parts = list(source_rel.parts[:-1])
        dots = len(spec) - len(spec.lstrip("."))
        suffix = spec.lstrip(".")
        if dots > len(source_parts) + 1:
            return []
        base_parts = source_parts[: len(source_parts) - dots + 1]
        if suffix:
            base_parts.extend(suffix.split("."))
        key = ".".join(base_parts)
        return [module_map[key]] if key in module_map else []

    matches: list[Path] = []
    if spec in module_map:
        matches.append(module_map[spec])
    return matches


def parse_imports(path: Path, text: str, root: Path, module_map: dict[str, Path]) -> list[Path]:
    resolved: list[Path] = []
    if path.suffix in JS_EXTENSIONS:
        specs = [item for group in JS_IMPORT_RE.findall(text) for item in group if item]
        for spec in specs:
            target = resolve_js_import(spec, path, root)
            if target is not None:
                resolved.append(target)

    if path.suffix in PY_EXTENSIONS:
        for spec in PY_FROM_RE.findall(text):
            resolved.extend(resolve_python_import(spec, path, root, module_map))
        for group in PY_IMPORT_RE.findall(text):
            for spec in [part.strip() for part in group.split(",")]:
                if spec:
                    resolved.extend(resolve_python_import(spec, path, root, module_map))

    unique: list[Path] = []
    seen: set[Path] = set()
    for target in resolved:
        if target == path or target in seen:
            continue
        seen.add(target)
        unique.append(target)
    return unique


def build_graph(root: Path) -> tuple[list[Path], dict[Path, list[Path]], dict[Path, list[Path]]]:
    files = iter_code_files(root)
    module_map = python_module_map(files, root)
    outgoing: dict[Path, list[Path]] = {}
    incoming: dict[Path, list[Path]] = defaultdict(list)

    for path in files:
        imports = parse_imports(path, read_text(path), root, module_map)
        outgoing[path] = imports
        for target in imports:
            incoming[target].append(path)

    for paths in incoming.values():
        paths.sort()

    return files, outgoing, dict(incoming)


def related_tests(target: Path, files: list[Path], root: Path) -> list[Path]:
    stem = target.stem.lower()
    parent_parts = set(target.parent.parts)
    matches: list[Path] = []
    for path in files:
        if not is_test_file(path):
            continue
        lowered = path.name.lower()
        if stem and stem in lowered:
            matches.append(path)
            continue
        if parent_parts.intersection(path.parts):
            matches.append(path)
    unique: list[Path] = []
    seen: set[Path] = set()
    for path in matches:
        if path == target or path in seen:
            continue
        seen.add(path)
        unique.append(path)
    return unique


def symbol_refs(symbol: str, files: list[Path], target: Path | None) -> list[Path]:
    pattern = re.compile(rf"\b{re.escape(symbol)}\b")
    refs: list[Path] = []
    for path in files:
        if target is not None and path == target:
            continue
        if pattern.search(read_text(path)):
            refs.append(path)
    return refs


def describe(edge: str, source: Path | None, symbol: str | None) -> str:
    if edge == "imports":
        return "local import"
    if edge == "imported_by":
        return "module importer"
    if edge == "related_test":
        return "related test"
    if edge == "symbol_ref":
        return f"references symbol {symbol}" if symbol else "symbol reference"
    return "related file"


def collect_edges(
    root: Path,
    target: Path | None,
    symbol: str | None,
    files: list[Path],
    outgoing: dict[Path, list[Path]],
    incoming: dict[Path, list[Path]],
) -> list[Edge]:
    edges: list[Edge] = []
    seen: set[str] = set()

    def add(paths: Iterable[Path], edge_name: str) -> None:
        for path in paths:
            file_path = relpath(path, root)
            if file_path in seen:
                continue
            seen.add(file_path)
            edges.append(
                Edge(
                    file=file_path,
                    edge=edge_name,
                    detail=describe(edge_name, target, symbol),
                )
            )

    if target is not None:
        add(outgoing.get(target, []), "imports")
        add(incoming.get(target, []), "imported_by")
        add(related_tests(target, files, root), "related_test")

    if symbol:
        add(symbol_refs(symbol, files, target), "symbol_ref")

    edges.sort(key=lambda item: (EDGE_PRIORITY.get(item.edge, 99), item.file))
    return edges


def suggested_read_order(start: str, edges: list[Edge], max_files: int) -> list[str]:
    ordered = [start]
    for edge_type in ("imports", "imported_by", "symbol_ref", "related_test"):
        for edge in edges:
            if edge.edge != edge_type or edge.file in ordered:
                continue
            ordered.append(edge.file)
            if len(ordered) >= max_files + 1:
                return ordered
    return ordered


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Deterministically trace local file flow.")
    parser.add_argument("target", nargs="?", help="Repo-relative file path to trace.")
    parser.add_argument("--repo-root", default=".", help="Repository root. Defaults to current directory.")
    parser.add_argument("--symbol", help="Optional symbol name to search for exactly.")
    parser.add_argument("--max-files", type=int, default=8, help="Maximum related files to return.")
    parser.add_argument("--format", choices={"text", "json"}, default="text")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    root = Path(args.repo_root).resolve()
    target: Path | None = None

    if args.target:
        target = (root / args.target).resolve()
        if not target.exists():
            raise SystemExit(f"Target file not found: {args.target}")
        if not target.is_file():
            raise SystemExit(f"Target must be a file: {args.target}")

    if target is None and not args.symbol:
        raise SystemExit("Provide a target file or --symbol.")

    files, outgoing, incoming = build_graph(root)
    edges = collect_edges(root, target, args.symbol, files, outgoing, incoming)[: args.max_files]

    start = relpath(target, root) if target is not None else f"symbol:{args.symbol}"
    payload = {
        "start": start,
        "neighbors": [edge.__dict__ for edge in edges],
        "suggested_read_order": suggested_read_order(start, edges, args.max_files),
    }

    if args.format == "json":
        print(json.dumps(payload, indent=2, sort_keys=False))
        return 0

    print(f"start: {payload['start']}")
    if not edges:
        print("neighbors: none")
        return 0

    print("neighbors:")
    for edge in edges:
        print(f"- {edge.file} [{edge.edge}] {edge.detail}")
    print("suggested_read_order:")
    for item in payload["suggested_read_order"]:
        print(f"- {item}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

#!/usr/bin/env python3
"""Ensure the repo contains a developer-owned feature seed file before mapping."""

from __future__ import annotations

import argparse
from pathlib import Path
import sys

TEMPLATE = """features:
  # - name: sign-in
  #   description: User signs in with email and password
  # - name: create-workflow
  #   description: User creates a workflow from the dashboard
"""


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Ensure .ai/feature-seeds.yaml exists and is filled in.")
    parser.add_argument("--repo-root", default=".", help="Repository root. Defaults to current directory.")
    return parser.parse_args()


def has_feature_entries(text: str) -> bool:
    lines = [line.rstrip() for line in text.splitlines()]
    saw_features = False
    for line in lines:
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue
        if stripped == "features:":
            saw_features = True
            continue
        if saw_features and stripped.startswith("- name:"):
            return True
    return False


def main() -> int:
    args = parse_args()
    repo_root = Path(args.repo_root).resolve()
    ai_dir = repo_root / ".ai"
    seeds_path = ai_dir / "feature-seeds.yaml"

    if not seeds_path.exists():
        ai_dir.mkdir(parents=True, exist_ok=True)
        seeds_path.write_text(TEMPLATE, encoding="utf-8")
        print(
            "Created .ai/feature-seeds.yaml. Fill in the feature list, then rerun feature-map-init.",
            file=sys.stderr,
        )
        return 1

    content = seeds_path.read_text(encoding="utf-8")
    if not has_feature_entries(content):
        print(
            ".ai/feature-seeds.yaml exists but has no feature entries. Fill it in, then rerun feature-map-init.",
            file=sys.stderr,
        )
        return 1

    print(".ai/feature-seeds.yaml is present and contains feature entries.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

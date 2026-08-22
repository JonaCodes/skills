#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
POLICY_FILE="${SCRIPT_DIR}/file-length-policy.sh"

if [ ! -r "$POLICY_FILE" ]; then
  printf '{"continue":true}\n'
  exit 0
fi

source "$POLICY_FILE"

count_lines_excluding_import_blocks() {
  local file="$1"

  awk '
    BEGIN {
      in_import = 0
      count = 0
    }

    {
      if (in_import) {
        if ($0 ~ /;[[:space:]]*$/) {
          in_import = 0
        }
        next
      }

      if ($0 ~ /^[[:space:]]*import([[:space:]]|[{*])/ ) {
        if ($0 !~ /;[[:space:]]*$/) {
          in_import = 1
        }
        next
      }

      count++
    }

    END {
      print count
    }
  ' "$file"
}

PAYLOAD="$(cat)"
CWD="$(printf '%s' "$PAYLOAD" | /usr/bin/jq -r '.cwd // empty' 2>/dev/null || true)"
STOP_HOOK_ACTIVE="$(printf '%s' "$PAYLOAD" | /usr/bin/jq -r '.stop_hook_active // false' 2>/dev/null || true)"

if [ "$STOP_HOOK_ACTIVE" = "true" ]; then
  printf '{"continue":true}\n'
  exit 0
fi

if [ -z "$CWD" ] || [ ! -d "$CWD" ]; then
  printf '{"continue":true}\n'
  exit 0
fi

cd "$CWD"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  printf '{"continue":true}\n'
  exit 0
fi

REPO_ROOT="$(git rev-parse --show-toplevel)"
OVERSIZED=()

while IFS= read -r rel; do
  [ -n "$rel" ] || continue
  abs="$REPO_ROOT/$rel"

  [ -f "$abs" ] || continue
  is_ignored_file "$abs" "$REPO_ROOT" && continue

  if ! grep -Iq . "$abs" 2>/dev/null; then
    continue
  fi

  lines="$(count_lines_excluding_import_blocks "$abs")"
  if [ "$lines" -gt "$MAX_LINES" ]; then
    OVERSIZED+=("$(display_path "$abs" "$REPO_ROOT") ($lines lines)")
  fi
done < <(
  {
    git diff --name-only --diff-filter=ACM
    git diff --cached --name-only --diff-filter=ACM
    git ls-files --others --exclude-standard
  } | sed '/^$/d' | sort -u
)

if [ "${#OVERSIZED[@]}" -eq 0 ]; then
  printf '{"continue":true}\n'
  exit 0
fi

joined="$(printf '%s, ' "${OVERSIZED[@]}")"
joined="${joined%, }"

jq -nc \
  --arg reason "These uncommitted files exceed $MAX_LINES lines (excluding import blocks): $joined. Before making any refactor or split, ask the user whether they want to address them now. Do not edit those files until the user confirms. If the user says not to change them, leave them as-is." \
  '{decision:"block", reason:$reason}'

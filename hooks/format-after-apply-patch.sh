#!/bin/bash
set -euo pipefail

PAYLOAD="$(cat)"
CWD="$(printf '%s' "$PAYLOAD" | /usr/bin/jq -r '.cwd // empty' 2>/dev/null || true)"
TOOL_NAME="$(printf '%s' "$PAYLOAD" | /usr/bin/jq -r '.tool_name // empty' 2>/dev/null || true)"
PATCH="$(
  printf '%s' "$PAYLOAD" |
    /usr/bin/jq -r '
      .tool_input as $input
      | if ($input | type) == "string" then
          $input
        elif ($input | type) == "object" then
          ($input.command // $input.cmd // $input.input // $input.patch // "")
        else
          ""
        end
    ' 2>/dev/null || true
)"

[ "$TOOL_NAME" = "apply_patch" ] || [ "$TOOL_NAME" = "functions.apply_patch" ] || exit 0
[ -n "$CWD" ] && [ -d "$CWD" ] || exit 0
[ -n "$PATCH" ] || exit 0

cd "$CWD"

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  REPO_ROOT="$(git rev-parse --show-toplevel)"
else
  REPO_ROOT="$CWD"
fi

cd "$REPO_ROOT"

PRETTIER=()
if [ -x "$REPO_ROOT/node_modules/.bin/prettier" ]; then
  PRETTIER=("$REPO_ROOT/node_modules/.bin/prettier")
elif [ -x "$REPO_ROOT/public/node_modules/.bin/prettier" ]; then
  PRETTIER=("$REPO_ROOT/public/node_modules/.bin/prettier")
else
  for candidate in \
    /Users/jona/.antigravity/extensions/esbenp.prettier-vscode-*/node_modules/prettier/bin/prettier.cjs \
    /Users/jona/.vscode/extensions/esbenp.prettier-vscode-*/node_modules/prettier/bin/prettier.cjs
  do
    if [ -f "$candidate" ]; then
      PRETTIER=(node "$candidate")
      break
    fi
  done
fi

[ "${#PRETTIER[@]}" -gt 0 ] || exit 0

FILES="$(
  printf '%s\n' "$PATCH" |
    sed -nE 's/^\*\*\* (Add|Update) File: (.*)$/\2/p; s/^\*\*\* Move to: (.*)$/\1/p' |
    sed '/^$/d' |
    sort -u
)"

[ -n "$FILES" ] || exit 0

while IFS= read -r file; do
  [ -n "$file" ] || continue
  case "$file" in
    /*) abs_file="$file" ;;
    *) abs_file="$CWD/$file" ;;
  esac
  [ -f "$abs_file" ] || continue
  "${PRETTIER[@]}" --write --ignore-unknown "$abs_file" >/dev/null 2>&1 || true
done <<EOF
$FILES
EOF

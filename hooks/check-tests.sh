#!/bin/bash
set -euo pipefail

PAYLOAD="$(cat)"
CWD="$(printf '%s' "$PAYLOAD" | /usr/bin/jq -r '.cwd // empty' 2>/dev/null || true)"
STOP_HOOK_ACTIVE="$(printf '%s' "$PAYLOAD" | /usr/bin/jq -r '.stop_hook_active // false' 2>/dev/null || true)"
PNPM_BIN="${PNPM_BIN:-/Users/jona/.nvm/versions/node/v20.19.2/bin/pnpm}"

resolve_spectral_notes_root() {
  local cwd="$1"
  local root=""
  local package_name=""
  local origin=""

  [ -n "$cwd" ] && [ -d "$cwd" ] || return 1

  cd "$cwd"
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 1

  root="$(git rev-parse --show-toplevel)"
  [ -n "$root" ] && [ -d "$root" ] || return 1

  cd "$root"

  if [ -f package.json ]; then
    package_name="$(/usr/bin/jq -r '.name // empty' package.json 2>/dev/null || true)"
    [ "$package_name" = "spectral-notes-workspace" ] && {
      printf '%s\n' "$root"
      return 0
    }
  fi

  origin="$(git remote get-url origin 2>/dev/null || true)"
  case "$origin" in
    *JonaCodes/spectral-notes*)
      printf '%s\n' "$root"
      return 0
      ;;
  esac

  return 1
}

if [ "$STOP_HOOK_ACTIVE" = "true" ]; then
  printf '{"continue":true}\n'
  exit 0
fi

PROJECT_ROOT="$(resolve_spectral_notes_root "$CWD" || true)"

if [ -z "$PROJECT_ROOT" ]; then
  printf '{"continue":true}\n'
  exit 0
fi

if [ ! -x "$PNPM_BIN" ]; then
  PNPM_BIN="$(command -v pnpm || true)"
fi

if [ -z "$PNPM_BIN" ]; then
  /usr/bin/jq -nc \
    --arg reason "pnpm was not found in the Codex hook environment; cannot run pnpm check for spectral-notes." \
    '{decision:"block", reason:$reason}'
  exit 0
fi

if ! cd "$PROJECT_ROOT" || ! "$PNPM_BIN" run check 1>&2; then
  /usr/bin/jq -nc \
    --arg reason "pnpm check failed in spectral-notes. Run \`pnpm run check\` and resolve the issues before continuing." \
    '{decision:"block", reason:$reason}'
  exit 0
fi

printf '{"continue":true}\n'

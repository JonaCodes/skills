#!/bin/bash
set -euo pipefail

PAYLOAD="$(cat)"
TOOL_NAME="$(printf '%s' "$PAYLOAD" | /usr/bin/jq -r '.tool_name // empty' 2>/dev/null || true)"

BLOCKED_DESCRIPTION=".env* and .dev.vars files"
BLOCKED_BASENAME_REGEX='^(\.env.*|\.dev\.vars)$'

block() {
  local target="$1"

  /usr/bin/jq -nc \
    --arg reason "Blocked access to sensitive file pattern ($BLOCKED_DESCRIPTION): $target. Do not attempt to read this without user consent." \
    '{decision:"block", reason:$reason}'
  exit 0
}

basename_matches_blocked_pattern() {
  local value="$1"
  local base="${value##*/}"
  local base_lower

  base_lower="$(printf '%s' "$base" | tr '[:upper:]' '[:lower:]')"
  case "$base_lower" in
    .env.example|.env.*.example) return 1 ;;
  esac

  [[ "$base_lower" =~ $BLOCKED_BASENAME_REGEX ]]
}

check_path_value() {
  local value="$1"

  [ -n "$value" ] || return 0

  if basename_matches_blocked_pattern "$value"; then
    block "$value"
  fi
}

check_json_path_fields() {
  while IFS= read -r value; do
    check_path_value "$value"
  done < <(
    printf '%s' "$PAYLOAD" |
      jq -r '
        .tool_input
        | ..?
        | strings
      '
  )
}

tool_input_text() {
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
}

check_apply_patch_headers() {
  local command="$1"

  while IFS= read -r file; do
    check_path_value "$file"
  done < <(
    printf '%s\n' "$command" |
      sed -nE 's/^\*\*\* (Add|Update|Delete) File: (.*)$/\2/p; s/^\*\*\* Move to: (.*)$/\1/p'
  )
}

check_shell_command() {
  local command="$1"
  local token

  [ -n "$command" ] || return 0

  while IFS= read -r token; do
    [ -n "$token" ] || continue
    check_path_value "$token"
  done < <(
    printf '%s\n' "$command" |
      tr '[:space:]<>"'\''=;|&(),' '\n' |
      sed -n '/\.[eE][nN][vV]\|\.dev\.[vV][aA][rR][sS]/p'
  )
}

check_json_path_fields

case "$TOOL_NAME" in
  apply_patch|functions.apply_patch)
    check_apply_patch_headers "$(tool_input_text)"
    ;;
  Bash|bash|exec_command|functions.exec_command)
    check_shell_command "$(tool_input_text)"
    ;;
esac

printf '{"continue":true}\n'

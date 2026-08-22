#!/bin/bash

# Shared, deliberately lock-free state helpers for manual-only skills.

MANUAL_ONLY_STATE_ROOT="${CODEX_MANUAL_ONLY_STATE_ROOT:-${CODEX_SKILL_STATE_ROOT:-/tmp/codex-manual-only-skill-state}}"
MANUAL_ONLY_STATE_MAX_AGE_SECONDS=86400
MANUAL_ONLY_STATE_CLEANUP_INTERVAL_SECONDS=3600

manual_only_sanitize_component() {
  local value="$1"
  value="$(printf '%s' "$value" | tr -c 'A-Za-z0-9._-' '_')"
  [ -n "$value" ] || value="_"
  printf '%s' "$value"
}

manual_only_session_dir() {
  printf '%s/%s' "$MANUAL_ONLY_STATE_ROOT" "$(manual_only_sanitize_component "$1")"
}

manual_only_turn_file() {
  printf '%s/%s.json' "$(manual_only_session_dir "$1")" "$(manual_only_sanitize_component "$2")"
}

manual_only_now_epoch() {
  date +%s 2>/dev/null || printf '0'
}

manual_only_file_mtime() {
  local path="$1"
  stat -f '%m' "$path" 2>/dev/null || stat -c '%Y' "$path" 2>/dev/null || printf '0'
}

manual_only_trim_scalar() {
  local value="$1"
  value="${value#${value%%[![:space:]]*}}"
  value="${value%${value##*[![:space:]]}}"
  case "$value" in
    \"*\") value="${value#\"}"; value="${value%\"}" ;;
    \'*\') value="${value#\'}"; value="${value%\'}" ;;
  esac
  printf '%s' "$value"
}

# Print the YAML frontmatter body. A non-frontmatter file or an unterminated
# frontmatter block returns non-zero; callers intentionally fail open for these.
manual_only_read_frontmatter() {
  local path="$1" first closed
  [ -r "$path" ] || return 1
  first="$(sed -n '1p' "$path" 2>/dev/null || true)"
  [ "$first" = '---' ] || return 1
  closed="$(awk 'NR > 1 && $0 ~ /^[[:space:]]*---[[:space:]]*$/ { print "yes"; exit }' "$path" 2>/dev/null || true)"
  [ "$closed" = yes ] || return 1
  awk 'NR == 1 { next } NR > 1 && $0 ~ /^[[:space:]]*---[[:space:]]*$/ { exit } { print }' "$path" 2>/dev/null
}

manual_only_frontmatter_value() {
  local body="$1" key="$2"
  printf '%s\n' "$body" |
    sed -nE "s/^[[:space:]]*${key}:[[:space:]]*(.*)$/\1/p" |
    head -n 1 |
    while IFS= read -r value; do manual_only_trim_scalar "$value"; done
}

manual_only_maybe_cleanup_stale() {
  local tracker now tracker_mtime cutoff session_file session_dir
  mkdir -p "$MANUAL_ONLY_STATE_ROOT" 2>/dev/null || return 0
  tracker="$MANUAL_ONLY_STATE_ROOT/.cleanup-tracker"
  now="$(manual_only_now_epoch)"
  tracker_mtime=0
  [ -f "$tracker" ] && tracker_mtime="$(manual_only_file_mtime "$tracker")"
  [ "$tracker_mtime" -gt 0 ] 2>/dev/null &&
    [ $((now - tracker_mtime)) -lt "$MANUAL_ONLY_STATE_CLEANUP_INTERVAL_SECONDS" ] 2>/dev/null && return 0

  cutoff=$((now - MANUAL_ONLY_STATE_MAX_AGE_SECONDS))
  if [ -d "$MANUAL_ONLY_STATE_ROOT" ]; then
    while IFS= read -r -d '' session_file; do
      [ "$(manual_only_file_mtime "$session_file")" -lt "$cutoff" ] 2>/dev/null || continue
      rm -f -- "$session_file" 2>/dev/null || true
    done < <(find "$MANUAL_ONLY_STATE_ROOT" -mindepth 2 -type f -name '*.json' -print0 2>/dev/null || true)

    while IFS= read -r -d '' session_dir; do
      [ "$session_dir" = "$MANUAL_ONLY_STATE_ROOT" ] && continue
      rmdir -- "$session_dir" 2>/dev/null || true
    done < <(find "$MANUAL_ONLY_STATE_ROOT" -mindepth 1 -type d -empty -print0 2>/dev/null || true)
  fi

  touch "$tracker" 2>/dev/null || true
}

manual_only_cleanup_turn() {
  local session_id="$1" turn_id="$2" session_dir turn_file
  session_dir="$(manual_only_session_dir "$session_id")"
  turn_file="$(manual_only_turn_file "$session_id" "$turn_id")"
  rm -f -- "$turn_file" 2>/dev/null || true
  rmdir -- "$session_dir" 2>/dev/null || true
  manual_only_maybe_cleanup_stale
}

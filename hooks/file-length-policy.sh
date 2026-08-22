MAX_LINES=320
TRACK_DIR="/tmp/claude-file-length-trackers"

tracker_path() {
  local session_id sanitized

  session_id="$1"
  sanitized="$(printf '%s' "$session_id" | tr -c 'A-Za-z0-9._-' '_')"
  printf '%s/%s.files\n' "$TRACK_DIR" "$sanitized"
}

resolve_path() {
  local path cwd

  path="$1"
  cwd="$2"

  case "$path" in
    /*) printf '%s\n' "$path" ;;
    *) printf '%s/%s\n' "$cwd" "$path" ;;
  esac
}

display_path() {
  local path cwd prefix

  path="$1"
  cwd="$2"
  prefix="$cwd/"

  case "$path" in
    "$prefix"*) printf '%s\n' "${path#"$prefix"}" ;;
    *) printf '%s\n' "$path" ;;
  esac
}

trim_line() {
  local value

  value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s\n' "$value"
}

project_ignore_file() {
  local cwd

  cwd="$1"
  printf '%s/.claude/hooks/file-length-validation.ignore.toml\n' "$cwd"
}

matches_project_ignore() {
  local path cwd ignore_file rel base pattern in_ignored_paths

  path="$1"
  cwd="${2:-}"

  [ -n "$cwd" ] || return 1

  ignore_file="$(project_ignore_file "$cwd")"
  [ -f "$ignore_file" ] || return 1

  rel="$(display_path "$path" "$cwd")"
  base="${path##*/}"
  in_ignored_paths=0

  while IFS= read -r pattern || [ -n "$pattern" ]; do
    pattern="$(trim_line "$pattern")"
    [ -n "$pattern" ] || continue

    case "$pattern" in
      \#*) continue ;;
      ignored_paths[\ \	]*=[\ \	]*\[*) in_ignored_paths=1 ;;
      '[') in_ignored_paths=1; continue ;;
      ']') in_ignored_paths=0; continue ;;
    esac

    [ "$in_ignored_paths" -eq 1 ] || continue

    pattern="${pattern%%#*}"
    pattern="$(trim_line "$pattern")"
    pattern="${pattern%,}"
    pattern="$(trim_line "$pattern")"
    pattern="${pattern#\"}"
    pattern="${pattern%\"}"
    [ -n "$pattern" ] || continue

    case "$rel" in
      $pattern) return 0 ;;
    esac

    case "$base" in
      $pattern) return 0 ;;
    esac

    case "$path" in
      $pattern) return 0 ;;
    esac
  done < "$ignore_file"

  return 1
}

is_ignored_file() {
  local path base cwd

  path="${1#./}"
  cwd="${2:-}"
  base="${path##*/}"

  case "$path" in
    */node_modules/*|node_modules/*|\
    */dist/*|dist/*|\
    */build/*|build/*|\
    */coverage/*|coverage/*|\
    */docs/handoffs/*|docs/handoffs/*|\
    */tmp/*|tmp/*|\
    */temp/*|temp/*|\
    */.cache/*|.cache/*|\
    */migrations/*|migrations/*|\
    */plans/*|plans/*|\
    */prompts/*|prompts/*|\
    */fixture/*|fixture/*|\
    */fixtures/*|fixtures/*|\
    */__fixtures__/*|__fixtures__/*|\
    */script/*|script/*|\
    */scripts/*|scripts/*|\
    */test/*|test/*|\
    */tests/*|tests/*|\
    */__tests__/*|__tests__/*|\
    */__snapshots__/*|__snapshots__/*|\
    */spec/*|spec/*|\
    */vendor/*|vendor/*|\
    */Pods/*|Pods/*|\
    */.venv/*|.venv/*|\
    */venv/*|venv/*|\
    */target/*|target/*|\
    */.next/*|.next/*|\
    */.nuxt/*|.nuxt/*|\
    */.svelte-kit/*|.svelte-kit/*|\
    */.turbo/*|.turbo/*|\
    */out/*|out/*)
      return 0
      ;;
  esac

  case "$base" in
    package-lock.json|pnpm-lock.yaml|yarn.lock|bun.lock|Cargo.lock|\
    composer.lock|Gemfile.lock|Podfile.lock|Package.resolved|\
    manifest.json|*.webmanifest|*.snap|*.min.js|*.min.css|\
    *.bundle.js|*.bundle.css|*.map|\
    *.test.*|*.spec.*|*.generated.*|*.gen.*)
      return 0
      ;;
  esac

  matches_project_ignore "$path" "$cwd" && return 0

  return 1
}

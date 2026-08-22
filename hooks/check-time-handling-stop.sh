#!/bin/bash
set -euo pipefail

APPROVED_TIMESTAMP_HELPER="packages/logic/src/time/localTimestamp.ts"
APPROVED_TIME_UTILS="packages/logic/src/utils/time.ts"
GET_TIME_REGEX='new[[:space:]]+Date\([^)]*\)\.getTime\(\)'

PAYLOAD="$(cat)"
CWD="$(printf '%s' "$PAYLOAD" | /usr/bin/jq -r '.cwd // empty' 2>/dev/null || true)"
STOP_HOOK_ACTIVE="$(printf '%s' "$PAYLOAD" | /usr/bin/jq -r '.stop_hook_active // false' 2>/dev/null || true)"

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

cd "$PROJECT_ROOT"

is_typescript_file() {
  case "$1" in
    *.ts|*.tsx) return 0 ;;
    *) return 1 ;;
  esac
}

is_excluded_file() {
  case "$1" in
    node_modules/*|*/node_modules/*) return 0 ;;
    dist/*|*/dist/*) return 0 ;;
    build/*|*/build/*) return 0 ;;
    coverage/*|*/coverage/*) return 0 ;;
    .next/*|*/.next/*) return 0 ;;
    *.generated.ts|*.generated.tsx|*.gen.ts|*.gen.tsx) return 0 ;;
    *) return 1 ;;
  esac
}

is_test_or_fake_file() {
  case "$1" in
    *.test.ts|*.test.tsx|*.spec.ts|*.spec.tsx) return 0 ;;
    */__tests__/*|*/__fixtures__/*|*/fake*|*/fakes/*) return 0 ;;
    *) return 1 ;;
  esac
}

allows_get_time() {
  case "$1" in
    packages/ui/src/components/feedback/OnlineStatus.tsx) return 0 ;;
    *) return 1 ;;
  esac
}

allows_date_now_raw_comparison() {
  local file="$1"
  local line="$2"

  case "$file" in
    apps/pwa/src/hooks/usePwaInstallPrompt.ts)
      [[ "$line" == *"Date.now() - timestamp < DISMISS_SNOOZE_MS"* ]] &&
        return 0
      ;;
  esac

  return 1
}

contains_timestamp_name() {
  local line="$1"
  [[ "$line" =~ (^|[^A-Za-z0-9_$])(createdAt|updatedAt|serverUpdatedAt|deletedAt|archivedAt|lastNotesServerSyncAt|lastTagsServerSyncAt|timestamp)([^A-Za-z0-9_$]|$) ]]
}

has_raw_comparison_operator() {
  local line="$1"
  local normalized="${line//=>/}"
  normalized="$(printf '%s\n' "$normalized" | sed -E \
    -e 's/"([^"\\]|\\.)*"//g' \
    -e "s/'([^'\\]|\\.)*'//g" \
    -e 's/`([^`\\]|\\.)*`//g' \
    -e 's#/>##g' \
    -e 's#</?[A-Za-z][A-Za-z0-9_.:-]*##g' \
    -e 's#>[[:space:]]*$##g' \
    -e 's/<[A-Za-z0-9_$.,|&?:[:space:]\\[\\]]+>//g')"
  [[ "$normalized" =~ (<=|>=|<|>) ]]
}

is_allowed_raw_comparison_line() {
  local file="$1"
  local line="$2"
  local trimmed="${line#"${line%%[![:space:]]*}"}"

  [[ "$line" == *"compareIsoInstants("* ]] && return 0
  [[ "$line" == *"maxIsoInstantCursor("* ]] && return 0
  allows_date_now_raw_comparison "$file" "$line" && return 0
  [[ "$trimmed" == import* ]] && return 0
  [[ "$trimmed" == export\ type* ]] && return 0
  [[ "$trimmed" == type* ]] && return 0
  [[ "$trimmed" == interface* ]] && return 0
  return 1
}

violations=()

add_violation() {
  local file="$1"
  local line_no="$2"
  local message="$3"

  violations+=("$file:$line_no:$message")
}

while IFS= read -r file; do
  [ -n "$file" ] || continue
  [ -f "$file" ] || continue
  is_typescript_file "$file" || continue
  is_excluded_file "$file" && continue

  line_no=0
  while IFS= read -r line || [ -n "$line" ]; do
    line_no=$((line_no + 1))

    if [[ "$line" == *"new Date().toISOString()"* ]] &&
      [ "$file" != "$APPROVED_TIMESTAMP_HELPER" ]; then
      add_violation "$file" "$line_no" "Use createLocalIsoTimestamp() instead of new Date().toISOString() for local domain/sync timestamps."
    fi

    if [[ "$line" == *"Date.parse("* ]] &&
      [ "$file" != "$APPROVED_TIME_UTILS" ] &&
      ! is_test_or_fake_file "$file"; then
      add_violation "$file" "$line_no" "Use shared time helpers instead of ad hoc Date.parse(...) in production code."
    fi

    if [[ "$line" =~ $GET_TIME_REGEX ]] &&
      ! allows_get_time "$file" &&
      ! is_test_or_fake_file "$file"; then
      add_violation "$file" "$line_no" "Use compareIsoInstants(...) or another shared time helper instead of new Date(...).getTime()."
    fi

    if [[ "$line" == *".localeCompare("* ]] && contains_timestamp_name "$line"; then
      add_violation "$file" "$line_no" "Use compareIsoInstants(...) for timestamp sorting instead of localeCompare(...)."
    fi

    if contains_timestamp_name "$line" &&
      has_raw_comparison_operator "$line" &&
      ! is_test_or_fake_file "$file" &&
      ! is_allowed_raw_comparison_line "$file" "$line"; then
      add_violation "$file" "$line_no" "Use compareIsoInstants(...) or maxIsoInstantCursor(...) instead of raw timestamp comparisons."
    fi
  done < "$file"
done < <(
  {
    git diff --name-only --diff-filter=ACMR
    git diff --cached --name-only --diff-filter=ACMR
    git ls-files --others --exclude-standard
  } | sed '/^$/d' | sort -u
)

if [ "${#violations[@]}" -eq 0 ]; then
  printf '{"continue":true}\n'
  exit 0
fi

printf '%s\n' "${violations[@]}" 1>&2

/usr/bin/jq -nc \
  --arg reason "Risky timestamp handling found in changed spectral-notes TypeScript files. Use createLocalIsoTimestamp(), compareIsoInstants(), or maxIsoInstantCursor(), or add a narrow hook allowlist for a legitimate exception. Ignore this message if the handling is justified." \
  '{decision:"block", reason:$reason}'

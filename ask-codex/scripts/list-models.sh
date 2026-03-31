#!/bin/bash

# Reads model list from a local cache file (valid for 7 days).
# If cache is missing or stale, regenerates it from ~/.codex/models_cache.json.
# Output format (no header line):
#   gpt-5.4: low, medium, high, xhigh
#   gpt-5.3-codex: low, medium, high, xhigh

SKILL_CACHE="/Users/jona/.claude/skills/ask-codex/cached-codex-models.txt"
SOURCE_CACHE="$HOME/.codex/models_cache.json"
TODAY=$(date +%Y-%m-%d)

# Check if local cache exists and is fresh (< 7 days old)
if [[ -f "$SKILL_CACHE" ]]; then
  CACHE_DATE=$(grep '^# updated:' "$SKILL_CACHE" | awk '{print $3}')
  if [[ -n "$CACHE_DATE" ]]; then
    CACHE_EPOCH=$(date -j -f "%Y-%m-%d" "$CACHE_DATE" "+%s" 2>/dev/null)
    TODAY_EPOCH=$(date -j -f "%Y-%m-%d" "$TODAY" "+%s" 2>/dev/null)
    AGE_DAYS=$(( (TODAY_EPOCH - CACHE_EPOCH) / 86400 ))
    if [[ $AGE_DAYS -lt 7 ]]; then
      grep -v '^#' "$SKILL_CACHE"
      exit 0
    fi
  fi
fi

# Cache missing or stale — regenerate from source
if [[ ! -f "$SOURCE_CACHE" ]]; then
  echo "Error: models cache not found at $SOURCE_CACHE" >&2
  exit 1
fi

MODEL_LINES=$(python3 - "$SOURCE_CACHE" <<'EOF'
import json, sys

with open(sys.argv[1]) as f:
    data = json.load(f)

for m in data.get("models", []):
    if m.get("visibility") != "list":
        continue
    slug = m["slug"]
    efforts = [r["effort"] for r in m.get("supported_reasoning_levels", [])]
    print(f"{slug}: {', '.join(efforts)}")
EOF
)

if [[ -z "$MODEL_LINES" ]]; then
  echo "Error: no models found in $SOURCE_CACHE" >&2
  exit 1
fi

# Write new cache file with datestamp header
{
  echo "# updated: $TODAY"
  echo "$MODEL_LINES"
} > "$SKILL_CACHE"

echo "$MODEL_LINES"

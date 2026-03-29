#!/bin/bash

set -euo pipefail

REPO_ROOT="${1:-$(pwd)}"
SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOK_PATH="$REPO_ROOT/.git/hooks/pre-commit"
MAINTAINER_SCRIPT="$SKILL_DIR/../../feature-map-maintainer/scripts/run-maintainer.sh"

if [[ ! -d "$REPO_ROOT/.git" ]]; then
  echo "Error: $REPO_ROOT is not a git repository" >&2
  exit 1
fi

cat >"$HOOK_PATH" <<EOF
#!/bin/bash
set -euo pipefail

REPO_ROOT="\$(git rev-parse --show-toplevel)"
"$MAINTAINER_SCRIPT" "\$REPO_ROOT"
EOF

chmod +x "$HOOK_PATH"
echo "Installed pre-commit hook at $HOOK_PATH"

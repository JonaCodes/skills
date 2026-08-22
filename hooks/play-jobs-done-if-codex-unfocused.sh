#!/bin/zsh

set -u

# JXA writes console.log output to stderr, so merge and retain only the
# boolean result. An empty result is treated as "unknown" and fails closed.
frontmost_is_codex="$({
  /usr/bin/osascript -l JavaScript -e 'ObjC.import("AppKit"); const app=$.NSWorkspace.sharedWorkspace.frontmostApplication; let id=""; try { if (app && app.bundleIdentifier) id=app.bundleIdentifier.js || ""; } catch (e) {} console.log(id ? (id === "com.openai.codex" ? "true" : "false") : "unknown");'
} 2>&1 | /usr/bin/grep -E '^(true|false)$' | /usr/bin/tail -n 1)"

# Play only when we successfully confirmed that Codex is not focused.
[[ "$frontmost_is_codex" == "false" ]] || exit 0

# Audio is best-effort; never turn a notification failure into a hook failure.
/usr/bin/afplay /Users/jona/.claude/custom-assets/jobs-done.mp3 >/dev/null 2>&1 || true

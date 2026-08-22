Set up a user-level Codex hook system that makes selected skills manual-only.

First inspect my existing Codex hook configuration and preserve all current hooks. Integrate with the existing setup; do not replace unrelated configuration.

Desired behavior

A skill is manual-only when its SKILL.md YAML frontmatter contains:

`manual-only: true`

Manual-only skills may be read only when the current user message explicitly invokes the skill using either:

$skill-name
/skill-name

Multiple skill invocations in one message must be supported.

Implement three lifecycle hooks:

1. UserPromptSubmit

- Read `session_id`, `turn_id`, and prompt from the hook payload.
- Extract, normalize to lowercase, and deduplicate all explicit $skill-name and /skill-name invocations.
- Store only the skill names and a creation timestamp.
- Use a per-turn JSON state file namespaced by both `session_id` and `turn_id`.
- Store state beneath an appropriate temporary directory.
- Create state files atomically using a temporary file followed by rename.
- No locking mechanism needed.

2. PreToolUse

- Cover supported local tools broadly because shell reads appear as Bash and there is no universal semantic file-read matcher.
- Exit successfully with no stdout when the tool arguments do not reference a file named SKILL.md.
- For every referenced SKILL.md:
  - Read its YAML frontmatter inside the hook.
  - If manual-only is absent or not true, allow the read.
  - If manual-only: true, obtain the frontmatter name.
  - Load the state for the current session_id and turn_id.
  - Allow the read only when that name appears in the recorded explicit invocations.
- Missing or malformed state must fail closed for manual-only skills.
- Unauthorized reads must be denied with exactly: "This skill can only be read when the user explicitly asks for it."

- PreToolUse allow paths must produce no stdout. Only intentional denial should emit a blocking hook response.

3. Stop

- Best-effort delete the current turn’s state file.
- Remove its session directory when empty.
- Maintain a small cleanup tracker in the state root.
- At most once per hour, scan for state files older than 24 hours, delete them, and remove empty session directories.
- Do not use a lock. Concurrent deletion or tracker-update failures are acceptable.
- Catch and ignore cleanup errors so they never disrupt the Codex flow.
- Return a successful Stop response.

Implementation requirements

- Use portable Bash suitable for macOS/Linux and clearly document required tools such as jq.
- Sanitize `session_id` and `turn_id` before using them as path components.
- Preserve the existing hooks.json entries and add UserPromptSubmit, PreToolUse, and Stop handlers.
- Use absolute paths in the user-level hooks.json so Codex can execute the scripts reliably.
- Make scripts executable.
- Do not modify existing skill contents.
- Do not introduce a background process.

Verification

Test all of these cases:

- Multiple $skill-name and /skill-name invocations are recorded and deduplicated.
- An explicitly invoked manual-only skill is allowed.
- A manual-only skill not explicitly invoked is denied with the exact message.
- Missing or malformed state denies manual-only skills.
- Ordinary skills remain readable without recorded state.
- Non-SKILL.md reads are unaffected.
- PreToolUse allow paths produce no output.
- Current-turn cleanup works.
- Files older than 24 hours are removed during an eligible cleanup sweep.
- Concurrent/best-effort cleanup errors do not fail the Stop hook.
- All scripts pass bash syntax checks and hooks.json is valid JSON.

After implementation, report the files created or changed, test results, and whether I must restart Codex or trust the new hooks through /hooks. Also remind me that:
1. Sometimes codex requires manual approval of new hooks (via the settings)
2. I must ask you to add `manual-only: true` or add it myself to relevant skills that I don't want Codex to autoload

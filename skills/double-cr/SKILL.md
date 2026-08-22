---
name: double-cr
description: Do not use this skill unless the user explicitly asks.
manual-only: true
disable-model-invocation: true
---

Spin up at least two subagents to review the changes:

1. For feature completeness
2. For coding quality per the relevant CLAUDE.md or AGENT.md file(s)

You should make as many agents as necessary soas not to overwhelm any individual agent with too many disparate parts of the changes.

Spawn lean subagents without full-history fork; pass only the repo path, scope, and review role.

## Review Guidelines

1. Avoid patch/hacks in the code - all implementations should be robust and maintainable
2. Keep the review straightforward; avoid over-engineering
3. Focus on the main use case; avoid getting distracted by edge cases
4. Stay within scope; review only the current changes
5. Ensure the code remains straightforward and not over-engineered
6. Ensure the overall architecture is reasonable and appropriate
7. Be brave: if a refactor is needed, say so clearly
8. Ensure the code adheres to the `CODING_GUIDELINES.md`

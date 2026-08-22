---
name: implement
description: Do not use this skill unless the user explicitly asks.
manual-only: true
disable-model-invocation: true
---

We are now ready to implement the task. If this is a small implementation, do it yourself. But if this requires implementing logic, a new feature, multiple files, or similar, then you should spin up one or more subagents to implement the task. You can use one of these subagents for the task:

- @junior-implementor
- @experienced-implementor
- @senior-implementor
- @tech-lead-implementor

When determening how many and which subagents to spin up, think about the scope of the task, and to what extent it can be parallelized, so that no subagent overwrites another subagents' work.

Your task is therefore to manage the subagents until the task is complete.

For each subagent you spin up, you must:

- Create it with fresh, clean context.
- Provide it with the relevant context of the task, including any relevant spec files.
- Instruct it to read the documentation relevant to the task (if any), starting at `docs/index.md`.

When _all_ implementor subagents are finished, you may consider running a `/double-cr` _if_ the scope/complexity merits it. If it is a small or straightforward task, there is no need for a full double CR.

If you are unsure whether to spin up subagents, or which subagents to use, consult with me.

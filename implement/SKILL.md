---
name: implement
description: Implement the request feature/flow/fix/refactor using one or more appropriate subagents
disable-model-invocation: true
---

We are now ready to implement the task. If this is a small implementation, do it yourself. But if this requires implementing logic, a new feature, multiple files, or similar, then you should spin up one or more subagents to implement the task.

When determening how many and which subagents to spin up, think about the scope of the task, and to what extent it can be parallelized, so that no subagent overwrites another subagents' work.

Your task is therefore to manage the subagents until the task is complete.

The subagents you create should be appropriate to the level of the task. For example, simple tasks may use simpler models. More complex tasks should use more advanced models. Reasoning should always be 'high' unless the task is trivial, like replacing variable names/values/renaming files/tiny refactors, etc.

For each subagent you spin up, you must:

- Provide it with the relevant context of the task, including any relevant spec files.
- Instruct it to read the documentation relevant to the task (if any), starting at `docs/index.md`.
- Instruct it to adhere to the `CODING_GUIDELINES.md` (note: if you are not using subagents, you must read this file yourself).

As soon as an implementor subagent is finished, you should run a `/double-cr`

If you are unsure whether to spin up subagents, or which subagents to use, consult with me.

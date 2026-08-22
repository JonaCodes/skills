---
name: project-context
description: Get the relevant context of the project before diving into planning/implementation
disable-model-invocation: true
---

For starters, read the following root files for general context, if they exist:

- `README.md`
- `CLAUDE.md`
- `AGENT.md` or `AGENTS.md`

Then read `docs/index.md` and branch out from there based on the user's request.

These markdown files in `docs/` give a general overview of the features/flows in this project, which you will need to complete the user's request. The docs point to actual code files, so read the relevant docs and code files that are relevant to the request.

**Important**: start simple:

- Start by _only_ reading the relevant documentation and code files.
- Do **not** run other commands, explore connections/state/data, search the codebase with your own commands.

Only if the raw docs/code fails to provide the needed context for the user's request, _then_ you make run other commands/explorations etc. But always start lean.

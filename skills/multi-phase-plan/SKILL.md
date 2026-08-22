---
name: multi-phase-plan
description: Do not use this skill unless the user explicitly asks.
manual-only: true
---

Create a multi-phase plan based on our discussion.

The plan should consist of an `index.md` with a high-level overview of the full flow, and links to the individual phase files. Store all files under:

`docs/plans/<feature-name>/`

Before planning, inspect the relevant parts of the existing project so the plan reflects the actual codebase.

Each phase should deliver a meaningful capability that can be manually run, exercised, or verified. A phase might represent a complete feature, flow, integration, migration, or meaningful configuration.

For example, setting up a repository can be a phase because we can run the server and verify it works. Adding a button is usually a task within a phase, not a phase itself.

Group closely related functionality together. For example, creating, editing, and removing users should be one phase. Equivalent operations for a different entity may be another phase.

When several features share a genuine abstraction, implement the abstraction alongside one representative end-to-end use case, then fill in the remaining cases in a later phase. Avoid speculative abstractions unless specifically requested.

Each phase should:

- Leave the project in a working state
- Build only on completed earlier phases
- Have a clear outcome and scope
- Include concrete acceptance criteria
- Include exact manual verification steps
- State what is deferred or out of scope

Order phases to validate risky assumptions and integrations early. Prefer thin end-to-end slices over separate frontend and backend phases when possible.

If stopping at the end of a phase would not leave something coherent to evaluate, it is probably a task rather than a phase.

**Guidelines**:

- Only plan for error handling at the beginning and endpoints of major flows, e.g at a controller, for an API request.
- Only separate to meaningful phases, not just for the sake of separation.
- Each phase should also plan up to 3 (can be zero) meaningful unit/integration tests.

**Crucial**: use plain language in the files. Only use technical jargon where necessary, but prefer simple verbs and ELI18 style language.

**Also Crucial**: each phase should outline _only the relevent functionality for that specific phase_. Absolutely avoid the following:

- fallbacks
- excessive guardrails
- handling every edge case

**Workflow**:

- Start by creating the high level plan without creating any files.
- Share the plan with the user for review and approval.
- If the user approves, create the aforementioned `index` and phase files.
- Once you're done, spin up a subagent that's free of context (same model, but low reasoning effort) to review all the phase files to ensure for consistency, and that it follows the rules above.

**Note**: we are only planning for now. Do not implement anything. Only write the relevant phase/index files when appropriate.

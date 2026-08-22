---
name: focused-plan
description: Do not use this skill unless the user explicitly asks.
manual-only: true
---

Create a focused plan based on the task at hand.

The plan should break the task down so that it's clear what's actually going to be implemented:

- What new functions are going to be created?
- What code will be deleted?
- A list of new types/contracts, if any
- What new connections/third-party integrations will be made? Any deleted?
- Any new database access? Any cleanups? Migrations?
- Which existing utils/helpers can we re-use for this task?
- Do existing utils/helpers need to be updated? Do new ones need to be created?

When building the plan, think of the leanest solution first. It should re-use any existing infrastructure and utils/helpers before offering new code. Check `docs/utils.md` for possible references.

**Guidelines**:

- Only plan for error handling at the beginning and endpoints of major flows, e.g at a controller, for an API request.
- Only mention meaningful additions/removals, not small changes.
- Avoid planning for fallbacks, excessive guardrails, and trying to handle everye edge case.

**Crucial**: use plain language in the plan. Only use technical jargon where necessary, but prefer simple verbs and ELI18 style language.

**Note**: we are only planning for now. Do not implement anything.

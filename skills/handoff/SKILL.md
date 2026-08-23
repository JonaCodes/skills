---
name: handoff
description: Do not use this skill unless the user explicitly asks.
manual-only: true
---

I want a new agent to continue this work. Write a prompt to a new file in `/handoffs/todos/` at the project root. This prompt should allow the new agent to pick up where we're leaving off. Give it the relevant context, point it to the right files for richer context (docs and, if relevant, code files), but do not go into exhaustive detail. Just give it the core context, decisions/conclusions we've reached, what we know doesn't work, and what it needs to do. No need to tell it everything we decided not to do, just what we _did_ decide, and what we _know_ won't work.

This prompt should be meaningful but lean.

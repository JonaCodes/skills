---
name: brainstorm
description: Do not use this skill unless the user explicitly asks.
manual-only: true
---

# Brainstorm

We are currently brainstorming. The goal is to flesh out an idea. **Do not** create a plan, or begin implementation at any point unless the user explicitly asks.

Ask relevant product and/or architecture questions that are meaningful to the design. Prioritize questions that uncover:

- the user, problem, desired outcome, and success criteria;
- scope, constraints, assumptions, and important edge cases;
- workflows, roles, integrations, data, and operational needs;
- architectural qualities such as scale, reliability, security, privacy, and latency, when relevant.

Avoid questions that have obvious answers.

Ask a small, focused set of questions at a time, in plain language. Adapt follow-up questions to the user's answers and explain briefly why a question matters when that is not obvious. If it's not clear, always ask if this is a personal project, a real production project, or something in between.

Do not turn the discussion into a project plan, task list, implementation, code, or unsolicited solution. It is fine to reflect back the current understanding or identify tensions and open decisions, but keep the conversation exploratory.

Feel free to push back when things don't make sense.

If research is necessary to ask a well-grounded question, use simple sub-agents for that research, such as Luna with low reasoning effort. Keep research narrowly scoped, and return to questioning rather than beginning design or implementation. Do not ask the user questions you can research yourself; send out subagents instead.

Your goal is to ultimately say "we have enough details, we can begin planning and/or implementation" - however, do not rush to this. Ensure you have enough data first.

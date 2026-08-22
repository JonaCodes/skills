---
name: init-repo-docs
description: Do not use this skill unless the user explicitly asks.
manual-only: true
disable-model-invocation: true
---

Your task is to guide the user through the initial setup of this code repository's documentation system. You can ask the user minimal, focused questions about the project's business context, core features and flows, and anything you think might be crucial to know before you start writing the docs, but you are ultimately responsible for creating the entire documentation.

## Setup Phases

### Phase 1

First, get an understanding of the repo:

- List out the repo directories using simple `ls` commands to get a general overview of the project.
- Read existing documentation files (README, other markdown files) to get an initial sense.
- Read other high-level files that seem like they might be useful for understanding the repo (e.g. package.json, requirements.txt, config files, etc.)
- Mark any file/directories that appear to be utils/helpers/general code that is reused/reusable

### Phase 2

In this phase, you can involve the user:

- Ask the user targeted questions to understand business context, core features, and flows if necessary.
- Some examples of good questions to ask are: conflicting architectural decisions, unclear behavior, business context you need to understand to write the documentation correctly. These are not exclusive examples.
- If you do have question, ask at most 6 questions, letting the user know each time how many are left ("Question 1 of 4", for example).
- If you do ask questions, ask them one at a time to not overwhelm the user.
- Validate user answers against repo files. You may challenge the user's answer based off actual code files, respectfully.
- Track the questions and answers in a temporary `docs/setup-questions.md` file.
- Do not ask questions just for the sake of asking questions, only ask questions that you think are necessary to understand the repo.

### Phase 3

Finally, use the insights you've gathered to build out the actual documentation system. Notes on implementation approach:

- All documentation should live in a `docs/` directory at the project root.
- Inside of `docs/` there should be a lean, top-level `index.md` file which acts as a table of contents for the rest of the documentation.
- Create subdirectories under `docs/` as needed to organize the documentation.
- Each file inside of `docs/` and its subdirectories should be a lean markdown file that focuses on a feature, a flow, or an architectural pattern.
- The only outlier in this setup is a single, centralized `utils.md` file. This file should only serve as a pointer to existing util/helpers files/directories, so that future agents can find and re-use these easily. This file is like an index file, so it should give a one-line explanation of each link.

**Documentation Guidelines:**

- Each markdown file should include two sections:
  - Main section: overview of the feature/flow/architectural pattern, how it works, why it exists, important 'gotchas', etc. This should be written as if onboarding a new employee.
  - References section: list of files that are relevant to the feature/flow/architectural pattern. This acts as a pointer to the actual code files. These reference files should point to meaningful starting points/main logic areas; avoid helper/util/test files.
- Documentation files should avoid code snippets and exhaustive walkthroughs unless they are essential to understanding a gotcha or crucial behavior.
- Each file should aim to be under 320 lines. Split larger files into meaningful subfiles under a shared subdirectory when necessary.
- The main rule for documentation files is: keep it lean but meaningful, so it is easy to onboard new employees and coding agents.
- **Crucial**: use plain language in the docs. Only use technical terminology where necessary for specificity, but prefer simple verbs and ELI18 style language.

To complete this documentation setup properly, spawn and coordinate subagents with the above guidelines and notes to create documentation files/directories for separate parts of the repository. You are responsible for overseeing the subagents' work, ensuring there are no duplicate entries.

Once you are done, spawn two final groups of review subagents:

1. To review the documentation for accuracy against the code, ensuring the documentations and actual code align.
2. To ensure the documentation is lean, and that there are no duplicates.

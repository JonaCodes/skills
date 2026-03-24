---
name: update-md
description: Update one or more `.md` file(s)
disable-model-invocation: true
---

Read the marldown file(s) in $ARGUMENTS. Either use your direct memory if you have it (preferred), or run `git status` and `git diff` to see what updates we've made. Do not look for the entire branch commit history. Update $ARGUMENTS to ensure the file(s) align with any changes.

## Guidelines

1. Do not bloat any markdown files
2. The purpose of these files are to onboard future developers - they needs to be lean but useful
3. The goal of this update is to align $ARGUMENTS to reflect the current state of the code
4. It is possible no or very minimal changes need to be made
5. If needed, create new markdown files

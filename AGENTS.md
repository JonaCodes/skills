Read the README.md for context on this project.

- Keep the real resource files in this repository.
- When creating a new skill, symlink it into both `.claude` and `.codex` so both agents use the same source of truth.
- Hooks and agents work automatically because their whole directories are symlinked.
- Handle other files as needed. If it is unclear, ask the user what to do and explain it in ELI5 terms.

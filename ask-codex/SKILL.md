---
name: ask-codex
description: Run Codex CLI with a prompt, letting Codex search through repo files
---

## Execution

1. Run `list-models.sh` to refresh the cache if needed, then read the cache file directly:

   ```bash
   bash /Users/jona/.claude/skills/ask-codex/list-models.sh
   ```

   ```
   /Users/jona/.claude/skills/ask-codex/cached-codex-models.txt
   ```

   Use all non-comment lines (lines not starting with `#`) as the model list.

2. Output a numbered model menu in your response and wait for the user to reply with a number:
   Pick a model (reply with a number):
   **1.** Auto (default: gpt-5.3-codex / medium)
   **2.** gpt-5.4
   **3.** gpt-5.3-codex
   ... (all models from cache, in order)

3. If the user picked **1 (Auto)**: skip to step 5 — run without `--model` or `--effort`.

4. If the user picked a specific model: output a numbered effort menu and wait for a reply:
   Pick an effort level (reply with a number):
   **1.** Auto (default: medium)
   **2.** low
   **3.** medium
   ... (that model's supported efforts from the cache line, in order)
   If the user picks **1 (Auto)**: omit `--effort`.

5. Run the script with the ARGUMENTS prompt, adding `--model` and `--effort` only for non-Auto selections:

   ```bash
   bash /Users/jona/.claude/skills/ask-codex/ask-codex.sh "<prompt>" [--model MODEL] [--effort EFFORT]
   ```

6. Check the exit code:
   - **Exit code 0**: Success — present the output to the user.
   - **Exit code 1**: Codex failed — show the error to the user.
   - **Exit code 2**: The model was rejected as invalid. The model cache has been cleared automatically. Inform the user: "The selected model was rejected by Codex as invalid. The model cache has been cleared. Please re-run `/ask-codex` to pick from a refreshed model list."

## Parameters

- **Prompt** (required): The question or task from ARGUMENTS. Codex will search the repo for relevant files.
- `--model MODEL` (optional): Omit to use script default. Pass the slug chosen by the user.
- `--effort EFFORT` (optional): Omit to use script default. Pass the effort chosen by the user.

---
name: wt-cleanup
description: Safely remove a completed local worktree and its local branch after its changes are pushed.
disable-model-invocation: true
---

The relevant changes have been pushed to remote and this local worktree is no longer needed.

Clean it up using Git-supported worktree commands:

- Confirm the current worktree path and branch.
- Verify there are no uncommitted changes.
- Use `git worktree remove <path>` to remove the worktree.
- Delete the local branch only after confirming it is merged or pushed.
- Run `git worktree prune` afterward to clean stale worktree metadata.

Do not manually delete the worktree directory unless `git worktree remove` fails and the reason is understood.
Do not delete remote branches unless explicitly requested.
Do not remove unrelated worktrees, branches, or repository objects.

# Coding Agent Resources

## Intro (written by me)

This is a collection of skills, hooks, subagents, and coding guidelines I've created that works for my specific workflow. I'm sharing it because it may be helpful for others as a starting point/inspiration for how to set up their own.

Currently I work with Codex (hence all the toml/yaml files), but this should be robust enough and easy to change to be used with other agents.

Note: I keep this all in one repo. Partly this is because it makes it easier to share, and partly because then I can have each coding agent symlink to one source of truth for all my important hooks/skills etc. This **won't** work out of the box for non-Codex agents yet, but next time I change agents, I'll make sure it does.

Most of the files should be self explanatory. Some of the hooks work as bundles. Read more [here](hooks.md).

Symlink instructions below. Let your agent set it up.

## Agent instructions (written by Codex)

When setting up or repairing this repository:

1. Keep the real resource files in this directory.
2. Set the repository and Codex locations for the current machine, then create symlinks from Codex's expected locations back to the canonical resources. For example:

   ```sh
   RESOURCE_REPO="/path/to/coding-agent-resources"
   CODEX_ROOT="${CODEX_HOME:-$HOME/.codex}"

   ln -s "$RESOURCE_REPO/skills/project-context" "$CODEX_ROOT/skills/project-context"
   ln -s "$RESOURCE_REPO/agents" "$CODEX_ROOT/agents"
   ln -s "$RESOURCE_REPO/hooks" "$CODEX_ROOT/hooks"
   ln -s "$RESOURCE_REPO/hooks.json" "$CODEX_ROOT/hooks.json"
   ```

3. Link custom skill directories individually. Do not replace the entire `$CODEX_ROOT/skills` directory, because Codex manages `.system` there.
4. Keep machine-specific or local-only resources outside this repository.
5. Before replacing an existing file or directory, move it to a temporary backup, create the symlink, and verify both `test -L <link>` and `test -e <link>` succeed.
6. Do not commit credentials, caches, sessions, generated state, or other private application data. Do not commit or push unless the user explicitly requests it.

Symlinks make edits effectively bidirectional: editing through `.codex`, `.claude`, or another linked location updates the same canonical file immediately. This avoids duplicate copies drifting apart and prevents Git from seeing the rest of each agent's private configuration directory.

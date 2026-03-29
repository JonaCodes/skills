---
name: feature-map-init
description: Bootstrap an initial `.ai/feature-map.yaml` from developer-authored `.ai/feature-seeds.yaml`, performing a deeper scan so the first map separates each feature's primary implementation files from its adjacent high-signal supporting files.
disable-model-invocation: true
---

# Feature Map Init

Use this skill for first-time setup or a deliberate full rebuild of the feature map. Treat `.ai/feature-seeds.yaml` as the bootstrap input and `.ai/feature-map.yaml` as the generated navigation artifact.

The seeds are a developer-authored starting taxonomy, not an exhaustive list of implementation layers. Developers usually describe user-facing workflows more confidently than architectural seams. Your job is to preserve the seeded feature names while doing a deeper repo scan that captures both the primary implementation files for each workflow and the adjacent high-signal supporting files needed to modify that workflow safely.

The `scripts/` paths in this skill are bundled with the skill itself, not with the target repository. Run them from the skill directory, or otherwise use the bundled script path with `--repo-root <target-repo>`.

## Workflow

1. Run the bundled `scripts/ensure_feature_seeds.py --repo-root <target-repo>` before any repo exploration.
2. If it exits non-zero, stop immediately. Do not inspect the repo further, do not infer features, and do not generate `.ai/feature-map.yaml`.
3. If the bundled script cannot be run, manually create `<target-repo>/.ai/feature-seeds.yaml` with the commented template from this skill, then stop immediately.
4. Read `<target-repo>/.ai/feature-seeds.yaml`.
5. Read the existing `<target-repo>/.ai/feature-map.yaml` if it exists so you can replace or refresh it intentionally rather than drifting blindly.
6. For each seeded feature, start with repo search against the feature name and description, then inspect the most likely entrypoints.
7. Run the bundled `scripts/trace_flow.py --repo-root <target-repo> <file>` on promising entrypoints to gather deterministic neighboring files.
8. Build each map entry with four fields:
   - `name`
   - `description`
   - `core_files`: the files most directly responsible for the feature's primary behavior
   - `supporting_files`: adjacent high-signal files that help explain or safely modify the feature, such as app shells, bridge/protocol boundaries, shared contracts, config/state surfaces, service entrypoints, or general architecture files
9. Keep `core_files` focused on the feature's main implementation path. Do not fill `core_files` with same-layer files if a better cross-layer split would make the map clearer.
10. Keep `supporting_files` optional and lean. Use it when it materially improves navigation; omit it when there is no useful supporting context.
11. Prefer the concrete path a maintainer would most likely touch first: UI entrypoints, app shells, route handlers, service boundaries, bridge/protocol files, config/state surfaces, and one useful test.
12. After generating the map, tell the developer:
    `I created the initial feature map from your seeded features. From this point on, the map is the working source of truth for code navigation, and future maintenance updates the map directly based on repo changes. If you want, I can also install a pre-commit hook to keep it in sync automatically.`
13. If the developer wants the hook, run the bundled installer script.

## Rules

- Use the seeds only for initialization and deliberate full rebuilds.
- Do not invent new feature names unless the user explicitly asks.
- If a feature is missing from `.ai/feature-seeds.yaml`, stop and ask for it to be added there first.
- Do not document every file in the repo.
- Do not add prose descriptions for individual files.
- Keep descriptions brief but meaningful.
- Do not require the developer to pre-seed every architectural layer just to get a useful map.
- It is valid for a seeded user-facing feature to map to shared architectural or cross-cutting files when those files are real supporting context for that feature.
- Do not invent a new seed merely because you found a shared layer; capture it under `supporting_files` when it is clearly supporting an existing feature.
- Treat the initializer as a deep scan, but keep the output compact and useful for navigation.
- When blocked on missing or empty seeds, tell the developer plainly that you created or found `<target-repo>/.ai/feature-seeds.yaml` and that they need to edit it before you can continue.
- Explain why in one sentence: the feature list must come from them so the map does not invent its own taxonomy.
- Do not frame the blocked state as a long story about what you tried. Keep it short and directive.

## Artifact Shape Examples

`.ai/feature-seeds.yaml`

```yaml
features:
  - name: sign-in
    description: User signs in with email and password
```

`.ai/feature-map.yaml`

```yaml
features:
  - name: sign-in
    description: User signs in with email and password
    core_files:
      - app/routes/sign-in.tsx
      - app/api/auth/sign-in/route.ts
      - lib/auth/credentials.ts
    supporting_files:
      - lib/auth/session.ts
      - tests/sign-in.spec.ts
```

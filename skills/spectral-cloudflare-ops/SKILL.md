---
name: spectral-cloudflare-ops
description: Safely inspect and update Spectral Cloudflare resources, especially R2 CORS for public downloads
---

Use this skill when managing Cloudflare resources for the Spectral Notes project.

## Safety Rules

1. Work from the Spectral Notes repo root unless the user gives another path:

   ```bash
   cd /Users/jona/Documents/projects/spectral-notes
   ```

2. Load deploy environment values only through repo helpers. Do not print `.env.deploy.local`, Cloudflare tokens, account IDs, or raw environment values.

3. For any Cloudflare mutation:
   - read current remote state first
   - run a dry run and show the exact proposed policy/change
   - wait for explicit user approval before applying
   - read back remote state after applying
   - verify the public behavior when possible

4. Keep changes narrow. Do not combine unrelated Cloudflare changes in one operation.

## R2 CORS

Use the bundled script for R2 CORS work:

```bash
node /Users/jona/.claude/skills/spectral-cloudflare-ops/scripts/configure-r2-cors.mjs --origin <origin>
```

The script defaults to dry-run. It reads the current bucket CORS policy, adds the requested origin to the existing public-downloads rule, prints the proposed policy, and exits without mutating Cloudflare.

Apply only after explicit user approval:

```bash
node /Users/jona/.claude/skills/spectral-cloudflare-ops/scripts/configure-r2-cors.mjs --origin <origin> --apply
```

Verify a public object response for that origin:

```bash
node /Users/jona/.claude/skills/spectral-cloudflare-ops/scripts/configure-r2-cors.mjs \
  --origin <origin> \
  --verify-url https://pub-88e05da057b5462fa65539f5a5d2f8f0.r2.dev/desktop/windows/latest.json
```

Expected verification includes:

```text
access-control-allow-origin: <origin>
```

## Required Env Vars

The script uses the repo's `scripts/release-shell.mjs` helper to load `.env.deploy.local`, then requires:

- `CLOUDFLARE_ACCOUNT_ID`
- `CLOUDFLARE_R2_API_TOKEN`
- `R2_DESKTOP_BUCKET`

Do not display their values.

## Common Origins

Current public-download origins include:

- `https://spectral-notes.pages.dev`
- `https://meet-spectral.pages.dev`
- `http://localhost:5173`
- `http://127.0.0.1:5173`

When a landing/app origin changes, update R2 CORS before expecting browser JavaScript to fetch R2 metadata.

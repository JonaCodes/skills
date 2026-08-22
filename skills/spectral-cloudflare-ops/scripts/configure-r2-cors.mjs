#!/usr/bin/env node

import path from "node:path";
import { pathToFileURL } from "node:url";

const PUBLIC_DOWNLOADS_RULE_ID = "spectral-notes-public-downloads";
const DEFAULT_REPO_ROOT = "/Users/jona/Documents/projects/spectral-notes";

const args = parseArgs(process.argv.slice(2));
const repoRoot = path.resolve(args.repo ?? process.cwd());
const releaseShellUrl = pathToFileURL(
  path.join(repoRoot, "scripts", "release-shell.mjs"),
).href;

const { loadDeployEnv, requireEnvVars } = await import(releaseShellUrl);

loadDeployEnv();
requireEnvVars([
  "CLOUDFLARE_ACCOUNT_ID",
  "CLOUDFLARE_R2_API_TOKEN",
  "R2_DESKTOP_BUCKET",
]);

const bucketName = process.env.R2_DESKTOP_BUCKET;
const endpoint = buildCorsEndpoint({
  accountId: process.env.CLOUDFLARE_ACCOUNT_ID,
  bucketName,
});

if (args.verifyUrl) {
  requireArg(args.origin, "--origin is required with --verify-url");
  await verifyPublicCors({ origin: args.origin, url: args.verifyUrl });
  process.exit(0);
}

const origin = parseSerializedOrigin(args.origin);

const currentPolicy = await readCorsPolicy(endpoint);
const updatedPolicy = addOriginToPolicy(currentPolicy, origin);

console.log(
  JSON.stringify(
    {
      dryRun: !args.apply,
      bucket: bucketName,
      addedOrigin: origin,
      policy: updatedPolicy,
    },
    null,
    2,
  ),
);

if (!args.apply) {
  console.log("\nDry run only. Re-run with --apply to update R2 CORS.");
  process.exit(0);
}

await putCorsPolicy(endpoint, updatedPolicy);
const readBack = await readCorsPolicy(endpoint);

console.log(
  JSON.stringify(
    {
      applied: true,
      bucket: bucketName,
      addedOrigin: origin,
      readBack,
    },
    null,
    2,
  ),
);

function parseArgs(argv) {
  const parsed = {
    apply: false,
    origin: null,
    repo: DEFAULT_REPO_ROOT,
    verifyUrl: null,
  };

  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index];
    if (arg === "--apply") {
      parsed.apply = true;
    } else if (arg === "--origin") {
      parsed.origin = argv[++index];
    } else if (arg === "--repo") {
      parsed.repo = argv[++index];
    } else if (arg === "--verify-url") {
      parsed.verifyUrl = argv[++index];
    } else if (arg === "--help" || arg === "-h") {
      printUsage();
      process.exit(0);
    } else {
      throw new Error(`Unknown argument: ${arg}`);
    }
  }

  return parsed;
}

function printUsage() {
  console.log(`Usage:
  configure-r2-cors.mjs --origin <origin> [--apply] [--repo <repo-root>]
  configure-r2-cors.mjs --origin <origin> --verify-url <public-r2-url>

Examples:
  configure-r2-cors.mjs --origin https://meet-spectral.pages.dev
  configure-r2-cors.mjs --origin https://meet-spectral.pages.dev --apply
`);
}

function requireArg(value, message) {
  if (!value) throw new Error(message);
}

function parseSerializedOrigin(value) {
  requireArg(value, "--origin is required");

  let url;
  try {
    url = new URL(value);
  } catch {
    throw new Error(`Invalid origin: ${value}`);
  }

  if (!["http:", "https:"].includes(url.protocol)) {
    throw new Error(`Origin must use http or https: ${value}`);
  }

  if (url.href !== `${url.origin}/`) {
    throw new Error(
      `Origin must not include a path, query, hash, or trailing slash: ${value}`,
    );
  }

  return url.origin;
}

function buildCorsEndpoint({ accountId, bucketName }) {
  return `https://api.cloudflare.com/client/v4/accounts/${encodeURIComponent(
    accountId,
  )}/r2/buckets/${encodeURIComponent(bucketName)}/cors`;
}

async function readCorsPolicy(endpoint) {
  const response = await fetch(endpoint, {
    headers: cloudflareHeaders(),
  });
  const body = await readJsonResponse(response);

  if (!response.ok || body.success === false) {
    failCloudflareRequest("read", response, body);
  }

  return body.result ?? { rules: [] };
}

async function putCorsPolicy(endpoint, policy) {
  const response = await fetch(endpoint, {
    method: "PUT",
    headers: {
      ...cloudflareHeaders(),
      "Content-Type": "application/json",
    },
    body: JSON.stringify(policy),
  });
  const body = await readJsonResponse(response);

  if (!response.ok || body.success === false) {
    failCloudflareRequest("apply", response, body);
  }
}

function addOriginToPolicy(policy, origin) {
  const rules = Array.isArray(policy.rules) ? policy.rules : [];
  const targetRule = rules.find(
    (rule) => rule?.id === PUBLIC_DOWNLOADS_RULE_ID,
  );

  if (!targetRule) {
    throw new Error(
      `Expected CORS rule not found: ${PUBLIC_DOWNLOADS_RULE_ID}`,
    );
  }

  const origins = Array.from(
    new Set([...(targetRule.allowed?.origins ?? []), origin]),
  );
  const updatedRule = {
    ...targetRule,
    allowed: {
      ...targetRule.allowed,
      origins,
    },
  };

  return {
    rules: rules.map((rule) => (rule === targetRule ? updatedRule : rule)),
  };
}

async function verifyPublicCors({ origin, url }) {
  const response = await fetch(url, {
    method: "HEAD",
    headers: { Origin: origin },
  });

  const selectedHeaders = {};
  for (const name of [
    "access-control-allow-origin",
    "access-control-expose-headers",
    "content-type",
    "content-length",
    "etag",
    "last-modified",
  ]) {
    selectedHeaders[name] = response.headers.get(name);
  }

  console.log(
    JSON.stringify(
      {
        ok: response.ok,
        status: response.status,
        origin,
        url,
        headers: selectedHeaders,
      },
      null,
      2,
    ),
  );
}

function cloudflareHeaders() {
  return {
    Authorization: `Bearer ${process.env.CLOUDFLARE_R2_API_TOKEN}`,
  };
}

async function readJsonResponse(response) {
  try {
    return await response.json();
  } catch {
    return { raw: await response.text() };
  }
}

function failCloudflareRequest(step, response, body) {
  console.error(
    JSON.stringify(
      {
        step,
        status: response.status,
        success: body.success,
        errors: body.errors,
      },
      null,
      2,
    ),
  );
  process.exit(1);
}

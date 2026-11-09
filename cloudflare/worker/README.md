# Cloudflare Player Worker (Phase 2 template)

This Worker is intentionally not deployed yet. It is a Phase 2 template to be used only after the local Processing/CheerpJ PoC works.

## Responsibilities

- Serve the player HTML/CSS/JS from `../../public` using Workers Static Assets.
- Intercept `/works/*` requests before static assets.
- Map `/works/{workId}/{version}/{relativePath}` to the private R2 key `published/{workId}/{version}/{relativePath}`.
- Allow only GET and HEAD; support Range reads via the R2 binding.
- Never expose source ZIPs or arbitrary private prefixes.

## Before running

1. Create the private R2 bucket `processing-works-dev` from the Cloudflare Dashboard.
2. Authenticate Wrangler: `npx wrangler login`.
3. Confirm bucket visibility: `npx wrangler r2 bucket list`.
4. Review `wrangler.jsonc`, especially the bucket name and assets directory.

## Local Worker test

From this directory:

```bash
npm install
npx wrangler dev
```

For real R2 access in local development, configure a remote R2 binding according to the current Wrangler remote-bindings docs. Do not point a public Worker at the bucket until the published-prefix access rule and range tests are complete.

## Deploy

```bash
npx wrangler deploy
```

The first deploy should use the generated `workers.dev` address. Do not configure a custom domain or change DNS at this stage.

## Important

This source is a starter implementation, not yet production-audited. Test 200, 206, HEAD, invalid path, missing object, cache headers, and content type before deploying publicly. It intentionally has no upload, list, or delete endpoints.

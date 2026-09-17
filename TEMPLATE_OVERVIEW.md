# Duplicati on Railway — Encrypted Backups of Your Data to Your Own Bucket

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/waF4pp)

Duplicati is a battle-tested backup agent: incremental, compressed, and encrypted **client-side with AES-256 before anything leaves your container**. This template deploys it with zero deploy-time prompts and no pre-required credentials — everything secret is generated per deployment, and a demo data folder plus a local backup destination are pre-wired so your first backup round-trip takes about a minute.

## What this template provisions

- **One service** (`duplicati`) built from the pinned upstream image `duplicati/duplicati:2.4.0.0` (source: https://github.com/lNamelessl/duplicati-railway-template), web UI on port 8200 exposed at your Railway domain.
- **One volume** mounted at `/data` — Duplicati's config database and job state. Boot scripts expose two extra persistent paths on that volume: `/source` (data to protect, seeded with demo files on first boot only) and `/backups` (a ready local-folder backup destination).
- **A public domain** routed to the UI, plus a healthcheck (`/`, 300 s timeout) and an auto-restart policy.

## Deploy-form variables — none to fill in

Every variable ships an expression default, so the one-click deploy asks you nothing:

| Variable | Default |
|---|---|
| `DUPLICATI__WEBSERVICE_PASSWORD` | `${{ secret(24, "alnum") }}` — your UI login, regenerated per deployment |
| `SETTINGS_ENCRYPTION_KEY` | `${{ secret(64, "hex") }}` — encrypts the config database at rest |
| `DUPLICATI__WEBSERVICE_ALLOWED_HOSTNAMES` | `${{ RAILWAY_PUBLIC_DOMAIN }}` — keeps Duplicati's host-name protection strict |

After deploying, open your service's **Variables** tab (or run `railway variables`) to copy the generated `DUPLICATI__WEBSERVICE_PASSWORD`, then log in at your Railway domain.

## Your first backup in ~60 seconds

1. Log in to the UI with the generated password.
2. **Add backup** → source `/source/demo`, destination **Local folder** `/backups`.
3. Keep **AES-256** encryption, set a passphrase (store it in your password manager), save, **Run now**.
4. Watch encrypted `duplicati-*.zip.aes` files appear in `/backups`; test a **Restore** — files come back byte-identical.

For real offsite backups, create the job with your own S3 / B2 / Storj / SFTP / WebDAV / OneDrive target instead — you supply those credentials directly to Duplicati at job-creation time, post-deploy. The provider only ever stores ciphertext.

# Deploy and Host

Deploying gives you a working Duplicati server in about two minutes: one service, one persistent volume at `/data`, the UI at `https://<your-project>.up.railway.app`, and a login password generated at deploy time. Nothing else is required — the demo source data and local backup destination are created automatically on first boot, so you can prove the full backup → restore cycle before attaching any cloud storage. Jobs, schedules, and retention live in the config database on the volume and survive redeploys and restarts.

## About Hosting

Hosting Duplicati yourself means your data and your encryption keys never touch a third-party backup service. This template runs the official `duplicati/duplicati` image pinned to the stable `2.4.0.0` release, so behavior matches upstream documentation. The web UI is served on port 8200 and protected by a per-deployment generated password; unauthenticated API calls are rejected. The config database is encrypted at rest with the generated `SETTINGS_ENCRYPTION_KEY`. Railway attaches one volume per service, mounted here at `/data`, with `/source` and `/backups` exposed as persistent paths on that volume; data you place under `/source` (via `railway ssh` or pushes from other services) is backed up on schedule with client-side AES-256. Cost is roughly $5/month for the service plus storage; the demo footprint is a few megabytes.

## Why Deploy

- **Zero-prompt, zero-credential deploy:** secrets are generated per deployment as expression defaults — you never type a password or a cloud key to get running.
- **Encryption before egress:** AES-256 client-side — your bucket provider (and Railway) never sees plaintext.
- **Railway-native durability:** config DB and data live on a persistent volume; redeploys keep your jobs, and the image tag is pinned for reproducible upgrades.
- **Instant proof:** the seeded `/source/demo` folder and `/backups` destination let you verify backup → encrypted storage → restore in about a minute, before you point anything at production data.

## Common Use Cases

- Offsite, encrypted backups of data you host on Railway (files, exports, dumps placed under `/source`).
- Scheduled versioned backups with retention (`1W:1D,4W:1W,12M:1M` style policies) to S3, Backblaze B2, Storj, SFTP, WebDAV, OneDrive, and other supported targets.
- A self-hosted restore point: pull files back into the container via the UI or `duplicati-cli` for verification or disaster recovery.
- Personal data protection: keep a server-side copy of documents, photos, and configuration in your own bucket rather than a vendor's managed backup.

## Dependencies for

Duplicati has no runtime service dependencies: it needs no database server (its config DB is embedded and stored on the `/data` volume) and no external broker. Cloud storage targets are optional and credential-free at deploy time.

### Deployment Dependencies

- A Railway account and this template — everything else is provisioned automatically (service, volume, public domain, generated secrets).
- Optional, post-deploy: credentials for your chosen cloud target (e.g. S3 access key + secret + bucket, B2 key ID + application key, Storj access grant, SFTP host + key). These are entered into the backup job in the Duplicati UI, not at deploy time.

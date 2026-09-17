# Duplicati on Railway

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/REPLACE_WITH_TEMPLATE_CODE)

Encrypted, incremental, scheduled backups — powered by [Duplicati](https://github.com/duplicati/duplicati) (pinned `2.4.0.0` stable), deployed in one click.

**The Railway-native pitch:** back up your Railway-hosted data to **your own** cloud storage — S3, Backblaze B2, Storj, SFTP, WebDAV, OneDrive, and more. Everything is encrypted **client-side with AES-256 before it leaves your container**: the storage provider never sees plaintext, and neither does Railway.

## What you get on deploy

Railway attaches **one volume per service** (platform limit), mounted here at `/data`. The boot script exposes three persistent paths on that single volume — all survive redeploys:

| Path | Purpose |
|---|---|
| `/data` | Duplicati's own config database + job state (native location). Your backup jobs survive redeploys. |
| `/source` (→ `/data/persist/source`) | Data to protect. Seeded with a small demo folder (`/source/demo`) so your first backup test takes ~60 seconds. |
| `/backups` (→ `/data/persist/backups`) | Ready-made local-folder destination for that first test run — no cloud credentials needed yet. |

> Attaching your own additional volume? Mount it at any free path (e.g. `/data-from-myapi`) and use that path as the backup job's source.

| Environment variable | Value on deploy |
|---|---|
| `DUPLICATI__WEBSERVICE_PASSWORD` | **Auto-generated per deploy** (24 alphanumeric chars). This is your web UI login. |
| `SETTINGS_ENCRYPTION_KEY` | **Auto-generated per deploy** (64 hex chars). Encrypts Duplicati's config database at rest (`DUPLICATI__DISABLE_DB_ENCRYPTION=false`). |
| `DUPLICATI__WEBSERVICE_ALLOWED_HOSTNAMES` | `${{RAILWAY_PUBLIC_DOMAIN}}` plus Railway's `healthcheck.railway.app` probe host. Keeps Duplicati's host-name protection strict — never `*`. |

## First backup in 60 seconds

1. Open your Railway deployment's public domain. Log in with `DUPLICATI__WEBSERVICE_PASSWORD` (find it under your service's **Variables** tab, or `railway variables`).
2. **Add backup** → name it, set source = `/source/demo`.
3. Destination → **Local folder** → `/backups` (or skip ahead to a real cloud target below).
4. Keep the default **AES-256** encryption, set a passphrase, save, then **Run now**.
5. Watch encrypted `duplicati-*.zip` files land in `/backups` — restore anytime from the UI (**Restore** → pick the destination → files come back byte-identical).

## Backing up to real cloud storage (credentials you supply, post-deploy)

Duplicati talks directly to your bucket — no credentials are needed at deploy time. Have these ready when you create the job in the UI:

| Target | What you'll need |
|---|---|
| **Amazon S3** (or any S3-compatible: MinIO, Cloudflare R2, iDrive e2) | Access key ID, secret key, bucket name, region/prefix |
| **Backblaze B2** | Key ID (account ID), application key, bucket name |
| **Storj** | Access grant (satellite address + key) |
| **SFTP** | Server, port, username, password or private key |
| **WebDAV** | Server URL, username, password |
| **OneDrive / Google Drive / Dropbox** | OAuth sign-in in the UI |

### Checklist for protecting your Railway-hosted data

- [ ] Put the data you want protected on this service's volume, under `/source` (copy it in via `railway ssh`, or have your other services push exports/snapshots here). This service's attached volume *is* a Railway volume — and its one-per-service limit is why data lands under `/source`.
- [ ] Create the job with your cloud target and **AES-256** encryption; store the passphrase in your password manager (there is no recovery without it).
- [ ] Set a schedule (default is fine) and retention (e.g. keep 30 days).
- [ ] Run once now, then test a **restore** — a backup you haven't restored isn't a backup.

## Security notes

- The UI is never reachable without credentials: the password is generated at deploy time and the API rejects unauthenticated requests.
- `DUPLICATI__WEBSERVICE_ALLOWED_HOSTNAMES` is pinned to your Railway domain (DNS-rebinding protection stays on).
- The config DB in `/data` is encrypted at rest with `SETTINGS_ENCRYPTION_KEY` — both are per-deploy generated; losing the service means losing the key, which is the intended trade-off.
- Backup payloads are encrypted client-side (AES-256) before upload. Your storage provider only ever stores ciphertext.

## Operations

- **Persistence:** job config lives in `/data` (volume), as do `/source` and `/backups` behind the symlinks. Redeploy, restart, crash — everything survives. The boot seeder never overwrites existing files.
- **Restore via CLI:** `railway ssh` into the service and use `duplicati-cli restore <destination> --restore-path=/restore-test ...` for scripted restores.
- **Upgrading:** the image tag is pinned for reproducibility. To upgrade, change the tag in the `Dockerfile` and redeploy — config DB migrations are handled by Duplicati at boot.
- **Healthcheck:** Railway probes `/` (the UI shell) with a 300 s start timeout; failed deploys restart automatically.

## Links

- Upstream: https://github.com/duplicati/duplicati
- Docs: https://docs.duplicati.com
- Forum: https://forum.duplicati.com

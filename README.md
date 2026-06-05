# N8N Production Stack with Self-Hosted Toolkit

[![n8n](https://img.shields.io/badge/n8n-EA4B71?style=for-the-badge&logo=n8n&logoColor=white)](https://n8n.io/)
[![Traefik](https://img.shields.io/badge/Traefik-24A1C1?style=for-the-badge&logo=traefikproxy&logoColor=white)](https://traefik.io/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-4169E1?style=for-the-badge&logo=postgresql&logoColor=white)](https://www.postgresql.org/)
[![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://www.docker.com/)
[![Hetzner](https://img.shields.io/badge/Hetzner-D50C2D?style=for-the-badge&logo=hetzner&logoColor=white)](https://www.hetzner.com/cloud)

Self-hosted n8n automation stack on a single Hetzner VPS. This repo holds the
Docker Compose stack (the deployment payload). Provisioning and deployment are
handled by the companion Infrastructure-as-Code repo
[**n8n-hetzner-deploy**](https://github.com/kfuras/n8n-hetzner-deploy)
(OpenTofu + Ansible). All external traffic terminates at Traefik v3 with
automatic Let's Encrypt TLS.

---

## What Gets Created

- **N8N** - Workflow automation platform with a dedicated PostgreSQL database
- **Traefik** - Reverse proxy with automatic SSL certificates via Let's Encrypt
- **Optional Services** - BaseRow, NocoDB, MinIO, Kokoro TTS, NCA Toolkit, Postiz (toggled per deployment)
- **Ubuntu server** with Docker and security hardening (provisioned by the deploy repo)
- **Pinned, auto-updated images** - the n8n version is pinned and bumped weekly by CI (see below)

---

## Cost Comparison

| Service                   | SaaS Monthly Cost | Self-Hosted      | Savings          |
|---------------------------|-------------------|------------------|------------------|
| TTS (ElevenLabs/OpenAI)   | $22-$330         | $0 (Kokoro)      | $22-$330        |
| Storage (AWS S3)          | $23+             | $0 (MinIO)       | $23+            |
| Automation (Zapier)       | $20-$600         | $0 (n8n)         | $20-$600        |
| Video processing (API)    | $15-$250         | $0 (NCA Toolkit) | $15-$250        |
| Database (Airtable)       | $20-$54          | $0 (NocoDB/Baserow) | $20-$54      |
| Social publishing (Buffer)| $6-$120          | $0 (Postiz)      | $6-$120         |
| **Total**                 | **$106-$1,674/mo**| **EUR 9.99/mo** | **$96-$1,664/mo** |

Runs on a single Hetzner VPS (from EUR 9.99/month) with 20 TB traffic included.

---

## How It's Deployed

Deployment is **pull-based Infrastructure-as-Code**, driven entirely from the
[n8n-hetzner-deploy](https://github.com/kfuras/n8n-hetzner-deploy) repo:

1. **OpenTofu** provisions the Hetzner server, firewall, and DNS expectations.
2. **Ansible** (`make deploy`) configures the host, clones this repo onto the
   server, generates secrets, and brings the stack up with Docker Compose.
3. Re-running `make deploy` is **idempotent** - it fast-forwards the server to
   the latest commit of this repo only when there is something new, then
   reconciles the running containers.

You do not deploy from this repo directly; you change the stack here, and the
deploy repo rolls it out.

### Secrets

- Secrets are **generated on the server** on first deploy (`openssl rand`) and
  written to `~/stack/.env` with `0600` permissions.
- **No real secrets are committed to git** - only [`secrets/production.env.example`](secrets/production.env.example), the template of expected keys.
- The `N8N_ENCRYPTION_KEY` is the critical value: if lost, stored n8n
  credentials become unreadable. Back it up off-server (e.g. a password
  manager) after the first deploy.
- See the deploy repo for how secrets and per-service values are seeded.

### Configure (keys you set)

In the deploy repo's variables / on first run:

- `DOMAIN` - your domain name
- `HOME_IP` - your IP address (used for optional service allowlisting)
- (Optional) `SKOOL_EMAIL`, `SKOOL_PASSWORD`, `SKOOL_GROUP_ID` - for personal Skool automation workflows

After DNS propagates, open `https://n8n.yourdomain.com`.

---

## Automated n8n Updates

A weekly GitHub Action ([`.github/workflows/update-n8n.yml`](.github/workflows/update-n8n.yml))
keeps the pinned n8n image current:

- Runs Mondays 06:00 UTC (plus manual `workflow_dispatch`).
- Checks Docker Hub for the newest **stable** `n8nio/n8n` tag (ignores `latest`/`next`/`nightly`/`-rc`).
- If newer than the pinned tag, it bumps `docker-compose.yml`, opens a PR, and auto-merges it.
- This only updates the repo; the new version rolls out on the next `make deploy`.

---

## Service URLs

- **N8N**: `https://n8n.yourdomain.com` (UI and webhooks)
- **BaseRow**: `https://baserow.yourdomain.com`
- **NocoDB**: `https://nocodb.yourdomain.com`
- **MinIO Console**: `https://minio-console.yourdomain.com`
- **Postiz**: `https://postiz.yourdomain.com`

(Only the subdomains for enabled services are routed.)

---

## Day-to-Day Operations

### Modify the stack

```bash
# Edit a compose file, then commit and push
nano docker-compose.yml
git commit -am "Update stack"
git push
# Roll out from the deploy repo:
#   cd ../n8n-hetzner-deploy && make deploy
```

### Rotate or change a secret

Secrets live in `~/stack/.env` on the server (not in git). SSH to the host,
edit the value, and restart:

```bash
nano ~/stack/.env
docker compose --env-file ~/stack/.env up -d
```

### View logs

```bash
docker compose logs -f n8n-core
docker compose ps
```

---

## Security

- **No secrets in git** - only a template of expected keys is committed; real values are generated server-side.
- **TLS everywhere** - Traefik v3 with automatic Let's Encrypt certificates.
- **Host hardening** - SSH key-only auth and firewalling, provisioned via cloud-init in the deploy repo.
- **Optional IP allowlisting** - sensitive service subdomains can be restricted to `HOME_IP`.
- **Least exposure** - `.env` is `0600`; Ansible secret tasks use `no_log` so values never appear in deploy output.

> Note: Docker requires a plaintext `.env` at runtime, so secrets exist in
> cleartext on the host while containers run. This is inherent to self-hosted
> compute and is mitigated by least-privilege host access, not eliminated.

---

## Use Cases

- Automated video content creation
- AI-powered Telegram assistant
- Email and calendar automations
- Batch data processing
- High-volume text-to-speech (300+ requests/day)
- No-code database applications
- Social media content scheduling

---

## Links

- [Blog](https://kjetilfuras.com)
- [LinkedIn](https://www.linkedin.com/in/kjetil-furas/)

---

Built by Kjetil Furås. Questions? Open an issue.

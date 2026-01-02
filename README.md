# n8n Production Stack with Self-Hosted AI Toolkit
This is my actual production n8n + AI infrastructure. Clone it as a template to run the same stack with your own credentials.

Production-proven automation stack with encrypted GitOps workflows. Run n8n plus supporting AI services on a single Hetzner VPS with safe, reproducible deployments.

---

## Architecture

```text
          +-----------+        +-----------+
 HTTPS -->|  Traefik  | -----> |    n8n    |
          +-----------+        +-----+-----+
                                      |
                                      +--> PostgreSQL 16 (state)
                                      +--> MinIO (S3-compatible storage)
                                      +--> Kokoro TTS (self-hosted voice)
                                      +--> NCA Toolkit (video processing)
```

All external traffic terminates at Traefik v3 with automatic TLS certificates and per-service access control.

---

## Cost Comparison (Indicative)

| Service                   | SaaS Monthly Cost | Self-Hosted      | Est. Savings    |
|---------------------------|-------------------|------------------|-----------------|
| TTS (ElevenLabs/OpenAI)   | \$22-$330         | \$0 (Kokoro)      | \$22-$330       |
| Storage (AWS S3) **       | \$23+             | \$0 (MinIO)       | \$23+           |
| Automation (Zapier) **    | \$20-$600         | \$0 (n8n)         | \$20-$600       |
| Video processing (API) ** | \$15-$250         | \$0 (NCA Toolkit) | \$15-$250       |
| **Total**                 | **\$80-$1,480/mo**| **EUR 24.49/mo**  | **\$55.51-$1,455.51/mo** |

_Indicative SaaS figures reflect commonly advertised mid-tier plans. Actual savings depend on usage._

Runs on a single Hetzner ( EUR 9.9/month) with 20 TB traffic included. Enabling Hetzner backups adds 20% of the instance price (about EUR 4.90 extra).

---

## Tech Stack

- n8n: workflow automation (Zapier alternative)
- Traefik v3: reverse proxy with ACME TLS and IP allow lists
- PostgreSQL 16: durable workflow state
- MinIO: S3-compatible object storage
- Kokoro TTS: self-hosted text-to-speech API
- NCA Toolkit: FFmpeg-based video rendering API
- SOPS + age: reproducible, encrypted secrets

---

## Security Features

- GitOps workflow with repeatable, auditable deployments
- Secrets encrypted at rest with SOPS + age
- GitHub Actions auto-deploy via self-hosted runner + `scripts/deploy.sh`
- Traefik TLS everywhere plus optional IP allow listing (HOME_IP)
- No plaintext secrets committed; `.env` is generated on deploy
- Defense in depth with Docker networks and host firewall

_Never commit private keys or unencrypted `.env` files. Track only the encrypted blob._

---

## Use Cases

- Automated video content creation
- AI-powered Telegram assistant
- Email and calendar automations
- Batch data processing
- High-volume text-to-speech (300+ requests/day)

---

## Learn From This Repo

1. SOPS workflows keep production secrets safe in a public repo.
2. Self-hosted runner GitOps: merge to main → Actions redeploys automatically.
3. Self-hosted versus SaaS cost model with real numbers.
4. Production Docker patterns: networking, health checks, logging.

---

## Quick Start

### Prerequisites

- Ubuntu or Debian host with DNS pointing at your server
- Docker Engine and Docker Compose v2
- `age` and `sops` installed locally
- Recommended: Hetzner Cloud firewall and automated OS updates

### Install Tooling

```bash
sudo apt-get update
sudo apt-get install -y docker.io docker-compose-plugin age

wget https://github.com/mozilla/sops/releases/latest/download/sops-linux-amd64 -O sops
sudo install -m 0755 sops /usr/local/bin/sops
rm sops
```

### Clone the Repository

```bash
git clone https://github.com/kfuras/n8n-production.git
cd n8n-production
```

### First-Time Secrets Setup

1. Copy the example env file and create a local `.env`.

   ```bash
   cp secrets/production.env.example .env
   nano .env
   ```

2. Fill in every value (hostnames, passwords, HOME_IP, and so on) and keep the file private on the server.

### Required Secrets

- `POSTGRES_*`, `N8N_*`, and `GENERIC_TIMEZONE` for n8n
- `ACME_EMAIL` for Traefik certificates
- `MINIO_*` credentials and hostnames
- `NCA_*` API keys for the toolkit
- `HOME_IP` for the MinIO console IP allow list

> Want to track secrets in git and let the server auto-deploy? Jump to [Advanced: GitOps + Encrypted Secrets (SOPS)](#advanced-gitops--encrypted-secrets-sops).

### One-Time Traefik ACME Setup

Ensure the hostnames in `secrets/production.env.example` resolve to your server and that `ACME_EMAIL` is set before the first run. Traefik will request and renew certificates automatically.

### Manual Deploy

```bash
docker compose pull
docker compose up -d
```

Your `.env` now contains production secrets; lock down file permissions and rotate values regularly.

---

## Advanced: GitOps + Encrypted Secrets (SOPS)

Set this up when you want hands-off deployments and encrypted secrets committed to the repo.

### Configure SOPS for Encrypted Secrets

1. Generate an age key pair (store `keys.txt` safely and never commit it).

   ```bash
   mkdir -p ~/.config/sops/age
   age-keygen -o ~/.config/sops/age/keys.txt
   chmod 600 ~/.config/sops/age/keys.txt
   ```

2. Add the public key (the line starting with `age1`) to your local SOPS config. Update `.sops.yaml` if you fork this repo and want to use a different recipient.

3. Create `secrets/production.env` by copying your `.env`, then encrypt it.

   ```bash
   cp .env secrets/production.env
   sops --encrypt --input-type binary --output-type binary secrets/production.env > secrets/production.env.enc
   shred -u secrets/production.env
   ```

4. Commit `secrets/production.env.enc` to git so the server can pull it. `.env` stays ignored and is generated at deploy time.

When deploying manually with SOPS, decrypt before running compose:

```bash
export SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt
sops -d secrets/production.env.enc > .env
docker compose up -d
shred -u .env
```

### GitHub Actions Auto-Deploy

Pushes to `main` flow through GitHub Actions:

1. `.github/workflows/trigger-deploy.yml` fires only when `docker-compose.yml`, `secrets/production.env.enc`, or `scripts/deploy.sh` change.
2. That workflow dispatches a private repository workflow that runs on a self-hosted runner on the server.
3. The dispatch includes the latest commit message (fallback: short SHA) as `deployment_name`. The private workflow runs `scripts/deploy.sh` with `FORCE_DEPLOY=1`, so the deploy happens even if the local clone already matches origin. Logs still land in `deploy.log`.

#### `scripts/deploy.sh` (Excerpt)

```bash
#!/bin/bash
set -euo pipefail

REPO_DIR="/home/kaf/docker/n8n-stack"
LOG_FILE="/home/kaf/docker/n8n-stack/deploy.log"

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

log "Checking for updates..."
git fetch origin main
LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse origin/main)

FORCE_DEPLOY=${FORCE_DEPLOY:-0}
WATCHED_FILES=("docker-compose.yml" "secrets/production.env.enc" "scripts/deploy.sh")

if [ "$LOCAL" = "$REMOTE" ] && [ "$FORCE_DEPLOY" != "1" ]; then
    log "Already up to date"
    exit 0
fi

# ...detects if any watched file changed upstream or FORCE_DEPLOY is set...

log "Decrypting secrets..."
sops -d secrets/production.env.enc > .env

log "Deploying containers..."
docker compose pull
docker compose up -d --remove-orphans
```

---

## Day-to-Day Operations

### Rotate or Add Secrets

```bash
sops secrets/production.env.enc
git add secrets/production.env.enc
git commit -m "chore: rotate secrets"
git push
```

### Modify Infrastructure

```bash
nano docker-compose.yml
git add docker-compose.yml
git commit -m "feat: update stack"
git push
```

### Roll Back

```bash
git log --oneline
git revert <sha>
git push
```

---

## Monitoring and Logs

```bash
docker compose ps            # Service status
docker compose logs -f n8n-core
tail -f deploy.log           # Cron deploy history
```

---

## License

MIT - make it your own.

---

## Links

- [Blog](https://kjetilfuras.com)
- [LinkedIn](https://www.linkedin.com/in/kjetil-furas/)
- [Skool community](https://www.skool.com/build-automate/about?ref=8708d3bb33f84fa2a3efd6b4ba05adb9)
---

Built by Kjetil Furås. Questions? Open an issue or reach out on LinkedIn.
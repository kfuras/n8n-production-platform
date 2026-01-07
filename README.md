# N8N Production Stack with Self-Hosted AI Toolkit

[![n8n](https://img.shields.io/badge/n8n-EA4B71?style=for-the-badge&logo=n8n&logoColor=white)](https://n8n.io/)
[![Traefik](https://img.shields.io/badge/Traefik-24A1C1?style=for-the-badge&logo=traefikproxy&logoColor=white)](https://traefik.io/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-4169E1?style=for-the-badge&logo=postgresql&logoColor=white)](https://www.postgresql.org/)
[![MinIO](https://img.shields.io/badge/MinIO-C72E49?style=for-the-badge&logo=minio&logoColor=white)](https://min.io/)
[![SOPS](https://img.shields.io/badge/SOPS-000000?style=for-the-badge&logo=mozilla&logoColor=white)](https://github.com/getsops/sops)
[![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://www.docker.com/)
[![Hetzner](https://img.shields.io/badge/Hetzner-D50C2D?style=for-the-badge&logo=hetzner&logoColor=white)](https://www.hetzner.com/cloud)
[![Skool Community](https://img.shields.io/badge/Skool-Build_&_Automate-FF6154?style=for-the-badge)](https://www.skool.com/build-automate)

Production-proven automation stack with encrypted GitOps workflows. Run n8n plus supporting AI services on a single Hetzner VPS with safe, reproducible deployments.

---

## What Gets Created

- **N8N** - Workflow automation platform with PostgreSQL database
- **Traefik** - Automatic SSL certificates via Let's Encrypt
- **Optional Services** - BaseRow, NocoDB, MinIO, Kokoro TTS, NCA Toolkit, Postiz
- **Ubuntu server** with Docker and security hardening
- **GitOps** - Encrypted secrets with SOPS, auto-deploy with GitHub Actions

All external traffic terminates at Traefik v3 with automatic TLS certificates.

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

Runs on a single Hetzner VPS (EUR 9.99/month cx43) with 20 TB traffic included.

---

## Quick Start

### Manual Deploy

1. **Clone repository**
   ```bash
   git clone https://github.com/build-automate/n8n-production-platform.git
   cd n8n-production-platform
   ```

2. **Install tools**
   ```bash
   sudo apt-get install -y docker.io docker-compose-plugin age
   wget https://github.com/mozilla/sops/releases/latest/download/sops-linux-amd64 -O sops
   sudo install -m 0755 sops /usr/local/bin/sops
   ```

3. **Configure**
   ```bash
   cp secrets/production.env.example .env
   nano .env
   ```
   
   Update:
   - `DOMAIN` - your domain name
   - `HOME_IP` - your IP address
   - Rotate all secrets for production

4. **Deploy**
   ```bash
   docker compose pull
   docker compose up -d
   ```

5. **Access**
   
   Open `https://n8n.yourdomain.com` after DNS propagates

---

## GitOps Setup (Optional)

For encrypted secrets and auto-deploy from GitHub:

### 1. Generate Age Key

```bash
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt
chmod 600 ~/.config/sops/age/keys.txt
```

### 2. Encrypt Secrets

```bash
cp .env secrets/production.env
sops --encrypt --input-type binary --output-type binary secrets/production.env > secrets/production.env.enc
shred -u secrets/production.env
git add secrets/production.env.enc
git commit -m "Add encrypted secrets"
```

### 3. Deploy with SOPS

```bash
export SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt
sops -d secrets/production.env.enc > .env
docker compose up -d
shred -u .env
```

### 4. Auto-Deploy (Optional)

Push to `main` triggers GitHub Actions. The workflow dispatches to a self-hosted runner that pulls changes and runs [scripts/deploy.sh](scripts/deploy.sh).

---

## Service URLs

- **N8N**: `https://n8n.yourdomain.com` (UI and webhooks)
- **BaseRow**: `https://baserow.yourdomain.com`
- **NocoDB**: `https://nocodb.yourdomain.com`
- **MinIO Console**: `https://minio-console.yourdomain.com`
- **Postiz**: `https://postiz.yourdomain.com`

---

## Day-to-Day Operations

### Update Secrets

```bash
sops secrets/production.env.enc
git add secrets/production.env.enc
git commit -m "Update secrets"
git push
```

### Modify Stack

```bash
nano docker-compose.yml
git commit -am "Update stack"
git push
```

### View Logs

```bash
docker compose logs -f n8n-core
docker compose ps
```

---

## Security Features

- Secrets encrypted at rest with SOPS + age
- Traefik TLS everywhere with automatic Let's Encrypt certificates
- Optional IP allowlisting for sensitive services (HOME_IP)
- No plaintext secrets committed to git
- GitOps workflow with auditable deployments

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
- [Skool community](https://www.skool.com/build-automate/about?ref=8708d3bb33f84fa2a3efd6b4ba05adb9)
---

Built by Kjetil Furås. Questions? Open an issue or reach out on Skool.
# Paperless-AI Installer

Quick installer for [Paperless-AI](https://github.com/clusterzx/paperless-ai) with optional Caddy reverse proxy for automatic HTTPS.

**Version:** 1.0.0
**Copyright:** (c) 2025 WZ-IT - [wz-it.com](https://wz-it.com)

## What is Paperless-AI?

Paperless-AI is an AI-powered companion for [Paperless-ngx](https://github.com/paperless-ngx/paperless-ngx) that automatically analyzes and tags your documents using AI (OpenAI, Ollama, and more).

## Important Notice

**This script is designed to be run on a FRESH SERVER.**

Running on an existing server with other services may cause port conflicts or other issues.

## Prerequisites

- **Paperless-ngx** - You need a working Paperless-ngx installation
- **Docker** - Automatically installed by this script if missing
- **Fresh server** - Recommended for clean installation

## Quick Install

```bash
curl -fsSL https://raw.githubusercontent.com/wzitcom/public-scripts/refs/heads/main/open-source-apps/paperless-ai/install.sh | bash
```

Or download and review before running:

```bash
curl -O https://raw.githubusercontent.com/wzitcom/public-scripts/refs/heads/main/open-source-apps/paperless-ai/install.sh
chmod +x install.sh
./install.sh
```

## What This Script Does

1. Checks for Docker and installs it if missing
2. Prompts for configuration options:
   - Installation directory
   - Domain name (optional, for HTTPS with Caddy)
3. Creates `docker-compose.yml` with your configuration
4. If domain specified: Creates `Caddyfile` for automatic HTTPS
5. Creates `.env` file for environment variables
6. Starts the Docker Compose stack

## Installation Options

### Local Development (Default)

Without a domain, Paperless-AI runs on `http://localhost:3000`:

| Setting | Value |
|---------|-------|
| Install Directory | `~/paperless-ai` |
| Web Port | `3000` |
| HTTPS | No |

### Production with Domain

With a domain configured, Caddy provides automatic HTTPS:

| Setting | Value |
|---------|-------|
| Install Directory | `~/paperless-ai` |
| Ports | `80`, `443` |
| HTTPS | Yes (automatic via Let's Encrypt) |

## Post-Installation

### Initial Setup

1. Open the web interface at `http://localhost:3000` or your configured domain
2. Configure your Paperless-ngx connection:
   - Paperless-ngx URL
   - API Token
3. Set up your AI provider:
   - OpenAI API Key, or
   - Ollama connection, or
   - Other supported providers

## Useful Commands

```bash
# Navigate to installation
cd ~/paperless-ai

# View logs
docker compose logs -f
docker compose logs -f paperless-ai
docker compose logs -f caddy  # If using Caddy

# Stop services
docker compose down

# Start services
docker compose up -d

# Update to latest version
docker compose pull
docker compose up -d

# Restart services
docker compose restart

# Check status
docker compose ps
```

## Configuration Files

| File | Purpose |
|------|---------|
| `docker-compose.yml` | Docker service definitions |
| `.env` | Environment variables |
| `Caddyfile` | Caddy reverse proxy config (if using domain) |

## Caddy Configuration

When using a domain, Caddy is configured with:

- **Automatic HTTPS** via Let's Encrypt
- **HTTP/2** and **HTTP/3** support
- **Gzip/Zstd compression**
- **Security headers** (HSTS, X-Frame-Options, etc.)
- **Access logging**

## Uninstallation

```bash
cd ~/paperless-ai

# Stop and remove containers, networks
docker compose down

# Also remove volumes (WARNING: deletes all data!)
docker compose down -v

# Remove installation directory
cd ~
rm -rf ~/paperless-ai
```

## Troubleshooting

### Port Already in Use

If port 3000 (or 80/443 when using Caddy) is in use:

```bash
# Check what's using the ports
sudo lsof -i :3000
sudo lsof -i :80
sudo lsof -i :443
```

### Cannot Connect to Paperless-ngx

- Ensure Paperless-ngx is accessible from this server
- Check firewall rules between servers
- Verify the API token is correct

### Container Won't Start

```bash
# Check container logs
docker compose logs paperless-ai

# Check container status
docker ps -a
```

## Resources

- [Paperless-AI GitHub](https://github.com/clusterzx/paperless-ai)
- [Paperless-ngx Documentation](https://docs.paperless-ngx.com/)
- [Caddy Documentation](https://caddyserver.com/docs/)
- [WZ-IT Website](https://wz-it.com)

## Disclaimer

This script is intended for **development and testing environments only**.

For production deployments, please consider proper security hardening, backup strategies, and custom configurations based on your requirements.

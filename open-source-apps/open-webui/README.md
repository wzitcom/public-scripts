# Open WebUI Installer

Quick installer for [Open WebUI](https://openwebui.com/) with optional Caddy reverse proxy for automatic HTTPS.

**Version:** 1.0.0
**Copyright:** (c) 2025 WZ-IT - [wz-it.com](https://wz-it.com)

## What is Open WebUI?

Open WebUI is a self-hosted, feature-rich web interface for running and managing Large Language Models (LLMs). It supports:

- Multiple LLM backends (Ollama, OpenAI, and more)
- User management and authentication
- Chat history and conversations
- Model management
- RAG (Retrieval-Augmented Generation)
- Function calling and tools
- And much more...

## Quick Install

```bash
curl -fsSL https://raw.githubusercontent.com/wzitcom/public-scripts/refs/heads/main/open-source-apps/open-webui/install.sh | bash
```

Or download and review before running:

```bash
curl -O https://raw.githubusercontent.com/wzitcom/public-scripts/refs/heads/main/open-source-apps/open-webui/install.sh
chmod +x install.sh
./install.sh
```

## What This Script Does

1. Checks for Docker and installs it if missing
2. Prompts for configuration options:
   - Installation directory
   - Domain name (optional, for HTTPS with Caddy)
   - GPU support (optional)
   - Slim/full image selection
3. Creates `docker-compose.yml` with your configuration
4. If domain specified: Creates `Caddyfile` for automatic HTTPS
5. Creates `.env` file for environment variables
6. Starts the Docker Compose stack

## Installation Options

### Local Development (Default)

Without a domain, Open WebUI runs on `http://localhost:3000`:

| Setting | Value |
|---------|-------|
| Install Directory | `~/open-webui` |
| Web Port | `3000` |
| HTTPS | No |

### Production with Domain

With a domain configured, Caddy provides automatic HTTPS:

| Setting | Value |
|---------|-------|
| Install Directory | `~/open-webui` |
| Ports | `80`, `443` |
| HTTPS | Yes (automatic via Let's Encrypt) |

## Requirements

- Docker (automatically installed if missing)
- For HTTPS: Domain with DNS pointing to your server
- For GPU: NVIDIA GPU with nvidia-docker

## Post-Installation

### First Login

1. Navigate to your Open WebUI instance
2. Sign up for an account
3. **The first user automatically becomes Administrator**
4. Subsequent users will have "Pending" status until approved

### Connecting to Ollama

If you're running Ollama locally, edit `.env`:

```bash
cd ~/open-webui
nano .env
```

Uncomment and configure:
```env
OLLAMA_BASE_URL=http://host.docker.internal:11434
```

Then restart:
```bash
docker compose down && docker compose up -d
```

### Connecting to OpenAI

Edit `.env` and add your API key:

```env
OPENAI_API_KEY=sk-your-api-key-here
```

## Useful Commands

```bash
# Navigate to installation
cd ~/open-webui

# View logs
docker compose logs -f
docker compose logs -f open-webui
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

### Custom Caddy Configuration

Edit `Caddyfile` for customizations:

```bash
nano ~/open-webui/Caddyfile
docker compose restart caddy
```

## Uninstallation

```bash
cd ~/open-webui

# Stop and remove containers, networks
docker compose down

# Also remove volumes (WARNING: deletes all data!)
docker compose down -v

# Remove installation directory
cd ~
rm -rf ~/open-webui
```

## Troubleshooting

### Port Already in Use

If ports 80/443 are in use (when using Caddy):
```bash
# Check what's using the ports
sudo lsof -i :80
sudo lsof -i :443
```

### Caddy Certificate Issues

```bash
# Check Caddy logs
docker compose logs caddy

# Ensure DNS is properly configured
nslookup your-domain.com
```

### GPU Not Working

```bash
# Check if nvidia-docker is working
docker run --rm --gpus all nvidia/cuda:11.0-base nvidia-smi
```

### Container Won't Start

```bash
# Check container logs
docker compose logs open-webui

# Check container status
docker ps -a
```

## Resources

- [Open WebUI Documentation](https://docs.openwebui.com/)
- [Open WebUI GitHub](https://github.com/open-webui/open-webui)
- [Caddy Documentation](https://caddyserver.com/docs/)
- [WZ-IT Website](https://wz-it.com)

## Disclaimer

This script is intended for **development and testing environments only**.

For production deployments, please consider proper security hardening, backup strategies, and custom configurations based on your requirements.

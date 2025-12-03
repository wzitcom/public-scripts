#!/bin/bash
#===============================================================================
#
#   WZ-IT Public Scripts
#   https://wz-it.com
#
#   Application:    Open WebUI
#   Version:        1.0.0
#   Description:    Quick installer for Open WebUI with optional Caddy reverse proxy
#
#   Copyright (c) 2025 WZ-IT
#   Licensed under MIT License
#
#===============================================================================

set -e

#-------------------------------------------------------------------------------
# Configuration
#-------------------------------------------------------------------------------
APP_NAME="Open WebUI"
APP_DIR_NAME="open-webui"
SCRIPT_VERSION="1.0.0"
INSTALL_DIR="${HOME}/${APP_DIR_NAME}"

# Colors (WZ-IT Brand)
ORANGE='\033[38;2;231;83;1m'      # #E75301
DARK_BLUE='\033[38;2;29;33;50m'   # #1D2132
NC='\033[0m'                       # No Color
BOLD='\033[1m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'

# Installation options (set during configuration)
USE_GPU="false"
USE_SLIM="false"
DOMAIN=""
USE_CADDY="false"
COMPOSE_CMD="docker compose"

#-------------------------------------------------------------------------------
# Helper Functions
#-------------------------------------------------------------------------------
print_banner() {
    echo -e "${ORANGE}"
    cat << "EOF"
 __          ________       _____ _______
 \ \        / /___  /      |_   _|__   __|
  \ \  /\  / /   / /  ______ | |    | |
   \ \/  \/ /   / /  |______|| |    | |
    \  /\  /   / /__         | |    | |
     \/  \/   /_____|       |___|   |_|

EOF
    echo -e "${NC}"
    echo -e "${BOLD}Open WebUI Installer${NC}"
    echo -e "Version: ${SCRIPT_VERSION}"
    echo -e "https://wz-it.com"
    echo ""
}

print_disclaimer() {
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}DISCLAIMER${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "This script is intended for quickly deploying DEVELOPMENT and TESTING"
    echo "environments only."
    echo ""
    echo "For PRODUCTION deployments, please consider:"
    echo "  - Proper security hardening"
    echo "  - SSL/TLS certificate configuration"
    echo "  - Firewall and network security rules"
    echo "  - Regular backup strategies"
    echo "  - High availability setup"
    echo "  - Resource monitoring and alerting"
    echo "  - Custom environment configurations"
    echo ""
    echo -e "${CYAN}Important: The first user to sign up becomes the Administrator!${NC}"
    echo ""
    echo "WZ-IT provides this script 'as is' without warranty of any kind."
    echo "Use at your own risk."
    echo ""
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${CYAN}[STEP]${NC} $1"
}

confirm_proceed() {
    echo -e "${ORANGE}Do you want to proceed? [y/N]${NC}"
    read -r response < /dev/tty
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        log_info "Operation cancelled."
        exit 0
    fi
}

#-------------------------------------------------------------------------------
# OS Detection
#-------------------------------------------------------------------------------
detect_os() {
    OS=""
    DISTRO=""

    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            DISTRO=$ID
        elif [ -f /etc/debian_version ]; then
            DISTRO="debian"
        elif [ -f /etc/redhat-release ]; then
            DISTRO="rhel"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        DISTRO="macos"
    else
        OS="unknown"
        DISTRO="unknown"
    fi

    log_info "Detected OS: ${OS} (${DISTRO})"
}

#-------------------------------------------------------------------------------
# Docker Installation
#-------------------------------------------------------------------------------
check_docker_installed() {
    if command -v docker &> /dev/null; then
        return 0
    fi
    return 1
}

check_docker_running() {
    if docker info &> /dev/null; then
        return 0
    fi
    return 1
}

check_docker_compose() {
    if docker compose version &> /dev/null; then
        COMPOSE_CMD="docker compose"
        return 0
    elif command -v docker-compose &> /dev/null; then
        COMPOSE_CMD="docker-compose"
        return 0
    fi
    return 1
}

install_docker_linux() {
    log_step "Installing Docker on Linux..."

    case "$DISTRO" in
        ubuntu|debian|raspbian|linuxmint|pop)
            log_info "Using official Docker install script for Debian-based system..."
            curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
            sudo sh /tmp/get-docker.sh
            rm /tmp/get-docker.sh
            ;;
        centos|rhel|fedora|rocky|almalinux|ol)
            log_info "Using official Docker install script for RHEL-based system..."
            curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
            sudo sh /tmp/get-docker.sh
            rm /tmp/get-docker.sh
            ;;
        arch|manjaro)
            log_info "Installing Docker via pacman..."
            sudo pacman -Sy --noconfirm docker docker-compose
            ;;
        opensuse*|sles)
            log_info "Installing Docker via zypper..."
            sudo zypper install -y docker docker-compose
            ;;
        *)
            log_info "Using official Docker install script for generic Linux..."
            curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
            sudo sh /tmp/get-docker.sh
            rm /tmp/get-docker.sh
            ;;
    esac

    # Start and enable Docker service
    log_info "Starting Docker service..."
    sudo systemctl start docker 2>/dev/null || sudo service docker start 2>/dev/null || true
    sudo systemctl enable docker 2>/dev/null || true

    # Add current user to docker group
    if ! groups | grep -q docker; then
        log_info "Adding current user to docker group..."
        sudo usermod -aG docker "$USER"
        log_warn "You may need to log out and back in for group changes to take effect."
        log_warn "Alternatively, run: newgrp docker"
    fi
}

install_docker_macos() {
    log_step "Docker installation on macOS..."
    echo ""
    echo "Docker Desktop is required for macOS."
    echo ""
    echo "Please install Docker Desktop manually:"
    echo "  1. Download from: https://www.docker.com/products/docker-desktop/"
    echo "  2. Open the downloaded .dmg file"
    echo "  3. Drag Docker to Applications"
    echo "  4. Start Docker Desktop from Applications"
    echo ""

    # Check if Homebrew is available
    if command -v brew &> /dev/null; then
        echo "Or install via Homebrew:"
        echo "  brew install --cask docker"
        echo ""
        echo -e "${ORANGE}Do you want to install Docker Desktop via Homebrew? [y/N]${NC}"
        read -r response < /dev/tty
        if [[ "$response" =~ ^[Yy]$ ]]; then
            brew install --cask docker
            echo ""
            log_info "Docker Desktop installed. Please start it from Applications."
            log_warn "After starting Docker Desktop, run this script again."
            exit 0
        fi
    fi

    log_error "Please install Docker Desktop and run this script again."
    exit 1
}

install_docker() {
    log_step "Docker is not installed. Installing Docker..."
    echo ""
    echo "This script will install Docker using the official installation method."
    echo ""
    confirm_proceed

    case "$OS" in
        linux)
            install_docker_linux
            ;;
        macos)
            install_docker_macos
            ;;
        *)
            log_error "Unsupported operating system: $OS"
            log_error "Please install Docker manually: https://docs.docker.com/get-docker/"
            exit 1
            ;;
    esac
}

start_docker_daemon() {
    log_step "Docker daemon is not running. Attempting to start..."

    case "$OS" in
        linux)
            sudo systemctl start docker 2>/dev/null || sudo service docker start 2>/dev/null
            sleep 3
            ;;
        macos)
            log_info "Starting Docker Desktop..."
            open -a Docker
            echo "Waiting for Docker to start (this may take a minute)..."

            local max_attempts=30
            local attempt=0
            while ! docker info &> /dev/null; do
                attempt=$((attempt + 1))
                if [ $attempt -ge $max_attempts ]; then
                    log_error "Docker failed to start. Please start Docker Desktop manually."
                    exit 1
                fi
                echo -n "."
                sleep 2
            done
            echo ""
            ;;
    esac

    if docker info &> /dev/null; then
        log_info "Docker daemon started successfully."
    else
        log_error "Failed to start Docker daemon."
        exit 1
    fi
}

#-------------------------------------------------------------------------------
# Pre-flight Checks
#-------------------------------------------------------------------------------
preflight_checks() {
    log_step "Running pre-flight checks..."
    echo ""

    # Detect OS
    detect_os

    # Check Docker installation
    if ! check_docker_installed; then
        install_docker
    fi
    log_info "Docker found: $(docker --version)"

    # Check Docker daemon
    if ! check_docker_running; then
        start_docker_daemon
    fi
    log_info "Docker daemon is running"

    # Check Docker Compose
    if ! check_docker_compose; then
        log_error "Docker Compose is not available."
        log_error "Docker Compose v2 should be included with Docker."
        log_error "Try reinstalling Docker or install docker-compose-plugin."
        exit 1
    fi
    log_info "Docker Compose found: $(${COMPOSE_CMD} version --short 2>/dev/null || echo 'available')"

    # Check for NVIDIA Docker if GPU support will be requested
    if command -v nvidia-smi &> /dev/null; then
        log_info "NVIDIA GPU detected"
    fi

    # Check ports if using Caddy
    if [[ "$USE_CADDY" == "true" ]]; then
        check_ports
    fi

    echo ""
    log_info "All pre-flight checks passed!"
    echo ""
}

check_ports() {
    local port_80_used=false
    local port_443_used=false

    if ss -tuln 2>/dev/null | grep -q ":80 " || netstat -tuln 2>/dev/null | grep -q ":80 "; then
        port_80_used=true
    fi
    if ss -tuln 2>/dev/null | grep -q ":443 " || netstat -tuln 2>/dev/null | grep -q ":443 "; then
        port_443_used=true
    fi

    if [[ "$port_80_used" == "true" ]] || [[ "$port_443_used" == "true" ]]; then
        log_warn "Port 80 and/or 443 may be in use."
        log_warn "Caddy requires these ports for HTTPS."
        echo -e "${ORANGE}Do you want to continue anyway? [y/N]${NC}"
        read -r response < /dev/tty
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

#-------------------------------------------------------------------------------
# Configuration Wizard
#-------------------------------------------------------------------------------
configure_installation() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}Configuration${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    # Installation directory
    echo -e "Installation directory [${BOLD}${INSTALL_DIR}${NC}]: "
    read -r custom_dir < /dev/tty
    if [[ -n "$custom_dir" ]]; then
        INSTALL_DIR="$custom_dir"
    fi

    # Domain configuration
    echo ""
    echo "Do you want to configure a domain with automatic HTTPS (via Caddy)?"
    echo "Leave empty for localhost-only access on port 3000."
    echo ""
    echo -e "Domain (e.g., openwebui.example.com): "
    read -r DOMAIN < /dev/tty

    if [[ -n "$DOMAIN" ]]; then
        USE_CADDY="true"
        echo ""
        log_info "Domain set to: ${DOMAIN}"
        log_info "Caddy will automatically obtain SSL certificates via Let's Encrypt."
        log_warn "Make sure your DNS A record points to this server's IP!"
    else
        echo ""
        log_info "No domain specified. Open WebUI will be accessible at http://localhost:3000"
    fi

    # GPU Support
    echo ""
    if command -v nvidia-smi &> /dev/null; then
        echo -e "NVIDIA GPU detected. Enable GPU support? [Y/n]"
        read -r gpu_response < /dev/tty
        if [[ ! "$gpu_response" =~ ^[Nn]$ ]]; then
            USE_GPU="true"
            log_info "GPU support enabled"
        fi
    else
        echo -e "Enable NVIDIA GPU support? (requires nvidia-docker) [y/N]"
        read -r gpu_response < /dev/tty
        if [[ "$gpu_response" =~ ^[Yy]$ ]]; then
            USE_GPU="true"
            log_info "GPU support enabled"
        fi
    fi

    # Slim image
    echo ""
    echo "Use slim image? (Smaller download, models downloaded on first use)"
    echo -e "[y/N]: "
    read -r slim_response < /dev/tty
    if [[ "$slim_response" =~ ^[Yy]$ ]]; then
        USE_SLIM="true"
        log_info "Slim image selected"
    fi

    # Print summary
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}Configuration Summary${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "  Install Directory: ${BOLD}${INSTALL_DIR}${NC}"
    if [[ -n "$DOMAIN" ]]; then
        echo -e "  Domain:            ${BOLD}${DOMAIN}${NC}"
        echo -e "  Reverse Proxy:     ${BOLD}Caddy (automatic HTTPS)${NC}"
    else
        echo -e "  Access:            ${BOLD}http://localhost:3000${NC}"
    fi
    echo -e "  GPU Support:       ${BOLD}${USE_GPU}${NC}"
    echo -e "  Slim Image:        ${BOLD}${USE_SLIM}${NC}"
    echo ""
}

#-------------------------------------------------------------------------------
# Installation
#-------------------------------------------------------------------------------
create_install_directory() {
    log_step "Creating installation directory: ${INSTALL_DIR}"
    mkdir -p "${INSTALL_DIR}"
    cd "${INSTALL_DIR}"
}

get_docker_image() {
    local image="ghcr.io/open-webui/open-webui"

    if [[ "$USE_GPU" == "true" ]]; then
        if [[ "$USE_SLIM" == "true" ]]; then
            echo "${image}:cuda-slim"
        else
            echo "${image}:cuda"
        fi
    else
        if [[ "$USE_SLIM" == "true" ]]; then
            echo "${image}:main-slim"
        else
            echo "${image}:main"
        fi
    fi
}

create_docker_compose() {
    log_step "Creating docker-compose.yml..."

    local DOCKER_IMAGE
    DOCKER_IMAGE=$(get_docker_image)

    # GPU configuration block
    local GPU_CONFIG=""
    if [[ "$USE_GPU" == "true" ]]; then
        GPU_CONFIG="    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: all
              capabilities: [gpu]"
    fi

    if [[ "$USE_CADDY" == "true" ]]; then
        # With Caddy reverse proxy
        cat > docker-compose.yml << EOF
# ============================================================================
# Open WebUI Docker Compose Stack with Caddy
# Generated by WZ-IT Installer v${SCRIPT_VERSION}
# https://wz-it.com
# ============================================================================

services:
  open-webui:
    image: ${DOCKER_IMAGE}
    container_name: open-webui
    restart: unless-stopped
    volumes:
      - open-webui-data:/app/backend/data
    environment:
      - TZ=\${TZ:-Europe/Berlin}
    networks:
      - open-webui-network
${GPU_CONFIG}

  caddy:
    image: caddy:2-alpine
    container_name: open-webui-caddy
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
      - "443:443/udp"
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile:ro
      - caddy-data:/data
      - caddy-config:/config
    networks:
      - open-webui-network
    depends_on:
      - open-webui

volumes:
  open-webui-data:
    driver: local
  caddy-data:
    driver: local
  caddy-config:
    driver: local

networks:
  open-webui-network:
    name: open-webui-network
EOF
    else
        # Without Caddy (localhost only)
        cat > docker-compose.yml << EOF
# ============================================================================
# Open WebUI Docker Compose Stack
# Generated by WZ-IT Installer v${SCRIPT_VERSION}
# https://wz-it.com
# ============================================================================

services:
  open-webui:
    image: ${DOCKER_IMAGE}
    container_name: open-webui
    restart: unless-stopped
    ports:
      - "3000:8080"
    volumes:
      - open-webui-data:/app/backend/data
    environment:
      - TZ=\${TZ:-Europe/Berlin}
${GPU_CONFIG}

volumes:
  open-webui-data:
    driver: local

networks:
  default:
    name: open-webui-network
EOF
    fi

    log_info "docker-compose.yml created successfully."
}

create_caddyfile() {
    if [[ "$USE_CADDY" != "true" ]]; then
        return
    fi

    log_step "Creating Caddyfile..."

    cat > Caddyfile << EOF
# ============================================================================
# Caddy Configuration for Open WebUI
# Generated by WZ-IT Installer v${SCRIPT_VERSION}
# https://wz-it.com
#
# Caddy automatically obtains and renews SSL certificates from Let's Encrypt.
# Make sure port 80 and 443 are open and your DNS points to this server.
# ============================================================================

${DOMAIN} {
    # Reverse proxy to Open WebUI container
    reverse_proxy open-webui:8080

    # Enable compression for better performance
    encode gzip zstd

    # Security headers
    header {
        # Enable HSTS (HTTP Strict Transport Security)
        Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
        # Prevent clickjacking attacks
        X-Frame-Options "SAMEORIGIN"
        # Prevent MIME type sniffing
        X-Content-Type-Options "nosniff"
        # XSS Protection
        X-XSS-Protection "1; mode=block"
        # Referrer Policy
        Referrer-Policy "strict-origin-when-cross-origin"
        # Remove server identification
        -Server
    }

    # Access logging
    log {
        output file /data/logs/access.log {
            roll_size 10mb
            roll_keep 5
            roll_keep_for 168h
        }
    }
}

# Optional: Redirect www to non-www (uncomment if needed)
# www.${DOMAIN} {
#     redir https://${DOMAIN}{uri} permanent
# }
EOF

    log_info "Caddyfile created successfully."
}

create_env_file() {
    log_step "Creating .env file..."

    cat > .env << 'ENV'
# ============================================================================
# Open WebUI Environment Configuration
# Generated by WZ-IT Installer
# https://wz-it.com
#
# Documentation: https://docs.openwebui.com/getting-started/env-configuration
# ============================================================================

# Timezone
TZ=Europe/Berlin

# ─────────────────────────────────────────────────────────────────────────────
# LLM Backend Configuration
# ─────────────────────────────────────────────────────────────────────────────

# Ollama Configuration (if running Ollama locally or on another host)
# OLLAMA_BASE_URL=http://host.docker.internal:11434

# OpenAI API Configuration
# OPENAI_API_KEY=sk-your-api-key-here
# OPENAI_API_BASE_URL=https://api.openai.com/v1

# ─────────────────────────────────────────────────────────────────────────────
# Authentication & Security
# ─────────────────────────────────────────────────────────────────────────────

# Enable/disable authentication (default: true)
# WEBUI_AUTH=true

# Custom name for the WebUI
# WEBUI_NAME=Open WebUI

# ─────────────────────────────────────────────────────────────────────────────
# Advanced Configuration
# ─────────────────────────────────────────────────────────────────────────────

# Enable signup (default: true)
# ENABLE_SIGNUP=true

# Default user role for new signups (pending, user, admin)
# DEFAULT_USER_ROLE=pending
ENV

    log_info ".env file created successfully."
}

start_services() {
    log_step "Starting Open WebUI..."

    ${COMPOSE_CMD} up -d

    log_info "Waiting for services to start..."
    sleep 5

    # Check if containers are running
    if docker ps | grep -q "open-webui"; then
        log_info "Open WebUI container is running."
    else
        log_warn "Open WebUI container may still be starting."
        log_warn "Check logs with: ${COMPOSE_CMD} logs -f open-webui"
    fi

    if [[ "$USE_CADDY" == "true" ]]; then
        if docker ps | grep -q "open-webui-caddy"; then
            log_info "Caddy container is running."
        else
            log_warn "Caddy container may not be running."
            log_warn "Check logs with: ${COMPOSE_CMD} logs -f caddy"
        fi
    fi
}

print_success() {
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}Installation Complete!${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "Open WebUI has been installed successfully!"
    echo ""
    echo -e "Installation directory: ${BOLD}${INSTALL_DIR}${NC}"

    if [[ "$USE_CADDY" == "true" ]]; then
        echo -e "Access URL:             ${BOLD}https://${DOMAIN}${NC}"
        echo ""
        echo -e "${YELLOW}Important:${NC}"
        echo "  - Ensure your DNS A record points to this server's IP address"
        echo "  - Caddy will automatically obtain SSL certificates from Let's Encrypt"
        echo "  - Certificates are stored in the caddy-data volume"
    else
        echo -e "Access URL:             ${BOLD}http://localhost:3000${NC}"
    fi

    echo ""
    echo -e "${CYAN}Note: The first user to sign up becomes the Administrator!${NC}"
    echo ""
    echo "Useful commands:"
    echo "  cd ${INSTALL_DIR}"
    echo "  ${COMPOSE_CMD} logs -f              # View all logs"
    echo "  ${COMPOSE_CMD} logs -f open-webui   # View Open WebUI logs"
    if [[ "$USE_CADDY" == "true" ]]; then
        echo "  ${COMPOSE_CMD} logs -f caddy        # View Caddy logs"
    fi
    echo "  ${COMPOSE_CMD} down                 # Stop services"
    echo "  ${COMPOSE_CMD} up -d                # Start services"
    echo "  ${COMPOSE_CMD} pull && ${COMPOSE_CMD} up -d  # Update to latest"
    echo ""

    if [[ "$USE_SLIM" == "true" ]]; then
        echo -e "${YELLOW}Note: Using slim image - models will be downloaded on first use.${NC}"
        echo ""
    fi

    echo -e "${ORANGE}Thank you for using WZ-IT scripts!${NC}"
    echo -e "Visit us at: ${BOLD}https://wz-it.com${NC}"
    echo ""
}

#-------------------------------------------------------------------------------
# Main
#-------------------------------------------------------------------------------
main() {
    clear
    print_banner
    print_disclaimer
    confirm_proceed
    echo ""
    configure_installation
    confirm_proceed
    echo ""
    preflight_checks
    create_install_directory
    create_docker_compose
    create_caddyfile
    create_env_file
    start_services
    print_success
}

main "$@"

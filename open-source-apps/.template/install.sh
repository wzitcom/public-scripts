#!/bin/bash
#===============================================================================
#
#   WZ-IT Public Scripts
#   https://wz-it.com
#
#   Application:    APP_NAME
#   Version:        1.0.0
#   Description:    Quick installer for APP_NAME using Docker Compose
#
#   Copyright (c) 2025 WZ-IT
#   Licensed under MIT License
#
#===============================================================================

set -e

#-------------------------------------------------------------------------------
# Configuration
#-------------------------------------------------------------------------------
APP_NAME="APP_NAME"
APP_VERSION="latest"
SCRIPT_VERSION="1.0.0"
INSTALL_DIR="${HOME}/${APP_NAME,,}"

# Colors (WZ-IT Brand)
ORANGE='\033[38;2;231;83;1m'      # #E75301
DARK_BLUE='\033[38;2;29;33;50m'   # #1D2132
NC='\033[0m'                       # No Color
BOLD='\033[1m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'

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
    echo -e "${BOLD}APP_NAME Installer${NC}"
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
    read -r response
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
        read -r response
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

    echo ""
    log_info "All pre-flight checks passed!"
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

create_docker_compose() {
    log_step "Creating docker-compose.yml..."

    cat > docker-compose.yml << 'COMPOSE'
# ============================================================================
# APP_NAME Docker Compose Stack
# Generated by WZ-IT Installer
# https://wz-it.com
# ============================================================================

services:
  app:
    image: APP_IMAGE:${APP_VERSION:-latest}
    container_name: APP_NAME
    restart: unless-stopped
    ports:
      - "8080:8080"
    volumes:
      - app_data:/data
    environment:
      - TZ=${TZ:-Europe/Berlin}
    # Add your configuration here

volumes:
  app_data:
    driver: local

networks:
  default:
    name: APP_NAME_network
COMPOSE

    log_info "docker-compose.yml created successfully."
}

create_env_file() {
    log_step "Creating .env file..."

    cat > .env << ENV
# ============================================================================
# APP_NAME Environment Configuration
# Generated by WZ-IT Installer
# ============================================================================

APP_VERSION=${APP_VERSION}
TZ=Europe/Berlin

# Add your environment variables here
# Example:
# DATABASE_PASSWORD=changeme
# ADMIN_USER=admin
ENV

    log_info ".env file created successfully."
}

start_services() {
    log_step "Starting ${APP_NAME}..."

    ${COMPOSE_CMD} up -d

    log_info "${APP_NAME} is starting..."
    sleep 3

    # Verify container is running
    if docker ps | grep -q "APP_NAME"; then
        log_info "${APP_NAME} container is running."
    else
        log_warn "Container may still be starting. Check logs with: ${COMPOSE_CMD} logs -f"
    fi
}

print_success() {
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}Installation Complete!${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "APP_NAME has been installed successfully!"
    echo ""
    echo -e "Installation directory: ${BOLD}${INSTALL_DIR}${NC}"
    echo -e "Access URL:             ${BOLD}http://localhost:8080${NC}"
    echo ""
    echo "Useful commands:"
    echo "  cd ${INSTALL_DIR}"
    echo "  ${COMPOSE_CMD} logs -f         # View logs"
    echo "  ${COMPOSE_CMD} down            # Stop services"
    echo "  ${COMPOSE_CMD} up -d           # Start services"
    echo "  ${COMPOSE_CMD} pull && ${COMPOSE_CMD} up -d  # Update"
    echo ""
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
    preflight_checks
    create_install_directory
    create_docker_compose
    create_env_file
    start_services
    print_success
}

main "$@"

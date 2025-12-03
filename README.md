# WZ-IT Public Scripts

A collection of public scripts and installers provided by [WZ-IT](https://wz-it.com).

## Overview

This repository contains ready-to-use installation scripts for popular open-source applications. Each installer deploys a Docker Compose stack with sensible defaults for development and testing environments.

## Quick Start

Each application can be installed with a single command:

```bash
curl -fsSL https://raw.githubusercontent.com/wzitcom/public-scripts/refs/heads/main/open-source-apps/<app-name>/install.sh | bash
```

Or download and review before running:

```bash
curl -O https://raw.githubusercontent.com/wzitcom/public-scripts/refs/heads/main/open-source-apps/<app-name>/install.sh
chmod +x install.sh
./install.sh
```

## Available Applications

| Application | Description | Install Command |
|-------------|-------------|-----------------|
| [Open WebUI](open-source-apps/open-webui/) | Self-hosted LLM web interface with optional Caddy HTTPS | `curl -fsSL .../open-webui/install.sh \| bash` |

## Repository Structure

```
public-scripts/
├── README.md
├── LICENSE
├── open-source-apps/
│   ├── .template/           # Template for new installers
│   │   ├── install.sh       # Base installer template
│   │   └── README.md        # README template
│   ├── open-webui/          # Open WebUI installer
│   │   ├── install.sh
│   │   └── README.md
│   └── <app-name>/          # Each app gets its own folder
│       ├── install.sh       # Main installer script
│       └── README.md        # App-specific documentation
```

## Prerequisites

- **bash** - Standard on Linux/macOS, use WSL on Windows
- **curl** - For downloading scripts
- **sudo** access - For installing Docker if not present

**Note:** Docker and Docker Compose are automatically installed by the scripts if not already present.

## Disclaimer

These scripts are intended for quickly deploying **development and testing environments only**.

For **production deployments**, please consider:

- Proper security hardening
- SSL/TLS certificate configuration
- Firewall and network security rules
- Regular backup strategies
- High availability setup
- Resource monitoring and alerting
- Custom environment configurations

**WZ-IT provides these scripts "as is" without warranty of any kind. Use at your own risk.**

## Creating New Installers

1. Copy the template:
   ```bash
   cp -r open-source-apps/.template open-source-apps/<app-name>
   ```

2. Edit `install.sh`:
   - Replace `APP_NAME` with the application name
   - Replace `APP_IMAGE` with the Docker image
   - Customize the docker-compose configuration
   - Update ports, volumes, and environment variables

3. Create a `README.md` for the application

4. Update this main README with the new application

## Contributing

Contributions are welcome! Please ensure:

- Scripts follow the existing template structure
- All scripts include proper error handling
- Documentation is clear and complete
- Scripts are tested on fresh environments

## License

MIT License - Copyright (c) 2025 WZ-IT

See [LICENSE](LICENSE) for details.

## Contact

- Website: [https://wz-it.com](https://wz-it.com)
- GitHub: [https://github.com/wzitcom](https://github.com/wzitcom)

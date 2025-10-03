# Dev Container Configuration

This directory contains the Dev Container configuration for this repository, enabling consistent development environments across:

- **VS Code Dev Containers** (local)
- **GitHub Codespaces**
- **Coder** (with Dev Container support)
- **GitHub Actions** (with Act or similar tools)

## Files

### `devcontainer.json`

Main configuration file that defines:
- Container build settings
- VS Code extensions to install
- Editor settings
- Port forwarding
- Lifecycle hooks (postCreateCommand, postStartCommand)
- User and runtime settings

### `Dockerfile`

Dev Container specific Dockerfile that:
- Uses `ubuntu:22.04` as base (instead of Coder-specific base)
- Creates `coder` user with UID/GID 1000 for host compatibility
- Installs all development tools from `scripts/`
- Configures sudo access for the coder user

### `post-create.sh`

Post-creation script that runs after the container is built:
- Validates environment setup
- Displays installed tool versions
- Provides helpful tips for getting started
- Checks Docker socket availability

## Usage

### Local Development with VS Code

1. Install [VS Code](https://code.visualstudio.com/) and [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
2. Open this repository in VS Code
3. Press `F1` → "Dev Containers: Reopen in Container"
4. Wait for the container to build (first time takes ~10-15 minutes)
5. Once ready, you'll have a fully configured development environment

### GitHub Codespaces

GitHub automatically detects the `.devcontainer/` configuration:

1. Go to the repository on GitHub
2. Click "Code" → "Create codespace on main"
3. Wait for the environment to be ready
4. Start coding!

### Coder with Dev Container Support

Coder can use Dev Container configurations:

1. Create a Coder template that references this repository
2. Coder will automatically use the `.devcontainer/` configuration
3. See [Coder Dev Container docs](https://coder.com/docs/admin/templates/managing-templates/devcontainers)

### GitHub Actions

You can use this Dev Container in GitHub Actions for consistent CI/CD:

```yaml
name: CI

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    container:
      image: ghcr.io/devcontainers/cli:latest
    steps:
      - uses: actions/checkout@v3
      - name: Build Dev Container
        run: devcontainer build --workspace-folder .
      - name: Run tests in Dev Container
        run: devcontainer exec --workspace-folder . npm test
```

## Customization

### Adding VS Code Extensions

Edit `devcontainer.json` → `customizations.vscode.extensions`:

```json
{
  "customizations": {
    "vscode": {
      "extensions": [
        "your-publisher.your-extension"
      ]
    }
  }
}
```

### Modifying Editor Settings

Edit `devcontainer.json` → `customizations.vscode.settings`:

```json
{
  "customizations": {
    "vscode": {
      "settings": {
        "editor.fontSize": 14
      }
    }
  }
}
```

### Port Forwarding

Add ports to forward to your local machine:

```json
{
  "forwardPorts": [3000, 8080]
}
```

### Environment Variables

Add environment variables in `devcontainer.json`:

```json
{
  "containerEnv": {
    "MY_VAR": "my_value"
  }
}
```

## Differences from Coder Base Image

| Aspect | Coder Base | Dev Container |
|--------|------------|---------------|
| Base Image | `codercom/enterprise-base:ubuntu` | `ubuntu:22.04` |
| User Creation | Pre-existing `coder` user | Creates `coder` user (UID 1000) |
| Sudo Access | May be restricted | Full sudo with NOPASSWD |
| Use Case | Coder workspaces | VS Code, Codespaces, CI/CD |
| Build Time | Optimized for Coder | Optimized for Dev Containers |

## Troubleshooting

### Container fails to build

1. Check Docker daemon is running
2. Ensure you have enough disk space (~5GB for build)
3. Try rebuilding without cache:
   ```bash
   docker build --no-cache -f .devcontainer/Dockerfile .
   ```

### Docker commands don't work inside container

1. Ensure Docker socket is mounted (check `devcontainer.json` mounts)
2. Verify the socket exists: `ls -la /var/run/docker.sock`
3. Check coder user is in docker group: `groups`

### Oh My Posh doesn't display correctly

1. Ensure terminal is using a Nerd Font (MesloLGS NF is installed)
2. In VS Code settings, set: `"terminal.integrated.fontFamily": "MesloLGS NF"`
3. Restart the terminal

### fnm/Node.js commands not found

1. Source the zsh config: `source ~/.zshrc`
2. Check PATH: `echo $PATH`
3. Verify fnm is installed: `which fnm`

## Performance Tips

1. **Use volume for package caches**: Mount `~/.npm`, `~/.cache`, etc. to host volumes
2. **Keep container running**: Set `"shutdownAction": "stopContainer"` (already configured)
3. **Enable Docker BuildKit**: Set `DOCKER_BUILDKIT=1` environment variable
4. **Use build cache**: Don't use `--no-cache` unless necessary

## Support

For issues specific to:
- **Dev Containers**: See [VS Code Dev Containers docs](https://code.visualstudio.com/docs/devcontainers/containers)
- **GitHub Codespaces**: See [GitHub Codespaces docs](https://docs.github.com/en/codespaces)
- **Coder**: See [Coder Dev Container docs](https://coder.com/docs/admin/templates/managing-templates/devcontainers)
- **This configuration**: Open an issue in this repository
# Dev Container Features

Reusable Dev Container features for consistent development environments.

## Available Features

### shell-utils
**Enhanced alternative to `common-utils`**
Installs and configures Zsh with choice of Zimfw or Oh My Zsh, plus Oh My Posh for prompt customization. Combines the best of shell frameworks and modern prompt engines.

**Options:**
- Choose between Zimfw (modern, fast) or Oh My Zsh (popular)
- Optional Oh My Posh for cross-shell prompt themes
- Automatic user detection
- Package upgrade support

### node
**Enhanced alternative to official `node` feature with fnm**
Installs Node.js via fnm (Fast Node Manager) with yarn and pnpm support. Provides better performance than nvm while maintaining compatibility.

**Options:**
- Node.js version selection (lts, latest, 22, 20, 18)
- Optional LTS installation
- Yarn and pnpm support
- nvm alias for compatibility

### graphite
Installs Graphite CLI for stacked pull request workflows via npm. Requires the `node` feature.

### bun
Installs Bun - Fast JavaScript runtime and toolkit.

### deno
Installs Deno - Secure TypeScript/JavaScript runtime.

### sdkman
Installs SDKMAN - Software Development Kit Manager for Java/JVM ecosystem.

### claude-code
Installs Claude Code - AI-powered coding assistant CLI.

### fvm
Installs FVM - Flutter Version Management.

## Usage

### In devcontainer.json

```json
{
  "features": {
    "ghcr.io/amondnet/devcontainer-features/shell-utils:1": {
      "shellFramework": "zimfw",
      "installOhMyPosh": true
    },
    "ghcr.io/amondnet/devcontainer-features/node:1": {
      "version": "22",
      "installYarn": true,
      "installPnpm": true
    },
    "ghcr.io/amondnet/devcontainer-features/graphite:1": {},
    "ghcr.io/amondnet/devcontainer-features/bun:1": {},
    "ghcr.io/amondnet/devcontainer-features/deno:1": {},
    "ghcr.io/amondnet/devcontainer-features/sdkman:1": {},
    "ghcr.io/amondnet/devcontainer-features/claude-code:1": {},
    "ghcr.io/amondnet/devcontainer-features/fvm:1": {}
  }
}
```

### Local development (submodule)

```json
{
  "features": {
    "./.devcontainer/features/src/shell-utils": {
      "shellFramework": "zimfw",
      "installOhMyPosh": true
    },
    "./.devcontainer/features/src/node": {
      "version": "22"
    }
  }
}
```

## Development

### Directory Structure

```
src/
├── zimfw/
│   ├── devcontainer-feature.json
│   └── install.sh
├── fnm/
│   ├── devcontainer-feature.json
│   └── install.sh
...
```

### Testing Locally

1. Clone this repository as a submodule in your project
2. Reference features with relative path in `devcontainer.json`
3. Rebuild Dev Container to test

## Publishing

Features are automatically published to GitHub Container Registry via GitHub Actions when pushed to main branch.

## License

MIT
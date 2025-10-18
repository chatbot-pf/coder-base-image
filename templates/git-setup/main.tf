terraform {
  required_providers {
    coder = {
      source = "coder/coder"
    }
    docker = {
      source = "kreuzwerker/docker"
    }
  }
}

locals {
  username    = data.coder_workspace_owner.me.name
  folder_name = try(element(split("/", data.coder_parameter.git_repo.value), length(split("/", data.coder_parameter.git_repo.value)) - 1), "")

  # Branch name (without repo prefix)
  branch_name = data.coder_parameter.branch_name.value != ""
    ? data.coder_parameter.branch_name.value
    : "issue-${data.coder_parameter.issue_number.value}"

  # Worktree name (with repo prefix to avoid conflicts)
  worktree_name = data.coder_parameter.branch_name.value != ""
    ? "${local.folder_name}/${data.coder_parameter.branch_name.value}"
    : "${local.folder_name}/issue-${data.coder_parameter.issue_number.value}"
}

variable "docker_socket" {
  default     = ""
  description = "(Optional) Docker socket URI"
  type        = string
}

provider "docker" {
  host = var.docker_socket != "" ? var.docker_socket : null
}

data "coder_provisioner" "me" {}
data "coder_workspace" "me" {}
data "coder_workspace_owner" "me" {}

# Git repository parameter
data "coder_parameter" "git_repo" {
  name         = "git_repo"
  display_name = "Git Repository URL"
  description  = "Repository to clone (e.g., https://github.com/org/repo)"
  default      = ""
  mutable      = false
  form_type    = "input"
  type         = "string"
}

# Issue number parameter
data "coder_parameter" "issue_number" {
  name         = "issue_number"
  display_name = "Issue Number"
  description  = "GitHub issue number (optional, leave empty if using custom branch)"
  default      = ""
  mutable      = false
  form_type    = "input"
  type         = "string"
}

# Branch name parameter (alternative to issue number)
data "coder_parameter" "branch_name" {
  name         = "branch_name"
  display_name = "Branch Name"
  description  = "Custom branch name (optional, overrides issue number)"
  default      = ""
  mutable      = false
  form_type    = "input"
  type         = "string"
}

# Setup mode parameter
data "coder_parameter" "setup_mode" {
  name         = "setup_mode"
  display_name = "Setup Mode"
  description  = "What to do with the repository"
  default      = "worktree"
  mutable      = false
  form_type    = "radio"
  type         = "string"
  option {
    name  = "Create Worktree"
    value = "worktree"
  }
  option {
    name  = "Clone Fresh"
    value = "clone"
  }
}

resource "coder_agent" "main" {
  arch           = data.coder_provisioner.me.arch
  os             = "linux"
  startup_script = <<-EOT
    set -e

    echo "========================================"
    echo "🚀 Git Setup Workspace"
    echo "========================================"

    REPO_URL="${data.coder_parameter.git_repo.value}"
    REPO_NAME="${local.folder_name}"
    BRANCH_NAME="${local.branch_name}"
    SETUP_MODE="${data.coder_parameter.setup_mode.value}"

    BARE_REPO="$HOME/repos/$REPO_NAME"
    WORKTREE_PATH="$HOME/workspace/${local.worktree_name}"
    CLONE_PATH="$HOME/workspace/$REPO_NAME"

    echo "Repository: $REPO_URL"
    echo "Branch: $BRANCH_NAME"
    echo "Worktree Path: $WORKTREE_PATH"
    echo "Setup Mode: $SETUP_MODE"
    echo "========================================"

    # Create directories
    mkdir -p "$HOME/repos"
    mkdir -p "$HOME/workspace"

    case "$SETUP_MODE" in
      worktree)
        echo "📦 Mode: Worktree"

        # Create bare repo if not exists
        if [ ! -d "$BARE_REPO" ]; then
          echo "Cloning bare repository..."
          git clone --bare "$REPO_URL" "$BARE_REPO"
          cd "$BARE_REPO"
          git config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"
        else
          echo "Bare repository already exists"
        fi

        # Fetch latest
        cd "$BARE_REPO"
        echo "Fetching latest changes..."
        git fetch origin

        # Create worktree
        if [ -d "$WORKTREE_PATH" ]; then
          echo "⚠️  Worktree already exists: $WORKTREE_PATH"
          cd "$WORKTREE_PATH"
          echo "Updating existing worktree..."
          git pull origin "$BRANCH_NAME" 2>/dev/null || echo "Branch may not exist remotely yet"
        else
          echo "Creating worktree: $WORKTREE_PATH"

          if git show-ref --verify --quiet refs/remotes/origin/$BRANCH_NAME; then
            echo "Checking out existing branch: $BRANCH_NAME"
            git worktree add "$WORKTREE_PATH" "$BRANCH_NAME"
          else
            echo "Creating new branch: $BRANCH_NAME"
            git worktree add "$WORKTREE_PATH" -b "$BRANCH_NAME"
          fi
        fi

        echo "✅ Worktree ready at: $WORKTREE_PATH"
        ;;

      clone)
        echo "📦 Mode: Fresh Clone"

        if [ -d "$CLONE_PATH" ]; then
          echo "⚠️  Directory already exists: $CLONE_PATH"
          cd "$CLONE_PATH"

          if git show-ref --verify --quiet refs/remotes/origin/$BRANCH_NAME; then
            echo "Checking out branch: $BRANCH_NAME"
            git checkout "$BRANCH_NAME"
            git pull origin "$BRANCH_NAME"
          else
            echo "Creating new branch: $BRANCH_NAME"
            git checkout -b "$BRANCH_NAME"
          fi
        else
          echo "Cloning repository..."
          git clone "$REPO_URL" "$CLONE_PATH"
          cd "$CLONE_PATH"

          if git show-ref --verify --quiet refs/remotes/origin/$BRANCH_NAME; then
            echo "Checking out branch: $BRANCH_NAME"
            git checkout "$BRANCH_NAME"
          else
            echo "Creating new branch: $BRANCH_NAME"
            git checkout -b "$BRANCH_NAME"
          fi
        fi

        echo "✅ Repository cloned at: $CLONE_PATH"
        ;;
    esac

    echo "========================================"
    echo "✅ Setup Complete!"
    echo "========================================"
    echo ""
    echo "You can now access this workspace from your other workspaces:"

    if [ "$SETUP_MODE" = "worktree" ]; then
      echo "  cd $WORKTREE_PATH"
    else
      echo "  cd $CLONE_PATH"
    fi

    echo ""
    echo "This setup workspace will stop automatically in 10 seconds."
    echo "You can manually stop it earlier from Coder dashboard."
    echo "========================================"

    # Auto-stop hint (workspace will stop when script completes)
    sleep 10
  EOT

  env = {
    GIT_AUTHOR_NAME     = coalesce(data.coder_workspace_owner.me.full_name, data.coder_workspace_owner.me.name)
    GIT_AUTHOR_EMAIL    = data.coder_workspace_owner.me.email
    GIT_COMMITTER_NAME  = coalesce(data.coder_workspace_owner.me.full_name, data.coder_workspace_owner.me.name)
    GIT_COMMITTER_EMAIL = data.coder_workspace_owner.me.email
  }
}

# Use shared home volume (same as other workspaces)
resource "docker_volume" "home_volume" {
  name = "coder-${data.coder_workspace_owner.me.id}-home"
  lifecycle {
    ignore_changes = all
  }
  labels {
    label = "coder.owner"
    value = data.coder_workspace_owner.me.name
  }
  labels {
    label = "coder.owner_id"
    value = data.coder_workspace_owner.me.id
  }
}

resource "docker_network" "private_network" {
  name = "network-${data.coder_workspace.me.id}"
}

resource "docker_container" "workspace" {
  count    = data.coder_workspace.me.start_count
  image    = data.coder_parameter.base_image.value
  name     = "coder-${data.coder_workspace_owner.me.name}-${lower(data.coder_workspace.me.name)}"
  hostname = data.coder_workspace.me.name
  command  = ["sh", "-c", coder_agent.main.init_script]

  env = [
    "CODER_AGENT_TOKEN=${coder_agent.main.token}",
  ]

  networks_advanced {
    name = docker_network.private_network.name
  }

  volumes {
    container_path = "/home/coder"
    volume_name    = docker_volume.home_volume.name
    read_only      = false
  }

  labels {
    label = "coder.owner"
    value = data.coder_workspace_owner.me.name
  }
  labels {
    label = "coder.owner_id"
    value = data.coder_workspace_owner.me.id
  }
  labels {
    label = "coder.workspace_id"
    value = data.coder_workspace.me.id
  }
  labels {
    label = "coder.workspace_name"
    value = data.coder_workspace.me.name
  }
}

data "coder_parameter" "base_image" {
  name        = "Base image"
  description = "Base machine image to use"
  default     = "ghcr.io/chatbot-pf/coder-base-image:main"
  form_type   = "input"
  type        = "string"
  mutable     = false
}

# Require external authentication
data "coder_external_auth" "github" {
  id = "primary-github"
}
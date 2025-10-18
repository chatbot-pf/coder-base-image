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
  username = data.coder_workspace_owner.me.name
}

variable "docker_socket" {
  default     = ""
  description = "(Optional) Docker socket URI"
  type        = string
}

provider "docker" {
  # Defaulting to null if the variable is an empty string lets us have an optional variable without having to set our own default
  host = var.docker_socket != "" ? var.docker_socket : null
}

data "coder_provisioner" "me" {}
data "coder_workspace" "me" {}
data "coder_workspace_owner" "me" {}

resource "coder_agent" "main" {
  arch           = data.coder_provisioner.me.arch
  os             = "linux"
  dir            = "$HOME/workspace"
  startup_script = <<-EOT
    set -e

    # Prepare user home with default files on first start.
    if [ ! -f ~/.init_done ]; then
      cp -rT /etc/skel ~
      touch ~/.init_done
    fi

    # Create workspace directory
    mkdir -p "$HOME/workspace"

    # Daily worktree cleanup (runs once per day)
    CLEANUP_MARKER="$HOME/.worktree_cleanup_timestamp"
    CURRENT_DATE=$(date +%Y-%m-%d)

    if [ ! -f "$CLEANUP_MARKER" ] || [ "$(cat $CLEANUP_MARKER 2>/dev/null)" != "$CURRENT_DATE" ]; then
      echo "🧹 Running daily worktree cleanup..."

      # Cleanup for all repositories in ~/repos
      if [ -d "$HOME/repos" ]; then
        for BARE_REPO in "$HOME/repos"/*; do
          if [ -d "$BARE_REPO" ] && [ -d "$BARE_REPO/objects" ]; then
            REPO_NAME=$(basename "$BARE_REPO")
            echo "  Checking repository: $REPO_NAME"

            cd "$BARE_REPO"
            git fetch --prune origin 2>/dev/null || true

            # Remove worktrees for deleted branches
            git worktree list --porcelain 2>/dev/null | awk '
              /^worktree / { wt=$2 }
              /^branch / {
                branch=$2
                gsub("refs/heads/", "", branch)
                worktrees[wt] = branch
              }
              END {
                for (wt in worktrees) {
                  print wt, worktrees[wt]
                }
              }
            ' | while read wt branch; do
              if [ -n "$branch" ] && ! git show-ref --verify --quiet refs/remotes/origin/$branch 2>/dev/null; then
                echo "    → Removing worktree: $(basename $wt) (branch '$branch' deleted)"
                git worktree remove "$wt" --force 2>/dev/null || true
              fi
            done

            # Prune stale worktree administrative files
            git worktree prune 2>/dev/null || true
          fi
        done
      fi

      echo "$CURRENT_DATE" > "$CLEANUP_MARKER"
      echo "✅ Daily cleanup completed"
    fi

    echo "✅ Workspace ready at: $HOME/workspace"

    # Add any commands that should be executed at workspace startup (e.g install requirements, start a program, etc) here
  EOT

  # These environment variables allow you to make Git commits right away after creating a
  # workspace. Note that they take precedence over configuration defined in ~/.gitconfig!
  # You can remove this block if you'd prefer to configure Git manually or using
  # dotfiles. (see docs/dotfiles.md)
  env = {
    GIT_AUTHOR_NAME     = coalesce(data.coder_workspace_owner.me.full_name, data.coder_workspace_owner.me.name)
    GIT_AUTHOR_EMAIL    = "${data.coder_workspace_owner.me.email}"
    GIT_COMMITTER_NAME  = coalesce(data.coder_workspace_owner.me.full_name, data.coder_workspace_owner.me.name)
    GIT_COMMITTER_EMAIL = "${data.coder_workspace_owner.me.email}"
  }

  # The following metadata blocks are optional. They are used to display
  # information about your workspace in the dashboard. You can remove them
  # if you don't want to display any information.
  # For basic resources, you can use the `coder stat` command.
  # If you need more control, you can write your own script.
  metadata {
    display_name = "CPU Usage"
    key          = "0_cpu_usage"
    script       = "coder stat cpu"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "RAM Usage"
    key          = "1_ram_usage"
    script       = "coder stat mem"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "Home Disk"
    key          = "3_home_disk"
    script       = "coder stat disk --path $${HOME}"
    interval     = 60
    timeout      = 1
  }

  metadata {
    display_name = "CPU Usage (Host)"
    key          = "4_cpu_usage_host"
    script       = "coder stat cpu --host"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "Memory Usage (Host)"
    key          = "5_mem_usage_host"
    script       = "coder stat mem --host"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "Load Average (Host)"
    key          = "6_load_host"
    # get load avg scaled by number of cores
    script   = <<EOT
      echo "`cat /proc/loadavg | awk '{ print $1 }'` `nproc`" | awk '{ printf "%0.2f", $1/$2 }'
    EOT
    interval = 60
    timeout  = 1
  }

  metadata {
    display_name = "Swap Usage (Host)"
    key          = "7_swap_host"
    script       = <<EOT
      free -b | awk '/^Swap/ { printf("%.1f/%.1f", $3/1024.0/1024.0/1024.0, $2/1024.0/1024.0/1024.0) }'
    EOT
    interval     = 10
    timeout      = 1
  }
}

# See https://registry.coder.com/modules/coder/code-server
module "code-server" {
  count  = data.coder_workspace.me.start_count
  source = "registry.coder.com/coder/code-server/coder"

  # This ensures that the latest non-breaking version of the module gets downloaded, you can also pin the module version to prevent breaking changes in production.
  version = "~> 1.0"

  agent_id = coder_agent.main.id
  order    = 1
}

module "jetbrains" {
  count    = data.coder_workspace.me.start_count
  source   = "registry.coder.com/coder/jetbrains/coder"
  version  = "1.1.0"
  agent_id = coder_agent.main.id
  folder   = "/home/coder"
  # tooltip  = "You need to [Install Coder Desktop](https://coder.com/docs/user-guides/desktop#install-coder-desktop) to use this button."  # Optional
}


resource "docker_volume" "home_volume" {
  name  = data.coder_parameter.persistent_volume.value == "true" ? "coder--${data.coder_workspace_owner.me.id}-home" : "coder-${data.coder_workspace.me.id}-home"
  # Protect the volume from being deleted due to changes in attributes.
  lifecycle {
    ignore_changes = all
  }
  # Add labels in Docker to keep track of orphan resources.
  labels {
    label = "coder.owner"
    value = data.coder_workspace_owner.me.name
  }
  labels {
    label = "coder.owner_id"
    value = data.coder_workspace_owner.me.id
  }
  # labels {
  #   label = "coder.workspace_id"
  #   value = data.coder_workspace.me.id
  # }
  # This field becomes outdated if the workspace is renamed but can
  # be useful for debugging or cleaning out dangling volumes.
  labels {
    label = "coder.workspace_name_at_creation"
    value = data.coder_workspace.me.name
  }
}

resource "docker_network" "private_network" {
  name = "network-${data.coder_workspace.me.id}"
}

resource "docker_container" "dind" {
  image      = "docker:dind"
  privileged = true
  name       = "dind-${data.coder_workspace.me.id}"
  entrypoint = ["dockerd", "-H", "tcp://0.0.0.0:2375"]
  networks_advanced {
    name = docker_network.private_network.name
  }
}

resource "docker_container" "workspace" {
  count = data.coder_workspace.me.start_count
  image = data.coder_parameter.base_image.value
  # Uses lower() to avoid Docker restriction on container names.
  name = "coder-${data.coder_workspace_owner.me.name}-${lower(data.coder_workspace.me.name)}"
  # Hostname makes the shell more user friendly: coder@my-workspace:~$
  hostname = data.coder_workspace.me.name
  # Use the docker gateway if the access URL is 127.0.0.1
  # entrypoint = ["sh", "-c", replace(coder_agent.main.# init_script, "/localhost|127\\.0\\.0\\.1/", "host.docker.internal")]
  command = ["sh", "-c", coder_agent.main.init_script]

  env = [
    "CODER_AGENT_TOKEN=${coder_agent.main.token}",
    "DOCKER_HOST=${docker_container.dind.name}:2375"
  ]
  networks_advanced {
    name = docker_network.private_network.name
  }
  #host {
  #  host = "host.docker.internal"
  #  ip   = "host-gateway"
  #}
  volumes {
    container_path = "/home/coder"
    volume_name    = docker_volume.home_volume.name
    read_only      = false
  }

  # Add labels in Docker to keep track of orphan resources.
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

data "coder_parameter" "persistent_volume" {
  name         = "persistent_volume"
  display_name = "영구 홈 볼륨 사용"
  description  = "true: 사용자별 공유 볼륨 (워크스페이스 재생성 시에도 유지), false: 워크스페이스별 개별 볼륨"
  type         = "bool"
  form_type    = "checkbox"
  default      = "false"
}

data "coder_parameter" "base_image" {
  name        = "Base image"
  description = "Base machine image to download"
  default     = "ghcr.io/chatbot-pf/coder-base-image:main"
  form_type   = "input"
  type        = "string"
  mutable     = true
}

#module "vscode-web" {
#  count          = data.coder_workspace.me.start_count
#  source         = "registry.coder.com/coder/vscode-web/coder"
#  version        = "~> 1.0"
#  agent_id       = coder_agent.main.id
#  accept_license = true
#}

module "dotfiles" {
  count                = data.coder_workspace.me.start_count
  source               = "registry.coder.com/coder/dotfiles/coder"
  version              = "~> 1.0"
  agent_id             = coder_agent.main.id
  default_dotfiles_uri = "git@github.com:chatbot-pf/dotfiles.git"
  manual_update        = true
}

module "personalize" {
  count    = data.coder_workspace.me.start_count
  source   = "registry.coder.com/modules/personalize/coder"
  version  = "~> 1.0"
  agent_id = coder_agent.main.id
}

# Require external authentication to use this template
data "coder_external_auth" "github" {
    id = "primary-github"
}

module "cursor" {
  count    = data.coder_workspace.me.start_count
  source   = "registry.coder.com/coder/cursor/coder"
  version  = "~> 1.0"
  agent_id = coder_agent.main.id
}

#module "filebrowser" {
#  count    = data.coder_workspace.me.start_count
#  source   = "registry.coder.com/coder/filebrowser/coder"
#  version  = "~> 1.0"
#  agent_id = coder_agent.main.id
#}


#module "zed" {
#  count    = data.coder_workspace.me.start_count
#  source   = "registry.coder.com/coder/zed/coder"
#  version  = "~> 1.0"
#  agent_id = coder_agent.main.id
#}

#module "kiro" {
#  count    = data.coder_workspace.me.start_count
#  source   = "registry.coder.com/coder/kiro/coder"
#  version  = "~> 1.0"
#  agent_id = coder_agent.main.id
#}


variable "claude_code_oauth_token" {
  type        = string
  description = "Set up a long-lived authentication token (requires Claude subscription). Generated using `claude setup-token` command"
  sensitive   = true
  default     = "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"
}

resource "coder_env" "claude_code_oauth_token" {
  agent_id = coder_agent.main.id
  name     = "CLAUDE_CODE_OAUTH_TOKEN"
  value    = var.claude_code_oauth_token
}
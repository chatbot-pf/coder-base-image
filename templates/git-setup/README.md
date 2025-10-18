# Git Setup Template

A lightweight, one-time workspace for setting up git repositories and worktrees in shared home directory.

## Purpose

This template creates a **temporary workspace** that:
1. Clones repositories or creates worktrees in your persistent home directory
2. Automatically stops after setup completes
3. Shares the same home volume as your development workspaces

## Use Cases

### Use Case 1: Create Worktree for GitHub Issue

**When to use:** Working on a specific issue in a repository

**Steps:**
1. Create workspace from this template
2. Enter parameters:
   - Git Repository: `https://github.com/org/repo`
   - Issue Number: `123`
   - Setup Mode: `Create Worktree`
3. Workspace creates: `~/workspace/repo/issue-123/`
4. Workspace stops automatically
5. Access from your dev workspace: `cd ~/workspace/repo/issue-123`

### Use Case 2: Create Worktree with Custom Branch

**When to use:** Working on a feature branch

**Steps:**
1. Create workspace from this template
2. Enter parameters:
   - Git Repository: `https://github.com/org/repo`
   - Branch Name: `feature-auth`
   - Setup Mode: `Create Worktree`
3. Workspace creates: `~/workspace/repo/feature-auth/`

### Use Case 3: Fresh Clone

**When to use:** Need a standalone clone (not a worktree)

**Steps:**
1. Create workspace from this template
2. Enter parameters:
   - Git Repository: `https://github.com/org/repo`
   - Setup Mode: `Clone Fresh`
3. Workspace creates: `~/workspace/repo/`

## Directory Structure

```
/home/coder/                           (Shared across all workspaces)
├── repos/
│   ├── repo-1/                        (Bare repository)
│   └── repo-2/                        (Bare repository)
└── workspace/
    ├── repo-1/
    │   ├── issue-123/                 (Worktree)
    │   ├── issue-456/                 (Worktree)
    │   └── feature-xyz/               (Worktree)
    └── repo-2/
        └── issue-123/                 (Different repo, same issue number - OK!)
```

## Parameters

| Parameter | Description | Example |
|-----------|-------------|---------|
| **Git Repository URL** | Repository to clone | `https://github.com/org/repo` |
| **Issue Number** | GitHub issue number | `123` |
| **Branch Name** | Custom branch name (overrides issue number) | `feature-auth` |
| **Setup Mode** | Worktree or Fresh Clone | `Create Worktree` |

## How It Works

### Worktree Mode

1. Creates bare repository in `~/repos/<repo-name>` (if not exists)
2. Fetches latest changes
3. Creates worktree in `~/workspace/<repo-name>/<branch-name>/`
4. Checks out existing branch or creates new one
5. Workspace stops automatically

### Clone Mode

1. Clones repository to `~/workspace/<repo-name>/`
2. Checks out specified branch
3. Workspace stops automatically

## Integration with Development Workspaces

### From Your Dev Workspace

After running this setup workspace, access the worktree from any of your development workspaces:

```bash
# List all worktrees
git -C ~/repos/repo-name worktree list

# Navigate to worktree
cd ~/workspace/repo-name/issue-123

# Start working
git status
```

### Example Workflow

```bash
# 1. Create setup workspace for issue #123
#    (via Coder UI)

# 2. From your dev workspace:
cd ~/workspace/repo-name/issue-123
git status

# 3. Work on the issue
# ... make changes ...

# 4. When done, create another setup workspace for issue #456
#    Both worktrees exist simultaneously in ~/workspace/
```

## Cleanup

### Manual Cleanup

To remove a worktree:

```bash
cd ~/repos/repo-name
git worktree remove ~/workspace/repo-name/issue-123
```

### Automatic Cleanup

Add to your dev workspace's startup script or dotfiles:

```bash
# Clean up worktrees for deleted branches
cd ~/repos/repo-name
git fetch --prune origin
git worktree prune
```

## Benefits

1. **Shared Home**: All workspaces share the same home directory
2. **Disk Efficiency**: Bare repository shared across worktrees
3. **Fast Setup**: No need to clone entire repo multiple times
4. **Issue Isolation**: Each issue gets its own worktree
5. **Parallel Work**: Work on multiple issues simultaneously
6. **Auto-Stop**: Setup workspace stops after completing its job

## Future Migration Path

This template can be extended to:
- Add workspace isolation (separate containers per issue)
- Add resource limits per workspace
- Add automatic cleanup on PR merge
- Integrate with CI/CD workflows

## Notes

- Same home volume name as dev workspaces: `coder-<user-id>-home`
- Workspace automatically stops after ~10 seconds
- GitHub authentication required (configured in Coder)
- Issue numbers can overlap across different repositories
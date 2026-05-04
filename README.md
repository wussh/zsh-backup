# Dotfiles Manager

A portable dotfiles management system that backs up zsh and other tool configurations, stores them in a version-controlled repository, and restores the full environment on a new machine with a single command.

## Quick Start (New Machine)

```sh
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/dotfiles/main/bin/bootstrap.sh | sh
```

Or with a specific profile:

```sh
DOTFILES_REMOTE=https://github.com/YOUR_USERNAME/dotfiles.git \
DOTFILES_PROFILE=server \
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/dotfiles/main/bin/bootstrap.sh | sh
```

## Installation (Existing Machine)

```sh
git clone https://github.com/YOUR_USERNAME/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./bin/dotfiles init --remote https://github.com/YOUR_USERNAME/dotfiles.git
./bin/dotfiles restore
```

## Usage

### Track a new config file

```sh
dotfiles add ~/.zshrc
dotfiles add ~/.gitconfig
```

### Backup changes to remote

```sh
dotfiles backup
```

### Restore configs on this machine

```sh
dotfiles restore
dotfiles restore --dry-run          # Preview without making changes
dotfiles restore --profile server   # Use a specific profile
```

### Sync (backup + restore)

```sh
dotfiles sync
```

### Check status

```sh
dotfiles status
```

### Manage profiles

```sh
dotfiles profile list
dotfiles profile use personal
```

### Initialize a new Config_Store

```sh
dotfiles init
dotfiles init --remote https://github.com/YOUR_USERNAME/dotfiles.git
```

## Profiles

| Profile  | Description                              |
|----------|------------------------------------------|
| default  | All standard zsh and tool configs        |
| personal | Full tool set for personal machines      |
| server   | Minimal set for headless servers         |
| work     | Work machine configuration               |

## Configuration

Edit `config/dotfiles.conf` to set defaults:

```sh
DOTFILES_REMOTE="https://github.com/YOUR_USERNAME/dotfiles.git"
DOTFILES_PROFILE="default"
DOTFILES_PLUGIN_MANAGER="zinit"
DOTFILES_BRANCH="main"
```

All values can be overridden with environment variables of the same name.

## Sensitive Files

Files matching patterns in `config/exclusions.txt` (e.g., `*_rsa`, `*.pem`, `*secret*`) will require explicit confirmation before being tracked. The `.gitignore` also excludes these patterns from git.

## Plugins

Edit `plugins.txt` to declare zsh plugins (one per line, GitHub `owner/repo` format or full URL).

## Tools

Edit `tools.txt` to declare CLI tools to install during bootstrap (one per line).

## Testing

```sh
make test-unit        # Run unit tests
make test-property    # Run property-based tests
make test-integration # Run integration tests (requires Docker)
make test-all         # Run all tests
```

# Dotfiles Manager

Portable dotfiles management for zsh and CLI tools.  
It tracks config files in this repo, symlinks them into your home directory, and restores them on another machine.

## What this project provides

- `bin/dotfiles`: main CLI (`add`, `backup`, `restore`, `sync`, `status`, `profile`, `init`)
- `bin/bootstrap.sh`: one-command bootstrap for a fresh machine
- `profiles/`: profile manifests (`default`, `personal`, `server`, `work`)
- `config/exclusions.txt`: sensitive-file exclusion patterns
- `plugins.txt` and `tools.txt`: plugin/tool manifests

## Quick Start

### Existing machine (this repo already cloned)

```sh
./bin/dotfiles init
./bin/dotfiles status
```

Run `dotfiles` as your normal user (`wush`), not with `sudo`.

### New machine bootstrap

```sh
DOTFILES_REMOTE="https://github.com/wussh/zsh-backup.git" \
curl -fsSL https://raw.githubusercontent.com/wussh/zsh-backup/main/bin/bootstrap.sh | sh
```

With a specific profile:

```sh
DOTFILES_REMOTE="https://github.com/wussh/zsh-backup.git" \
DOTFILES_PROFILE="server" \
curl -fsSL https://raw.githubusercontent.com/wussh/zsh-backup/main/bin/bootstrap.sh | sh
```

## Basic Usage

Use `./bin/dotfiles` directly, or add `bin/` to your `PATH`.

### Track files

```sh
./bin/dotfiles add ~/.zshrc
./bin/dotfiles add ~/.gitconfig
```

### Backup tracked changes (git commit + optional push)

```sh
./bin/dotfiles backup
```

### Restore links on current machine

```sh
./bin/dotfiles restore
./bin/dotfiles restore --dry-run
./bin/dotfiles restore --profile server
```

### Sync (backup then restore)

```sh
./bin/dotfiles sync
```

### Status and profiles

```sh
./bin/dotfiles status
./bin/dotfiles profile list
./bin/dotfiles profile use personal
```

## Configuration

Default config lives in `config/dotfiles.conf`:

```sh
DOTFILES_REMOTE=""
DOTFILES_PROFILE="default"
DOTFILES_PLUGIN_MANAGER="zinit"
DOTFILES_BRANCH="main"
```

Environment variables with the same names override file values.

## Local Repo Path

If cloned from GitHub with a standard command, use:

```txt
/home/wush/zsh-backup
```

If your clone is in the current workspace:

```txt
/home/wush/playground/zsh-backup
```

## Git User Setup

If git identity is not configured yet, set it once:

```sh
git config --global user.name "wussh"
git config --global user.email "you@example.com"
```

If you previously ran commands with `sudo` and got permission errors, fix ownership once:

```sh
sudo chown -R wush:wush /home/wush/playground/zsh-backup
```

## Sensitive Files

Patterns in `config/exclusions.txt` are treated as sensitive (`*_rsa`, `*_ed25519`, `*.pem`, `*.key`, `*secret*`, etc.).  
When you try to track a matching file, the CLI asks for explicit confirmation.

## Plugins and Tools

- Edit `plugins.txt` to define zsh plugins (one per line).
- Edit `tools.txt` to define CLI tools for bootstrap installs.

## Testing

Run all tests:

```sh
./run_tests.sh
```

Run specific suites:

```sh
./bats-core/bin/bats tests/unit
./bats-core/bin/bats tests/property
./bats-core/bin/bats tests/integration
```

## How-To Guide

See `HOWTO.md` for step-by-step workflows:

- first-time setup on current machine
- daily backup/sync workflow
- moving to a new machine
- adding custom exclusions and profiles

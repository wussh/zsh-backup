# Dotfiles How-To

Practical workflows for using this repository day-to-day.

## 1) First-Time Setup (Current Machine)

If this repo is already cloned:

```sh
cd ~/zsh-backup
./bin/dotfiles init
```

Use your normal user shell (`wush`) and do not run `dotfiles` with `sudo`.

Optionally set a remote for backup/push:

```sh
./bin/dotfiles init --remote https://github.com/wussh/zsh-backup.git
```

Track your main files:

```sh
./bin/dotfiles add ~/.zshrc
./bin/dotfiles add ~/.zprofile
./bin/dotfiles add ~/.gitconfig
./bin/dotfiles add ~/.tmux.conf
```

Check current tracked/symlink status:

```sh
./bin/dotfiles status
```

## 2) Daily Workflow

After editing tracked files:

```sh
./bin/dotfiles backup
```

If you also want to immediately re-apply links/state:

```sh
./bin/dotfiles sync
```

Preview restore actions without changing anything:

```sh
./bin/dotfiles restore --dry-run
```

## 3) Restore on Existing Machine

Pull and restore using default profile:

```sh
./bin/dotfiles restore
```

Use a specific profile:

```sh
./bin/dotfiles restore --profile server
```

If a regular file exists where a symlink should be, the tool will back it up with:

```txt
<filename>.bak.<timestamp>
```

## 4) Bootstrap a Brand-New Machine

Run from a new machine:

```sh
DOTFILES_REMOTE="https://github.com/wussh/zsh-backup.git" \
curl -fsSL https://raw.githubusercontent.com/wussh/zsh-backup/main/bin/bootstrap.sh | sh
```

With a profile:

```sh
DOTFILES_REMOTE="https://github.com/wussh/zsh-backup.git" \
DOTFILES_PROFILE="server" \
curl -fsSL https://raw.githubusercontent.com/wussh/zsh-backup/main/bin/bootstrap.sh | sh
```

## 5) Profiles

List profiles:

```sh
./bin/dotfiles profile list
```

Set active profile:

```sh
./bin/dotfiles profile use personal
```

Profile files are in `profiles/`:

- `default.yaml`
- `personal.yaml`
- `server.yaml`
- `work.yaml`

## 6) Sensitive Files and Exclusions

Default exclusion patterns are in:

```txt
config/exclusions.txt
```

When adding a matching file (for example private keys), the CLI asks for confirmation before tracking.

To add your own exclusion pattern, append a line in `config/exclusions.txt`, for example:

```txt
*.company-secret
```

## 7) Plugin and Tool Manifests

Manage plugins in `plugins.txt` (one per line):

```txt
zsh-users/zsh-autosuggestions
zsh-users/zsh-syntax-highlighting
```

Manage tool installs in `tools.txt` (one per line):

```txt
fzf
ripgrep:ripgrep
bat
eza
```

## 8) Test Commands

Run everything:

```sh
./run_tests.sh
```

Run suites individually:

```sh
./bats-core/bin/bats tests/unit
./bats-core/bin/bats tests/property
./bats-core/bin/bats tests/integration
```

## 9) Configure Git User (One-Time)

If git identity is missing on a machine, set it before `dotfiles backup`:

```sh
git config --global user.name "wussh"
git config --global user.email "you@example.com"
```

## 10) Fix Permissions After Running sudo (If Needed)

If you see errors like `Permission denied` when writing files in the repo:

```sh
sudo chown -R wush:wush /home/wush/playground/zsh-backup
```

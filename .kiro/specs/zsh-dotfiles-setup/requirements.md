# Requirements Document

## Introduction

A portable dotfiles management system that backs up zsh and other tool configurations from any machine, stores them in a version-controlled repository, and restores the full environment on a new machine or server with a single command. The system handles installing required tools (zsh, plugin managers, plugins), symlinking or copying config files, and keeping configurations in sync across machines.

## Glossary

- **Dotfiles_Manager**: The main CLI script that orchestrates backup, restore, and sync operations.
- **Config_Store**: The local directory (typically a git repository) where all tracked configuration files are stored.
- **Bootstrap_Script**: A single shell script that can be fetched and executed on a new machine to perform a full environment setup from scratch.
- **Symlink**: A filesystem symbolic link pointing from the expected config location (e.g., `~/.zshrc`) to the corresponding file inside the Config_Store.
- **Profile**: A named collection of config files and tool installation steps targeting a specific machine type (e.g., `personal`, `server`, `work`).
- **Plugin_Manager**: A zsh plugin management tool such as Oh My Zsh, Zinit, or Antigen.
- **Tracked_File**: A configuration file that has been added to the Config_Store and is managed by the Dotfiles_Manager.

---

## Requirements

### Requirement 1: Track and Back Up Configuration Files

**User Story:** As a developer, I want to add my config files to a central store, so that all my settings are preserved and version-controlled.

#### Acceptance Criteria

1. THE Dotfiles_Manager SHALL support adding individual files or directories to the Config_Store by specifying their absolute or home-relative path.
2. WHEN a file is added, THE Dotfiles_Manager SHALL copy the file into the Config_Store and create a Symlink from the original location to the stored copy.
3. WHEN a file is added that already exists in the Config_Store, THE Dotfiles_Manager SHALL overwrite the stored copy with the current version and update the Symlink.
4. THE Dotfiles_Manager SHALL track at minimum the following zsh files by default: `~/.zshrc`, `~/.zprofile`, `~/.zshenv`, `~/.zsh_aliases`, `~/.zsh_functions`.
5. THE Dotfiles_Manager SHALL track at minimum the following tool configs by default: `~/.gitconfig`, `~/.vimrc`, `~/.config/nvim/`, `~/.tmux.conf`, `~/.ssh/config`.
6. IF a file specified for tracking does not exist on the current machine, THEN THE Dotfiles_Manager SHALL skip that file and log a warning message identifying the skipped path.

---

### Requirement 2: Version Control Integration

**User Story:** As a developer, I want my dotfiles stored in a git repository, so that I can track changes over time and push them to a remote for access on any machine.

#### Acceptance Criteria

1. THE Dotfiles_Manager SHALL initialize the Config_Store as a git repository if one does not already exist.
2. WHEN the user runs a backup command, THE Dotfiles_Manager SHALL stage all changes in the Config_Store and create a git commit with a timestamp-based message.
3. WHERE a remote git repository URL is configured, THE Dotfiles_Manager SHALL push the commit to the configured remote after each backup.
4. IF the git push fails due to a network error, THEN THE Dotfiles_Manager SHALL log the error and exit with a non-zero status code without discarding the local commit.
5. THE Dotfiles_Manager SHALL support configuring the remote repository URL via an environment variable `DOTFILES_REMOTE` or a config file entry.

---

### Requirement 3: Single-Command Bootstrap on a New Machine

**User Story:** As a developer, I want to run one command on a new machine to restore my full environment, so that I can be productive immediately without manual setup steps.

#### Acceptance Criteria

1. THE Bootstrap_Script SHALL be executable with a single `curl | sh` or `wget | sh` invocation using a publicly accessible URL.
2. WHEN executed, THE Bootstrap_Script SHALL clone the Config_Store repository to a local directory on the new machine.
3. WHEN executed, THE Bootstrap_Script SHALL install zsh if it is not already present using the system package manager.
4. WHEN executed, THE Bootstrap_Script SHALL install the configured Plugin_Manager if it is not already present.
5. WHEN executed, THE Bootstrap_Script SHALL restore all Tracked_Files by creating Symlinks from their expected locations to the cloned Config_Store.
6. WHEN executed, THE Bootstrap_Script SHALL install all zsh plugins declared in the plugin manifest file.
7. IF a required system package manager command (`apt`, `brew`, `yum`, `pacman`) is not found, THEN THE Bootstrap_Script SHALL print a descriptive error message and exit with a non-zero status code.
8. WHEN the bootstrap completes successfully, THE Bootstrap_Script SHALL print a summary listing all installed tools and restored config files.

---

### Requirement 4: Profile-Based Configuration

**User Story:** As a developer, I want to define different profiles for different machine types, so that I can apply only the relevant configs and tools for each environment.

#### Acceptance Criteria

1. THE Dotfiles_Manager SHALL support defining named Profiles in a manifest file within the Config_Store.
2. WHEN a Profile name is passed to the bootstrap or restore command, THE Dotfiles_Manager SHALL apply only the files and installation steps declared in that Profile.
3. THE Dotfiles_Manager SHALL provide a default Profile named `default` that is applied when no Profile name is specified.
4. WHEN a Profile references a Tracked_File that does not exist in the Config_Store, THE Dotfiles_Manager SHALL log a warning and continue processing remaining items in the Profile.
5. THE Dotfiles_Manager SHALL support a `server` Profile that excludes GUI-only tools and configs (e.g., GUI application preferences).

---

### Requirement 5: Restore and Sync Configurations

**User Story:** As a developer, I want to restore or re-sync my configs on an existing machine, so that I can apply updates pulled from the remote repository.

#### Acceptance Criteria

1. WHEN the user runs the restore command, THE Dotfiles_Manager SHALL pull the latest changes from the configured remote repository.
2. WHEN the user runs the restore command, THE Dotfiles_Manager SHALL create or update Symlinks for all Tracked_Files in the active Profile.
3. IF a Symlink target path already exists as a regular file (not a Symlink), THEN THE Dotfiles_Manager SHALL back up the existing file with a `.bak` suffix before replacing it with a Symlink.
4. WHEN a restore completes, THE Dotfiles_Manager SHALL print a summary of all created, updated, and skipped Symlinks.
5. THE Dotfiles_Manager SHALL support a `--dry-run` flag that prints all actions that would be taken without modifying the filesystem.

---

### Requirement 6: Plugin and Tool Manifest

**User Story:** As a developer, I want to declare my zsh plugins and CLI tools in a manifest file, so that they are automatically installed during bootstrap.

#### Acceptance Criteria

1. THE Dotfiles_Manager SHALL read a plugin manifest file (e.g., `plugins.txt` or `manifest.yaml`) from the Config_Store that lists zsh plugins by name or repository URL.
2. WHEN bootstrapping, THE Dotfiles_Manager SHALL install each plugin listed in the manifest using the configured Plugin_Manager.
3. THE Dotfiles_Manager SHALL support declaring additional CLI tools (e.g., `fzf`, `ripgrep`, `bat`, `eza`) in the manifest for automatic installation.
4. WHEN a plugin or tool is already installed, THE Dotfiles_Manager SHALL skip its installation and log a message indicating it was already present.
5. IF a plugin installation fails, THEN THE Dotfiles_Manager SHALL log the error with the plugin name and continue installing remaining plugins.

---

### Requirement 7: Idempotent Operations

**User Story:** As a developer, I want to run the setup script multiple times safely, so that re-running it on an already-configured machine does not break anything.

#### Acceptance Criteria

1. WHEN the Bootstrap_Script is run on a machine where the environment is already fully configured, THE Bootstrap_Script SHALL complete without errors and without modifying any existing correct Symlinks or installed tools.
2. WHEN the restore command is run and a Symlink already points to the correct target, THE Dotfiles_Manager SHALL leave the Symlink unchanged and log it as already up-to-date.
3. FOR ALL restore operations, running the restore command twice in succession SHALL produce the same filesystem state as running it once.

---

### Requirement 8: Sensitive File Handling

**User Story:** As a developer, I want sensitive files excluded from the repository by default, so that secrets are not accidentally committed and pushed to a public remote.

#### Acceptance Criteria

1. THE Dotfiles_Manager SHALL maintain a default exclusion list that prevents tracking files matching patterns such as `*_rsa`, `*_ed25519`, `*.pem`, `*password*`, `*secret*`, `*token*`.
2. WHEN a user attempts to add a file matching an exclusion pattern, THE Dotfiles_Manager SHALL prompt the user to confirm before adding the file to the Config_Store.
3. THE Config_Store SHALL include a `.gitignore` file that excludes common sensitive file patterns by default.
4. THE Dotfiles_Manager SHALL support a user-defined exclusion list that extends the default exclusion patterns.

# Implementation Tasks: zsh-dotfiles-setup

## Task List

- [x] 1. Project scaffold and repository structure
  - [x] 1.1 Create the Config_Store directory layout (`bin/`, `config/`, `profiles/`, `files/`, `tests/`)
  - [x] 1.2 Create `.gitignore` with default sensitive file exclusion patterns (`*_rsa`, `*_ed25519`, `*.pem`, `*password*`, `*secret*`, `*token*`, `*.key`, `*.p12`, `.netrc`)
  - [x] 1.3 Create `config/dotfiles.conf` with default configuration values (`DOTFILES_PROFILE`, `DOTFILES_PLUGIN_MANAGER`, `DOTFILES_BRANCH`)
  - [x] 1.4 Create `config/exclusions.txt` with default sensitive file patterns
  - [x] 1.5 Create `profiles/default.yaml` with default profile (all standard zsh and tool config files)
  - [x] 1.6 Create `profiles/server.yaml` extending default, excluding GUI-only tools
  - [x] 1.7 Create `profiles/personal.yaml` and `profiles/work.yaml` as starter profiles
  - [x] 1.8 Create `plugins.txt` and `tools.txt` manifests with example entries and comment documentation
  - [x] 1.9 Create `README.md` with usage instructions and bootstrap command

- [-] 2. Config Loader (`bin/lib/config.sh`)
  - [-] 2.1 Implement `load_config()` that sources `config/dotfiles.conf` and applies environment variable overrides
  - [ ] 2.2 Implement `get_config(key)` and `set_config(key, value)` functions
  - [ ] 2.3 Implement `init_config()` that creates a default `dotfiles.conf` if none exists
  - [ ] 2.4 Write unit tests for config loading with env var override precedence

- [ ] 3. Sensitive File Filter (`bin/lib/sensitive.sh`)
  - [ ] 3.1 Implement `load_exclusions()` that reads default patterns from `config/exclusions.txt`
  - [ ] 3.2 Implement `is_sensitive(path)` that matches a path against all loaded exclusion patterns using glob matching
  - [ ] 3.3 Implement `prompt_sensitive_confirm(path)` that prints a warning and reads user confirmation
  - [ ] 3.4 Implement `add_user_exclusion(pattern)` that appends a pattern to `config/exclusions.txt`
  - [ ] 3.5 Write property tests for `is_sensitive()` — for any path matching an exclusion pattern, must return true (Property 3)
  - [ ] 3.6 Write property tests for user-defined exclusions — custom patterns must be treated identically to default patterns (Property 3)

- [ ] 4. File Tracker (`bin/lib/tracker.sh`)
  - [ ] 4.1 Implement `get_store_path(source_path)` that maps a home-relative or absolute path to its location under `files/`
  - [ ] 4.2 Implement `track_file(source_path)` that copies the file to the store and records the mapping in `files/manifest.txt`
  - [ ] 4.3 Implement `is_tracked(source_path)` that checks `files/manifest.txt` for an existing entry
  - [ ] 4.4 Implement `untrack_file(source_path)` that removes the file from the store and manifest
  - [ ] 4.5 Handle the case where `source_path` does not exist: log warning to stderr, return non-zero, do not modify store
  - [ ] 4.6 Handle the case where `source_path` matches a sensitive pattern: call `prompt_sensitive_confirm` before proceeding
  - [ ] 4.7 Handle the case where the file is already tracked: overwrite the stored copy with the current version
  - [ ] 4.8 Write property tests for `track_file` round-trip — for any file content, add then restore produces correct symlink (Property 1)
  - [ ] 4.9 Write property tests for skipped non-existent files — store unchanged, warning emitted (Property 7)

- [ ] 5. Symlink Manager (`bin/lib/symlink.sh`)
  - [ ] 5.1 Implement `create_symlink(store_path, target_path)` that creates a symlink, backing up any existing regular file with `.bak.<timestamp>` suffix
  - [ ] 5.2 Implement `validate_symlink(target_path)` that checks whether a symlink exists and points to the correct store path
  - [ ] 5.3 Implement `update_symlink(store_path, target_path)` that updates an existing symlink if the target has changed
  - [ ] 5.4 Implement `restore_all_symlinks(profile, dry_run)` that iterates profile files and calls `create_symlink` or `update_symlink` for each
  - [ ] 5.5 Implement dry-run mode: when `dry_run=true`, print actions to stdout without executing them
  - [ ] 5.6 Implement summary output: after restore, print counts of created, updated, and skipped symlinks
  - [ ] 5.7 Write property tests for idempotent restore — running restore twice produces same state (Property 2)
  - [ ] 5.8 Write property tests for backup file preservation — existing regular files get `.bak` copy before replacement (Property 5)
  - [ ] 5.9 Write property tests for dry-run non-modification — filesystem state unchanged after `--dry-run` (Property 8)

- [ ] 6. Profile Manager (`bin/lib/profile.sh`)
  - [ ] 6.1 Implement `load_profile(name)` that parses a YAML-like profile manifest using `awk`/`sed`
  - [ ] 6.2 Implement `get_profile_files(name)` that returns the list of store-relative file paths for a profile
  - [ ] 6.3 Implement `get_profile_tools(name)` that returns the list of tools declared in a profile
  - [ ] 6.4 Implement `resolve_profile_inheritance(name)` that merges a profile with its parent (`extends` field)
  - [ ] 6.5 Implement `list_profiles()` that lists all `.yaml` files in the `profiles/` directory
  - [ ] 6.6 Handle missing profile files: log warning and continue with remaining items
  - [ ] 6.7 Write property tests for profile file isolation — restore with profile P only creates symlinks for files in P (Property 4)
  - [ ] 6.8 Write property tests for partial failure continuation — missing profile files don't stop processing of remaining files (covers Requirement 4.4)

- [ ] 7. Git Operations (`bin/lib/git.sh`)
  - [ ] 7.1 Implement `git_init(dir)` that initializes a git repo if one doesn't exist
  - [ ] 7.2 Implement `git_commit(message)` that stages all changes and creates a commit
  - [ ] 7.3 Implement `git_push(remote, branch)` that pushes to the configured remote, logging errors without discarding local commits
  - [ ] 7.4 Implement `git_pull(remote, branch)` that pulls latest changes
  - [ ] 7.5 Implement `git_clone(url, dir)` that clones a remote repository
  - [ ] 7.6 Implement `git_set_remote(url)` that configures the remote URL
  - [ ] 7.7 Implement `git_status()` that returns the porcelain status output
  - [ ] 7.8 Write property tests for git commit on backup — any set of changes produces a new commit with timestamp-format message (Property 6)
  - [ ] 7.9 Write unit test for push failure handling — local commit preserved, non-zero exit code returned

- [ ] 8. Package Installer (`bin/lib/packages.sh`)
  - [ ] 8.1 Implement `detect_package_manager()` that checks for `brew`, `apt-get`, `yum`/`dnf`, `pacman`, `apk` in order
  - [ ] 8.2 Implement `install_package(name)` that calls the detected package manager with appropriate flags
  - [ ] 8.3 Implement `is_package_installed(name)` that checks if a command exists via `command -v`
  - [ ] 8.4 Handle missing package manager: print descriptive error listing supported managers, exit code 2
  - [ ] 8.5 Write unit tests for package manager detection with each supported manager mocked
  - [ ] 8.6 Write unit test for missing package manager error message and exit code

- [ ] 9. Plugin Installer (`bin/lib/plugins.sh`)
  - [ ] 9.1 Implement `install_plugin_manager(name)` supporting `zinit`, `oh-my-zsh`, and `antigen`
  - [ ] 9.2 Implement `is_plugin_manager_installed(name)` that checks for the plugin manager's presence
  - [ ] 9.3 Implement `install_plugin(plugin_spec)` that installs a single plugin via the configured plugin manager
  - [ ] 9.4 Implement `is_plugin_installed(name)` that checks if a plugin directory/file exists
  - [ ] 9.5 Implement `install_all_plugins()` that reads `plugins.txt` and installs each plugin, skipping already-installed ones and continuing on failure
  - [ ] 9.6 Write property tests for already-installed skip behavior — installed plugins are skipped with log message (covers Requirement 6.4)
  - [ ] 9.7 Write property tests for partial failure continuation — failed plugin installs don't stop remaining installs (covers Requirement 6.5)

- [ ] 10. Main CLI (`bin/dotfiles`)
  - [ ] 10.1 Implement argument parsing for subcommands: `add`, `backup`, `restore`, `sync`, `status`, `profile`, `init`
  - [ ] 10.2 Implement `dotfiles add <path>` — calls `track_file`, then calls `create_symlink`
  - [ ] 10.3 Implement `dotfiles backup` — calls `git_commit` with timestamp message, then `git_push` if remote configured
  - [ ] 10.4 Implement `dotfiles restore [--dry-run] [--profile <name>]` — calls `git_pull`, then `restore_all_symlinks`
  - [ ] 10.5 Implement `dotfiles sync` — runs backup then restore
  - [ ] 10.6 Implement `dotfiles status` — shows tracked files and their symlink validation status
  - [ ] 10.7 Implement `dotfiles profile list` and `dotfiles profile use <name>`
  - [ ] 10.8 Implement `dotfiles init [--remote <url>]` — calls `git_init`, optionally `git_set_remote`
  - [ ] 10.9 Implement consistent exit code behavior: 0 for success, 1 for warnings/partial, 2 for fatal errors
  - [ ] 10.10 Write integration tests for each subcommand using a temporary Config_Store directory

- [ ] 11. Bootstrap Script (`bin/bootstrap.sh`)
  - [ ] 11.1 Implement OS detection and package manager detection at the top of the script
  - [ ] 11.2 Implement `git` installation if not present
  - [ ] 11.3 Implement `zsh` installation if not present
  - [ ] 11.4 Implement Config_Store clone from `$DOTFILES_REMOTE`
  - [ ] 11.5 Implement profile selection from `$DOTFILES_PROFILE` env var or `--profile` argument
  - [ ] 11.6 Implement plugin manager installation
  - [ ] 11.7 Implement plugin installation from `plugins.txt`
  - [ ] 11.8 Implement tool installation from `tools.txt` filtered by active profile
  - [ ] 11.9 Implement symlink restoration for active profile
  - [ ] 11.10 Implement completion summary: list all installed tools and restored config files
  - [ ] 11.11 Implement optional `chsh` to set zsh as default shell
  - [ ] 11.12 Ensure the script is self-contained (no sourcing of lib files) so it can be piped via `curl | sh`
  - [ ] 11.13 Write integration test: run bootstrap in Docker Ubuntu container, verify full environment setup
  - [ ] 11.14 Write integration test: run bootstrap in Docker Alpine container, verify apk-based install path
  - [ ] 11.15 Write integration test: run bootstrap twice in same container, verify idempotent behavior

- [ ] 12. Test infrastructure setup
  - [ ] 12.1 Install `bats-core` as a git submodule or via package manager
  - [ ] 12.2 Create `tests/helpers/setup_helpers.bash` with common `setup()` and `teardown()` functions using temp directories
  - [ ] 12.3 Create `tests/helpers/generators.bash` with random input generator functions for property tests
  - [ ] 12.4 Create `Makefile` or `run_tests.sh` with targets: `test-unit`, `test-property`, `test-integration`, `test-all`
  - [ ] 12.5 Create `Dockerfile.ubuntu` and `Dockerfile.alpine` for integration test containers
  - [ ] 12.6 Configure property tests to run minimum 100 iterations per property

- [ ] 13. Default file tracking and initialization
  - [ ] 13.1 Implement `dotfiles init` to create the default `files/manifest.txt` with entries for all standard zsh and tool config files
  - [ ] 13.2 Implement logic to skip files that don't exist on the current machine during init (log warning per Requirement 1.6)
  - [ ] 13.3 Write smoke tests verifying the default tracked file list includes all required zsh files (Requirement 1.4)
  - [ ] 13.4 Write smoke tests verifying the default tracked file list includes all required tool configs (Requirement 1.5)

- [ ] 14. End-to-end validation and documentation
  - [ ] 14.1 Write a full end-to-end test: add files → backup → simulate new machine → bootstrap → verify environment
  - [ ] 14.2 Verify all 8 correctness properties have corresponding property-based tests
  - [ ] 14.3 Update `README.md` with complete usage examples, profile documentation, and bootstrap URL instructions
  - [ ] 14.4 Add inline comments to all shell scripts documenting function contracts and error conditions
  - [ ] 14.5 Verify all scripts pass `shellcheck` with no errors

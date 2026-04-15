# Changelog

All notable changes to this project will be documented in this file.

The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.2] - 2026-04-15

### Added

- Added `rpmlint` filters to suppress `non-standard-uid`/`gid` warnings for the
  `podman-ai` system user.

### Changed

- Included `%doc` for subpackages in the RPM spec file to resolve
  `no-documentation` warnings.
- Updated `CONTRIBUTING.md` with instructions for installing `shellcheck` and
  `markdownlint-cli`.
- Switched Markdown linting configuration from YAML/JSON to `.jsonc` and
  standardized CI and local lint commands to use `.github/.markdownlint.jsonc`.
- Updated the CI Markdown lint step to use `markdownlint-cli2-action` with
  explicit Markdown globs for repository-wide checks.
- Removed obsolete `.github/linters/ignore` and legacy
  `.github/linters/markdownlint.yaml` configuration files.

### Fixed

- Resolved `shellcheck` SC2115 warning in `scripts/update-repo.sh` by ensuring
  safe expansion of variables in `rm -rf`.
- Corrected Markdown formatting issues in GitHub issue and pull request
  templates to satisfy linting rules and avoid heading/line-length violations.

## [0.2.1] - 2026-04-15

### Changed

- Improved RPM spec compliance by adding a `%check` section for build-time
  validation.
- Resolved `rpmlint` warnings regarding missing documentation in subpackages by
  adding `%license` to all subpackages.
- Fixed `rpmlint` macro-in-changelog warnings by escaping `%` characters in the
  spec file.
- Updated `Source0` URL in spec file for better standards compliance.

## [0.2.0] - 2026-04-15

### Added

- **CI/CD Pipeline**: Introduced a comprehensive GitHub Actions workflow for
  pull requests and main branch pushes.
- **Linting**: Automated shell script linting (`shellcheck`), Markdown linting
  (`markdownlint`), and RPM spec/package linting (`rpmlint`).
- **Packaging Verification**: Added `make verify-rpm` target to build and
  validate RPM integrity locally and in CI.
- **Smoke Tests**: Integrated basic installation and service status verification
  in the CI pipeline.
- **Project Badges**: Added a CI status badge to the `README.md`.

### Changed

- Improved `CONTRIBUTING.md` with instructions for local linting and
  verification.
- Refactored `Makefile` for better build reliability and standard compliance.
- Optimized RPM spec file descriptions and file ownership handling.

### Fixed

- Resolved `tar` concurrency issues during RPM building by excluding the
  `rpmbuild` directory.
- Fixed missing directory creation in the build root for the `podman-ai` user.

## [0.1.0-5] - 2026-04-14

### Changed

- Attempted fix for GitHub workflow RPM signing by escaping positional
  parameters (`%%{1}` and `%%{2}`) in the `%__gpg_sign_cmd` macro definition to
  ensure proper RPM macro expansion.
- Configured GPG loopback pinentry, batch mode, and no-tty for non-interactive
  CI environments.
- Added `--pinentry-mode loopback` to repository metadata signing in
  `scripts/update-repo.sh`.
- Exported `GPG_TTY` in GitHub workflow to suppress terminal-related warnings.

## [0.1.0-4] - 2026-04-14

### Changed

- Added automatic signature cleanup (`rpm --delsig`) to `make sign` to handle
  "legacy signature" conflicts.
- Refactored `Makefile` to use `RPM_DIR` variable and improved overall
  robustness.
- Enhanced `scripts/update-repo.sh` with dependency checks and a usage function.

## [0.1.0-3] - 2026-04-14

### Changed

- Improved GPG key discovery in `Makefile` and `update-repo.sh` to automatically
  use `%_gpg_name` macro.
- Made `GPG_KEY_ID` parameter optional for both RPM signing and repository
  metadata signing.
- Refactored `scripts/update-repo.sh` for better readability and more
  professional logic.

## [0.1.0-2] - 2026-04-14

### Changed

- Updated DNF repository structure to support versioned channels (e.g.,
  `v0.1/stable`, `latest/testing`).
- Modified `scripts/update-repo.sh` to automatically organize RPMs and sync
  `latest` pointers.
- Updated GitHub Actions workflow to deploy the new repository structure to
  GitHub Pages.
- Improved documentation in `DEVELOPMENT.md` and `GEMINI.md` to reflect the new
  build process.

## [0.1.0-1] - 2026-04-11

### Changed

- Clarified that the `ollama` container is optional and not started by default.
- Added documentation for using the built-in Ollama service or an external
  server.
- Clarified rootless Quadlet installation paths and configuration mechanisms in
  `README.md`.
- Added support for optional user-specific configuration via
  `~/.config/podman-ai-stack.env`.
- Added documentation for disabling the dedicated bridge network in `README.md`.
- Added "Advanced Customization (Masking)" documentation for users who need
  total control over the Quadlet definitions.
- Improved `/etc/sysconfig/podman-ai-stack` with documented default variables
  and reference links.
- Updated `README.md` with comprehensive project description and DNF repository
  integration steps.

### Added

- Marked all Quadlet files as `%config(noreplace)` to preserve user
  modifications during updates.
- Refined automated cleanup of user-level pods to use runuser and
  XDG_RUNTIME_DIR.
- Automated cleanup of user-level pods during uninstallation.
- Initial release of the Podman AI Stack.
- Podman Quadlet templates for Ollama and Open WebUI.
- Rootless and Rootfull deployment support via RPM subpackages.
- Configurable build-time variables for ports, images, and resource limits.
- `/etc/sysconfig/podman-ai-stack` for runtime environment variable
  configuration.
- GPG signing support for RPM builds.
- Integrated `createrepo_c` support for DNF repository management.
- Comprehensive documentation and contribution guidelines.

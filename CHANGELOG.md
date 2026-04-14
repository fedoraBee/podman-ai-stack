# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0-2] - 2026-04-14

### Changed
- Updated DNF repository structure to support versioned channels (e.g., `v0.1/stable`, `latest/testing`).
- Modified `scripts/update-repo.sh` to automatically organize RPMs and sync `latest` pointers.
- Updated GitHub Actions workflow to deploy the new repository structure to GitHub Pages.
- Improved documentation in `DEVELOPMENT.md` and `GEMINI.md` to reflect the new build process.

## [0.1.0-1] - 2026-04-11

### Changed
- Clarified that the `ollama` container is optional and not started by default.
- Added documentation for using the built-in Ollama service or an external server.
- Clarified rootless Quadlet installation paths and configuration mechanisms in `README.md`.
- Added support for optional user-specific configuration via `~/.config/podman-ai-stack.env`.
- Added documentation for disabling the dedicated bridge network in `README.md`.
- Added "Advanced Customization (Masking)" documentation for users who need total control over the Quadlet definitions.
- Improved `/etc/sysconfig/podman-ai-stack` with documented default variables and reference links.
- Updated `README.md` with comprehensive project description and DNF repository integration steps.

### Added
- Marked all Quadlet files as `%config(noreplace)` to preserve user modifications during updates.
- Refined automated cleanup of user-level pods to use runuser and XDG_RUNTIME_DIR.
- Automated cleanup of user-level pods during uninstallation.
- Initial release of the Podman AI Stack.
- Podman Quadlet templates for Ollama and Open WebUI.
- Rootless and Rootfull deployment support via RPM subpackages.
- Configurable build-time variables for ports, images, and resource limits.
- `/etc/sysconfig/podman-ai-stack` for runtime environment variable configuration.
- GPG signing support for RPM builds.
- Integrated `createrepo_c` support for DNF repository management.
- Comprehensive documentation and contribution guidelines.

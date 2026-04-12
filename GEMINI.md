# Podman AI Stack: Technical Manifest

The Podman AI Stack is a secure, configurable, and systemd-native orchestration stack for deploying containerized AI environments (Open WebUI and Ollama). It leverages Podman Quadlets to provide a seamless integration with systemd, supporting both rootless and rootfull deployments on Fedora and other RPM-based distributions.

## 🏗 Architectural Overview

The project is structured around a base RPM package with deployment-specific subpackages:

### 1. Base Package (`podman-ai-stack`)
- **Shared Configuration**: Installs `/etc/sysconfig/podman-ai-stack` for container environment variables.
- **User-Level Quadlets**: Installs rootless Quadlet templates to `/usr/share/containers/systemd/users/`.
- **Manual Usage**: Allows any user to immediately run the stack via `systemctl --user start open-webui`.

### 2. User Subpackage (`podman-ai-stack-user`)
- **Provisioning**: Automates the creation of the dedicated `podman-ai` system user and group.
- **Persistence**: Enables systemd lingering for the `podman-ai` user, allowing services to start at boot without an active login.

### 3. Root Subpackage (`podman-ai-stack-root`)
- **System-Wide Deployment**: Installs system-level Quadlets to `/usr/share/containers/systemd/`.
- **System Services**: Automatically enables the generated `open-webui.service` and `ollama.service` as standard system services.

## 🛠 Project Standards

- **Quadlet Locations**:
  - Rootless (Global): `/usr/share/containers/systemd/users/`
  - Rootfull (System): `/usr/share/containers/systemd/`
- **Variable Substitution**: Quadlet templates (`.in` files) use `@VARIABLE@` placeholders which are replaced during `make install` using `sed`.
- **Configuration Persistence**: The `/etc/sysconfig/podman-ai-stack` file is marked as `noreplace` to preserve user overrides during package updates.
- **Network Isolation**: Uses a dedicated bridge network (`podman-ai-stack.network`) for communication between containers.
- **Security**: Default deployments are rootless for maximum isolation and security.

## 🚀 Deployment Workflow

To deploy changes locally for testing:
1.  **Build the RPM:** `make rpm`
2.  **Update Local Repo:** `cp -r rpmbuild/RPMS/ ../dnf-repos/podman-ai-stack/`
3.  **Install/Reinstall:** `sudo dnf reinstall -Cy ../dnf-repos/podman-ai-stack/RPMS/noarch/podman-ai-stack-0.1.0-1.fc43.noarch.rpm`
4.  **Reload Systemd:** `systemctl daemon-reload --user`
5.  **Restart Service:** `systemctl --user restart podman-ai-stack-pod`

## 🤖 Gemini CLI Guidelines

- **Self-Correction**: Automatically re-read the `GEMINI.md` file immediately after making any changes to it to ensure your active context is always up-to-date with the latest project-specific guidelines.
- **Professionalism**: Maintain the highest standards of professional conduct.
 This includes writing clean, idiomatic code, providing clear and concise communication, and ensuring all changes are thoroughly verified before completion.
- **Atomic Commits**: Automatically commit all successful changes to Git. Each commit should be atomic and represent a single logical change. Use clear and descriptive commit messages that follow project conventions.
- **Surgical Updates**: When modifying Quadlet templates, ensure placeholders like `@VARIABLE@` are preserved or updated in the `Makefile` substitution logic.
- **Verification**: After modifying the RPM spec or Makefile, always verify the file paths and deployment logic.
- **Documentation**:
  - Update `DEVELOPMENT.md` if build steps, variables, or prerequisites change.
  - Update `README.md` if installation methods or user-facing features change.
  - **Changelog Synchronization**: For every feature, fix, or release, you must update both `CHANGELOG.md` (for users) and the `rpm/podman-ai-stack.spec` `%changelog` section (for package management). Ensure the version, date, and core details match exactly between both files.
- **Best Practices**:
  - Follow Fedora packaging guidelines for RPMs.
  - Adhere to Podman Quadlet standards for unit files and generators.
  - Ensure all scripts (pre/post/postun) are idempotent and handle failures gracefully.

## 📦 Reference Docs
- [README.md](README.md): Installation and usage guide.
- [CONTRIBUTING.md](CONTRIBUTING.md): Guidelines for contributors.
- [DEVELOPMENT.md](DEVELOPMENT.md): Build instructions and technical notes.
- [CHANGELOG.md](CHANGELOG.md): Record of notable changes and versions.
- [LICENSE](LICENSE): MIT License.

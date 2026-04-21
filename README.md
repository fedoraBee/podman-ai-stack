# Podman AI Stack

[![CI](https://github.com/fedoraBee/podman-ai-stack/actions/workflows/ci.yml/badge.svg)](https://github.com/fedoraBee/podman-ai-stack/actions/workflows/ci.yml)
[![Release](https://github.com/fedoraBee/podman-ai-stack/actions/workflows/release.yml/badge.svg)](https://github.com/fedoraBee/podman-ai-stack/actions/workflows/release.yml)

The Podman AI Stack provides a secure, configurable, and systemd-native
orchestration stack for deploying containerized AI environments (Open WebUI and
Ollama).

It leverages Podman Quadlets to integrate seamlessly with systemd and supports
both **rootless** and **rootfull** deployments on Fedora and other RPM-based
distributions.

Pull requests are validated with ShellCheck, `actionlint`, Markdown, and RPM
checks plus install smoke tests across Fedora 40, 41, 42, and Rawhide for
current-user rootless, service-user rootless, and rootfull package paths.

## ✨ Features

- **Rootless-first** – Run entirely without root privileges
- **Systemd-native** – Managed via Podman Quadlets
- **Secure by default** – Isolated networking, read-only root filesystems,
  dropped capabilities, and strict SELinux boundaries
- **Flexible configuration** – Environment-based configuration via
  `/etc/sysconfig/podman-ai-stack`
- **Multiple deployment modes** – User, dedicated service user, or system-wide

## 📦 Installation via DNF (Recommended)

Packages are distributed via a dedicated DNF repository hosted on GitHub Pages:

👉 <https://fedorabee.github.io/podman-ai-stack/rpms/>

### 1. Add the Repository

```bash
sudo tee /etc/yum.repos.d/podman-ai-stack.repo <<'EOF'
[podman-ai-stack]
name=Podman AI Stack - Stable
baseurl=https://fedorabee.github.io/podman-ai-stack/rpms/latest/stable/
enabled=1
gpgcheck=1
gpgkey=https://fedorabee.github.io/podman-ai-stack/rpms/gpg.key

[podman-ai-stack-testing]
name=Podman AI Stack - Testing
baseurl=https://fedorabee.github.io/podman-ai-stack/rpms/latest/testing/
enabled=0
gpgcheck=1
gpgkey=https://fedorabee.github.io/podman-ai-stack/rpms/gpg.key
EOF
```

### 2. Update Cache

```bash
sudo dnf makecache
```

## 🔐 GPG Key

The GPG key is available at
<https://fedorabee.github.io/podman-ai-stack/rpms/gpg.key>.

Fingerprint:

```text
8D12 D614 9E1E 5E83 29DD E6FD 9B99 A03F 6577 BF59
```

## 🚀 Installation Options

The stack is split into a base package and deployment-specific subpackages. **By
default, only the Open WebUI service is started.**

### Option 1: Rootless (Current User)

Ideal for personal workstations.

```bash
sudo dnf install podman-ai-stack
systemctl --user daemon-reload
systemctl --user start podman-ai-stack-pod
```

Monitor logs:

```bash
journalctl --user -u open-webui.service -f
```

### Option 2: Rootless (Dedicated System User)

Recommended for server-like deployments.

```bash
sudo dnf install podman-ai-stack-user
sudo -u podman-ai systemctl --user start podman-ai-stack-pod
```

> ℹ️ Lingering is enabled automatically by the package.

Monitor logs:

```bash
sudo -u podman-ai XDG_RUNTIME_DIR=/run/user/$(id -u podman-ai) \
  journalctl --user -u ollama.service -f
```

### Option 3: Rootfull (System-wide)

```bash
sudo dnf install podman-ai-stack-root
sudo systemctl start podman-ai-stack-pod
```

Monitor logs:

```bash
sudo journalctl -u podman-ai-stack-pod.service -f
```

## 🤖 Using Ollama

The stack includes an optional Ollama service.

By default, Open WebUI connects to:

```text
http://localhost:11434
```

### Start Ollama

```bash
# Rootless (current user)
systemctl --user start ollama

# Dedicated user
sudo -u podman-ai systemctl --user start ollama

# Rootfull
sudo systemctl start ollama
```

### External Ollama

Set:

```text
OLLAMA_BASE_URL=<your-server>
```

## 🖥️ Hardware Requirements & Sizing

AI workloads require specific hardware considerations, particularly GPU VRAM.
For a detailed breakdown of model sizes (e.g., Llama 3 8B vs 70B) and
instructions on how to dynamically tweak CPU and Memory constraints safely via
systemd drop-ins, please read the [Hardware Guide](HARDWARE.md).

## ⚙️ Configuration

### Runtime Configuration (Environment)

Configuration files are loaded in order:

1. `/etc/sysconfig/podman-ai-stack`
2. `~/.config/podman-ai-stack.env`

Common options:

- `OLLAMA_BASE_URL`
- `OLLAMA_HOST`

### Build-time Configuration

Certain parameters (ports, limits, image versions) are defined at build time.

See: `DEVELOPMENT.md`

## 🧩 Advanced Customization (Quadlet Overrides)

User-level Quadlets override system templates:

```bash
~/.config/containers/systemd/
```

Overrides:

```bash
/etc/containers/systemd/users/
```

### Example: Customize Open WebUI

```bash
mkdir -p ~/.config/containers/systemd/
cp /etc/containers/systemd/users/open-webui.container \
   ~/.config/containers/systemd/
```

```bash
systemctl --user daemon-reload
systemctl --user restart open-webui
```

### External Database (PostgreSQL)

For larger deployments, you can decouple Open WebUI's state from SQLite to
PostgreSQL. Uncomment and configure `DATABASE_URL` in
`/etc/sysconfig/podman-ai-stack`:

```ini
DATABASE_URL=postgresql://openwebui:openwebui_secret@localhost:5432/openwebui
```

We ship an optional Postgres Quadlet template if you wish to run it within the
stack:

```bash
# Start the postgres database
systemctl --user start postgres

# Restart open-webui to pick up the new database connection
systemctl --user restart open-webui
```

### Disable Dedicated Network

Edit:

```bash
~/.config/containers/systemd/podman-ai-stack.pod
```

```ini
[Pod]
# Network=podman-ai-stack.network
```

```bash
systemctl --user daemon-reload
systemctl --user restart podman-ai-stack-pod
```

## 🔐 Secrets Management (Postgres & API Keys)

For enhanced security, avoid storing database passwords or external API keys
(like OpenAI keys) in plain-text configuration files. Podman Quadlets support
native secrets.

### 1. Create the Secrets

Initialize your secrets using the `podman secret create` command:

```bash
# Set a PostgreSQL password
echo "my-secret-db-pass" | podman secret create postgres_password -

# (Optional) Set an external database URL for Open WebUI
echo "postgresql://openwebui:my-secret-db-pass@localhost:5432/openwebui" | \
podman secret create openwebui_database_url -
# (Optional) Set an OpenAI API Key
echo "sk-your-api-key" | podman secret create openai_api_key -
```

*(Note: If using the dedicated service user deployment, prefix with
`sudo -u podman-ai`)*

### 2. Enable Secrets in Quadlets

Override your Quadlets to use the created secrets via systemd drop-ins
(`systemctl --user edit open-webui` or `postgres`):

```ini
[Container]
Secret=postgres_password,type=env,target=POSTGRES_PASSWORD
# Secret=openwebui_database_url,type=env,target=DATABASE_URL
# Secret=openai_api_key,type=env,target=OPENAI_API_KEY
```

Or uncomment the `Secret=` directives directly if you manage the `.container`
templates manually.

## 🔄 Auto-Updates

The Quadlet containers are configured to automatically pull new image versions
(`AutoUpdate=registry`). To operationalize this, enable the Podman auto-update
timer:

```bash
# Rootless (current user or dedicated user)
systemctl --user enable --now podman-auto-update.timer

# Rootfull
sudo systemctl enable --now podman-auto-update.timer
```

> ℹ️ For Rootfull deployments, the RPM package automatically enables this timer
> during installation.

## 💾 Backup & Restore

Open WebUI and Ollama store important state (chats, configurations, and models)
in Podman volumes. We provide a script to safely export these volumes without
corrupting active database writes by temporarily pausing the container
processes.

### Backup

Run the included backup script to pause the containers and export their volumes
safely:

```bash
./scripts/backup-ai-stack.sh /path/to/backup/dir
```

*(Note: If using the dedicated service user deployment, prefix with
`sudo -u podman-ai`)*

### Restore

To restore from a backup archive:

```bash
# 1. Stop the pod
systemctl --user stop podman-ai-stack-pod

# 2. Import the volume data
podman volume import open-webui /path/to/backup/dir/open-webui-backup.tar
podman volume import ollama /path/to/backup/dir/ollama-backup.tar

# 3. Restart the pod
systemctl --user start podman-ai-stack-pod
```

## 🔄 Restart Services

```bash
# Rootless
systemctl --user restart podman-ai-stack-pod

# Dedicated user
sudo -u podman-ai systemctl --user restart podman-ai-stack-pod

# Rootfull
sudo systemctl restart podman-ai-stack-pod
```

## 📁 Repository Contents

The package repository contains:

- RPM packages:
  - `podman-ai-stack`
  - `podman-ai-stack-user`
  - `podman-ai-stack-root`

- Repository metadata (`repodata/`)
- GPG signing key

## GitOps PR CLI Tool

The project includes a `scripts/gitops-pr-cli-tool.sh` to automate and enforce
the Pull Request workflow. It performs the following checks:

- Branch naming validation.
- Version extraction from branch name.
- Verification that `CHANGELOG.md` contains the version.
- Verification that the RPM spec file's `Version` field is automatically updated
  by `scripts/update-rpm-metadata.py` from the `Makefile`'s `VERSION` variable,
  and this value is validated.
- Ensure the `Makefile` version is synchronized with the RPM spec and
  `CHANGELOG.md`.
- Automatic PR body generation from commit messages.

### Prerequisites

- **GitHub CLI (`gh`)**: The tool requires the GitHub CLI to be installed and
  authenticated.

Usage:

```bash
./scripts/gitops-pr-cli-tool.sh --target <branch-name> \
  [--base main] \
  [--title "PR Title"] \
  [--message "PR Body"] \
  [--reviewers user1,user2] \
  [--remote origin] \
  [--dry-run]
```

## Git Clean & Switch Tool

A `scripts/git-clean-switch-tool.sh` is provided to safely reset the current Git
branch to a remote source, clean the worktree, and prepare a development branch.
This is useful for quickly synchronizing a development environment to a known
good state.

Usage:

```bash
./scripts/git-clean-switch-tool.sh \
  [--base main] \
  [--target dev] \
  [--backup backup-main-timestamp] \
  [--remote origin] \
  [--dry-run]
```

## 🔗 Resources

- 🌐 DNF Repository: <https://fedorabee.github.io/podman-ai-stack/rpms/>
- 📦 Repo Source (gh-pages):
  <https://github.com/fedoraBee/podman-ai-stack/tree/gh-pages>
- 💻 Development: <https://github.com/fedoraBee/podman-ai-stack>

## ⚠️ Disclaimer

This is an independent project and not affiliated with Fedora.

Use in production environments at your own discretion.

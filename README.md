# Podman AI Stack

The **Podman AI Stack** is a secure, configurable, and systemd-native orchestration stack for deploying containerized AI environments (Open WebUI and Ollama). It leverages **Podman Quadlets** to provide a seamless integration with systemd, supporting both rootless and rootfull deployments on Fedora and other RPM-based distributions.

## Features
- **Rootless**: Runs entirely without root privileges for maximum security.
- **Systemd-Native**: Uses Podman Quadlets for seamless systemd integration and lifecycle management.
- **Secure**: Pre-configured with secure defaults and isolated bridge networks.
- **Configurable**: Easy-to-manage environment variables via `/etc/sysconfig/podman-ai-stack`.

## Repository
To install the stack via DNF, you can add the repository to your system.

### 1. Add the Repository
Create a new repo file in `/etc/yum.repos.d/`:

```bash
sudo tee /etc/yum.repos.d/podman-ai-stack.repo <<EOF
[podman-ai-stack]
name=Podman AI Stack
baseurl=https://raw.githubusercontent.com/fedoraBee/podman-ai-stack/main/rpms/noarch/
enabled=1
gpgcheck=0
EOF
```

### 2. Update Cache
```bash
sudo dnf makecache
```

## Installation
The stack is split into a base package and deployment-specific subpackages. **By default, only the Open WebUI service is started.**

### Option 1: Rootless (Current User)
Ideal for personal workstations. Installs templates to the system-wide rootless Quadlet directory (`/etc/containers/systemd/users/`).
```bash
sudo dnf install podman-ai-stack
systemctl --user daemon-reload
systemctl --user start podman-ai-stack-pod
```

### Option 2: Rootless (Dedicated System User)
Recommended for server-like deployments. Installs templates to `/etc/containers/systemd/users/`, creates a dedicated `podman-ai` user, and enables systemd lingering.
```bash
sudo dnf install podman-ai-stack-user
sudo -u podman-ai systemctl --user start podman-ai-stack-pod
```

### Option 3: Rootfull (System-wide)
Runs as a standard root system service. Installs templates to the system-wide Quadlet directory (`/etc/containers/systemd/`).
```bash
sudo dnf install podman-ai-stack-root
sudo systemctl start podman-ai-stack-pod
```

## Using Ollama
The stack includes an optional Ollama service. By default, Open WebUI is configured to connect to a local Ollama instance at `http://localhost:11434`.

### Using the Built-in Ollama Container
If you want to run Ollama as part of the stack, you must start the service explicitly:
```bash
# For rootless (current user)
systemctl --user start ollama

# For dedicated user
sudo -u podman-ai systemctl --user start ollama

# For rootfull
sudo systemctl start ollama
```

### Using an External Ollama Server
If you already have an Ollama server running elsewhere (e.g., on a different host or as a standalone service), you can point Open WebUI to it by setting the `OLLAMA_BASE_URL` in your configuration file.

See the [Configuration](#configuration) section for details on how to set this variable.

## Configuration
The stack supports two types of configuration:

### 1. Runtime Configuration (Environment Variables)
Most settings can be customized by editing the environment files. The stack loads them in the following order (later files override earlier ones):

1.  **Global Configuration**: `/etc/sysconfig/podman-ai-stack` (Mandatory, managed by the package).
2.  **User-specific Configuration**: `~/.config/podman-ai-stack.env` (Optional, allows user overrides without root).

Common options:
- `OLLAMA_BASE_URL`: The URL used by Open WebUI to connect to Ollama (default: `http://localhost:11434`).
- `OLLAMA_HOST`: The host address Ollama binds to (default: `0.0.0.0`).

### 2. Build-time Configuration (Quadlet Keys)
Some parameters (like host ports, memory limits, and image versions) are "baked into" the Quadlet files during the RPM build process. To change these, you must rebuild the RPM with custom flags (see [DEVELOPMENT.md](DEVELOPMENT.md)).

## Advanced Customization (Masking)
Podman Quadlets support a priority-based override mechanism. You can completely customize any part of the stack by placing a modified copy of a Quadlet file in your user-specific configuration directory.

User-specific files in **`~/.config/containers/systemd/`** will mask (override) the system-provided versions in `/etc/containers/systemd/users/`.

**Example: Customizing the Open WebUI container**
1. Copy the system template to your local config:
   ```bash
   mkdir -p ~/.config/containers/systemd/
   cp /etc/containers/systemd/users/open-webui.container ~/.config/containers/systemd/
   ```
2. Edit your local copy as needed.
3. Apply changes:
   ```bash
   systemctl --user daemon-reload
   systemctl --user restart open-webui
   ```

### Disabling the Dedicated Network
By default, the stack creates a dedicated bridge network (`podman-ai-stack.network`). If you prefer to use the default Podman network:

1. Copy the Pod template to your local config:
   ```bash
   mkdir -p ~/.config/containers/systemd/
   cp /etc/containers/systemd/users/podman-ai-stack.pod ~/.config/containers/systemd/
   ```
2. Edit `~/.config/containers/systemd/podman-ai-stack.pod` and comment out or remove the `Network=` line:
   ```ini
   [Pod]
   # Network=podman-ai-stack.network
   ```
3. Reload and restart:
   ```bash
   systemctl --user daemon-reload
   systemctl --user restart podman-ai-stack-pod
   ```
4. (Optional) Stop the now-unused network service:
   ```bash
   systemctl --user stop podman-ai-stack-network.service
   ```

After modifying the configuration, restart the services:
```bash
# For rootless (current user)
systemctl --user restart podman-ai-stack-pod

# For dedicated user
sudo -u podman-ai systemctl --user restart podman-ai-stack-pod

# For rootfull
sudo systemctl restart podman-ai-stack-pod
```

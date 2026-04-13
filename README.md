# Podman AI Stack

The **Podman AI Stack** is a secure, configurable, and systemd-native orchestration stack for deploying containerized AI environments such as Open WebUI and Ollama.

It leverages Podman Quadlets to integrate seamlessly with systemd and supports both **rootless** and **rootfull** deployments on Fedora and other RPM-based distributions.

---

## ✨ Features

* **Rootless-first** – Run entirely without root privileges
* **Systemd-native** – Managed via Podman Quadlets
* **Secure by default** – Isolated networking and minimal privileges
* **Flexible configuration** – Environment-based configuration via `/etc/sysconfig/podman-ai-stack`
* **Multiple deployment modes** – User, dedicated service user, or system-wide

---

## 📦 Installation via DNF (Recommended)

Packages are distributed via a dedicated DNF repository hosted on GitHub Pages:

👉 https://fedorabee.github.io/podman-ai-stack/

### 1. Add the Repository

```bash
sudo tee /etc/yum.repos.d/podman-ai-stack.repo <<'EOF'
[podman-ai-stack]
name=Podman Ai Stack - Release Server
baseurl=https://fedorabee.github.io/podman-ai-stack/
enabled=1
gpgcheck=1
gpgkey=https://github.com/fedoraBee.gpg
EOF
```

### 2. Update Cache

```bash
sudo dnf makecache
```

---

## 🚀 Installation Options

The stack is split into a base package and deployment-specific subpackages.
**By default, only the Open WebUI service is started.**

---

### Option 1: Rootless (Current User)

Ideal for personal workstations.

```bash
sudo dnf install podman-ai-stack
systemctl --user daemon-reload
systemctl --user start podman-ai-stack-pod
```

Monitor some logs (example for Open WebUI):

```bash
journalctl --user -u open-webui.service -f
```

---

### Option 2: Rootless (Dedicated System User)

Recommended for server-like deployments.

```bash
sudo dnf install podman-ai-stack-user
sudo -u podman-ai systemctl --user start podman-ai-stack-pod
```

> ℹ️ Lingering is enabled automatically by the package.

Monitor some logs (example for Ollama):

```bash
sudo -u podman-ai XDG_RUNTIME_DIR=/run/user/$(id -u podman-ai) \
  journalctl --user -u ollama.service -f
```

---

### Option 3: Rootfull (System-wide)

```bash
sudo dnf install podman-ai-stack-root
sudo systemctl start podman-ai-stack-pod
```

Monitor some logs (example for Podman AI Stack):

```bash
sudo journalctl -u podman-ai-stack-pod.service -f
```

---

## 🤖 Using Ollama

The stack includes an optional Ollama service.

By default, Open WebUI connects to:

```
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

---

### External Ollama

Set:

```
OLLAMA_BASE_URL=<your-server>
```

See [Configuration](#configuration).

---

## ⚙️ Configuration

### Runtime Configuration (Environment)

Configuration files are loaded in order:

1. `/etc/sysconfig/podman-ai-stack`
2. `~/.config/podman-ai-stack.env`

Common options:

* `OLLAMA_BASE_URL`
* `OLLAMA_HOST`

---

### Build-time Configuration

Certain parameters (ports, limits, image versions) are defined at build time.

See: `DEVELOPMENT.md`

---

## 🧩 Advanced Customization (Quadlet Overrides)

You can override any component using user-level Quadlets:

```
~/.config/containers/systemd/
```

These override system templates in:

```
/etc/containers/systemd/users/
```

---

### Example: Customize Open WebUI

```bash
mkdir -p ~/.config/containers/systemd/
cp /etc/containers/systemd/users/open-webui.container \
   ~/.config/containers/systemd/
```

Then:

```bash
systemctl --user daemon-reload
systemctl --user restart open-webui
```

---

### Disable Dedicated Network

Edit:

```
~/.config/containers/systemd/podman-ai-stack.pod
```

```ini
[Pod]
# Network=podman-ai-stack.network
```

Then:

```bash
systemctl --user daemon-reload
systemctl --user restart podman-ai-stack-pod
```

---

## 🔄 Restart Services

```bash
# Rootless
systemctl --user restart podman-ai-stack-pod

# Dedicated user
sudo -u podman-ai systemctl --user restart podman-ai-stack-pod

# Rootfull
sudo systemctl restart podman-ai-stack-pod
```

---

## 🔗 Resources

* 🌐 DNF Repository: https://fedorabee.github.io/podman-ai-stack/
* 📦 Repo Source (gh-pages): https://github.com/fedoraBee/podman-ai-stack/tree/gh-pages
* 💻 Development: https://github.com/fedoraBee/podman-ai-stack

---

## ⚠️ Disclaimer

This is an independent project and not affiliated with Fedora.

Use in production environments at your own discretion.

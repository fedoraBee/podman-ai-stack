# Podman AI Stack Repository

This repository hosts the official RPM packages for the **Podman AI Stack**.

The Podman AI Stack provides a secure, systemd-native way to run AI services like Open WebUI and Ollama using Podman Quadlets.

---

## 📦 Repository Setup

To install packages from this repository, create the following file:

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

Then update your package cache:

```bash
sudo dnf makecache
```

---

## 🔐 GPG Key

Packages in this repository are signed. During the first installation, DNF will prompt you to import the GPG key.

Fingerprint (recommended to verify manually):

```
8D12 D614 9E1E 5E83 29DD E6FD 9B99 A03F 6577 BF59
```

---

## 🚀 Installation

### Rootless (Current User)

```bash
sudo dnf install podman-ai-stack
systemctl --user daemon-reload
systemctl --user start podman-ai-stack-pod
```

---

### Rootless (Dedicated User)

```bash
sudo dnf install podman-ai-stack-user
sudo -u podman-ai systemctl --user start podman-ai-stack-pod
```

> Lingering is enabled automatically by the package.

---

### Rootfull (System Service)

```bash
sudo dnf install podman-ai-stack-root
sudo systemctl start podman-ai-stack-pod
```

---

## 📁 What This Repository Contains

* RPM packages for:

  * `podman-ai-stack`
  * `podman-ai-stack-user`
  * `podman-ai-stack-root`
* Repository metadata (`repodata/`)
* GPG signing key

---

## 🔗 Project Source & Documentation

For full documentation, configuration options, and development details, see:

👉 [https://github.com/fedoraBee/podman-ai-stack](https://github.com/fedoraBee/podman-ai-stack)

---

## 🛠️ Notes

* This repository is intended for **end users installing via DNF**
* Development files and source code are located in the main project repository
* Packages are built for Fedora and compatible RPM-based distributions

---

## ⚠️ Disclaimer

This is a personal project and not an official Fedora repository.

Use in production environments at your own discretion.

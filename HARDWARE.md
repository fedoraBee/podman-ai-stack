# Hardware Requirements & Resource Management

AI workloads are highly resource-constrained. This document outlines the
expected hardware sizing for running models via Ollama and how to dynamically
manage container resources without modifying the managed Quadlet templates.

## Hardware Sizing Guide

Local LLM inference relies heavily on GPU VRAM (Video RAM). System RAM is used
as a fallback but is significantly slower. These estimates assume standard 4-bit
quantization (which Ollama uses by default for most models).

| Model Size | Example Models | Minimum VRAM | Recommended System RAM |
| :--- | :--- | :--- | :--- |
| **7B - 8B** | Llama 3 8B, Mistral 7B | 6 GB - 8 GB | 16 GB |
| **13B - 14B** | Qwen 14B | 10 GB - 12 GB | 32 GB |
| **33B - 34B** | Command R | 20 GB - 24 GB | 64 GB |
| **70B+** | Llama 3 70B, Qwen 72B | 40 GB - 48 GB+ | 128 GB |

## Dynamic Resource Constraints

The Podman AI Stack ships with safe, hardcoded defaults defined at build time
(e.g., `OLLAMA_MEMORY=16G`, `OLLAMA_CPUS=4`). However, you should tune these
limits to fully utilize your specific hardware.

**Do not edit the Quadlet files directly** (e.g.,
`/etc/containers/systemd/users/ollama.container`), as they will be overwritten
during the next RPM update. Instead, use systemd drop-in files.

### Modifying Ollama Resources

To allocate more memory or CPUs to Ollama, create a drop-in file using the
systemctl edit command:

```bash
# For Rootless (User) deployment:
systemctl --user edit ollama

# For Rootfull deployment:
sudo systemctl edit ollama
```

This will open your default text editor. Add the following lines to override the
`PodmanArgs` directive in the `[Container]` section:

```ini
[Container]
# You must clear the existing PodmanArgs list first
PodmanArgs=
# Define your new resource limits
PodmanArgs=--memory=32G --cpus=8
```

Save the file and exit the editor. Then, reload the daemon and restart the pod:

```bash
systemctl --user daemon-reload
systemctl --user restart podman-ai-stack-pod
```

# Security Policy

## Supported Versions

The following table outlines which versions of the **podman-ai-stack** project
are currently receiving security updates.

| Version | Supported          |
| ------- | ------------------ |
| 0.4.x   | :white_check_mark: |
| 0.3.x   | :white_check_mark: |
| < 0.3.0 | :x:                |

## Reporting a Vulnerability

We take the security of this project seriously. To protect the systems of our
users (including those running `hybrid-btrfs-safe` configurations), please **do
not report vulnerabilities via public issues, social media, or public email.**

### How to Report

Please use the **GitHub Private Vulnerability Reporting** feature:

1. Navigate to the
   [Security Tab](https://github.com/fedoraBee/podman-ai-stack/security) of this
   repository.
2. Click on **Advisories** in the left sidebar.
3. Click **Report a vulnerability** to open a private draft advisory.

### Reporting Format

To help us investigate quickly, please follow the structure in our
[Security Advisory Template](https://github.com/fedoraBee/podman-ai-stack/blob/main/.github/SECURITY_ADVISORY_TEMPLATE.md).
Specifically, include:

* **Impact:** Technical description of the risk.
* **Environment:** Details from your `.version_manifest`.
* **Proof of Concept:** Steps to reproduce the issue privately.

### What to Expect

* **Acknowledgement:** You can expect a response within **48 hours** confirming
  receipt of your report.
* **Updates:** We provide progress updates at least once a week during
  investigation and patching.
* **Disclosure:** Once a fix is ready, we will coordinate with you to publish a
  Security Advisory and credit your contribution via the **MT-Tools** disclosure
  process.

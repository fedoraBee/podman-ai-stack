# Development Notes

## Building the RPM

To build the RPM package:

```bash
make rpm
```

This generates the following packages in `rpmbuild/RPMS/noarch/`:

- `podman-ai-stack`: Core configuration.
- `podman-ai-stack-user`: Rootless deployment.
- `podman-ai-stack-root`: Rootfull deployment.

## GPG Signing

To sign the built RPMs, you need a GPG key. If you have configured your
`~/.rpmmacros` (as shown below), you can simply run:

```bash
make sign
```

Alternatively, you can provide the key ID directly:

```bash
make sign GPG_KEY_ID=YOUR_KEY_ID
```

### RPM GPG Configuration

You should have the following in your `~/.rpmmacros`:

```rpmMacros
%_gpg_name YOUR_KEY_ID
%_gpg_path /home/youruser/.gnupg
%__gpg /usr/bin/gpg
```

## DNF Repository Management

The project uses `createrepo_c` to maintain a DNF repository with support for
versioned channels (e.g., `v0.1/stable`, `latest/testing`).

To update the repository metadata:

```bash
make repo CHANNEL=testing GPG_KEY_ID=YOUR_KEY_ID
```

This will:

1. Organize RPMs into `rpmbuild/repo/v<MAJOR>.<MINOR>/<CHANNEL>/`.
2. Run `createrepo_c --update` on that directory.
3. Generate a signed `repomd.xml.asc` if a GPG key is provided.
4. Sync the content to `rpmbuild/repo/latest/<CHANNEL>/`.

### Hosting on GitHub

To host this as a DNF repository on GitHub:

1. The repository structure in `rpmbuild/repo` is automatically deployed to the
   `gh-pages` branch by the CI workflow on each tag release.
2. Users can then add the repository by creating a `.repo` file pointing to the
   raw GitHub Pages URL.

## Releasing a New Version

The deployment to the public DNF repository is automated via GitHub Actions.

1. **Tag the release:** When you are ready to publish, create a new semantic
   version tag:

   ```bash
       git tag -a v0.1.0 -m "Release version 0.1.0"
   ```

2. **Push the tag:**

   ```bash
   git push origin v0.1.0
   ```

### Workflow Behavior

- **Push to `main`**: Does **not** trigger a deployment. Use this for ongoing
  development.
- **Push a `v*` tag**: Triggers the `release.yml` workflow.
  - Builds and signs the RPMs.
  - Organizes the DNF repository structure.
  - Deploys the result to the `gh-pages` branch.
  - Creates a GitHub Release with the RPMs as assets.

> ℹ️ **Note on Channels:** Tags containing `rc`, `beta`, `alpha`, or `test`
> (e.g., `v0.1.0-rc1`) are automatically deployed to the **testing** channel.
> All other tags are deployed to **stable**.

## Customizing at Build Time

You can override variables during the RPM build:

```bash
rpmbuild -ba rpm/podman-ai-stack.spec --define "OPEN_WEBUI_PORT 8080"
```

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

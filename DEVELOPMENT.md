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
To sign the built RPMs, you need a GPG key. Ensure your `~/.rpmmacros` is configured or provide the key ID to make:

```bash
make sign GPG_KEY_ID=YOUR_KEY_ID
```

### RPM GPG Configuration
You should have the following in your `~/.rpmmacros`:
```
%_gpg_name YOUR_KEY_ID
%_gpg_path /home/youruser/.gnupg
%__gpg /usr/bin/gpg
```

## DNF Repository Management
The project uses `createrepo_c` to maintain a DNF repository with support for versioned channels (e.g., `v0.1/stable`, `latest/testing`).

To update the repository metadata:
```bash
make repo CHANNEL=testing GPG_KEY_ID=YOUR_KEY_ID
```

This will:
1.  Organize RPMs into `rpmbuild/repo/v<MAJOR>.<MINOR>/<CHANNEL>/`.
2.  Run `createrepo_c --update` on that directory.
3.  Generate a signed `repomd.xml.asc` if a GPG key is provided.
4.  Sync the content to `rpmbuild/repo/latest/<CHANNEL>/`.

### Hosting on GitHub
To host this as a DNF repository on GitHub:
1.  The repository structure in `rpmbuild/repo` is automatically deployed to the `gh-pages` branch by the CI workflow on each tag release.
2.  Users can then add the repository by creating a `.repo` file pointing to the raw GitHub Pages URL.

## Customizing at Build Time
You can override variables during the RPM build:
```bash
rpmbuild -ba rpm/podman-ai-stack.spec --define "OPEN_WEBUI_PORT 8080"
```

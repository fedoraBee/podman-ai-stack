# Development Notes

## Building the RPM
To build the RPM package:
```bash
make rpm
```
This generates the following packages in `rpms/noarch/`:
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
The project uses `createrepo_c` to maintain a DNF repository. To update the repository metadata:

```bash
make repo GPG_KEY_ID=YOUR_KEY_ID
```

This will:
1. Run `createrepo_c --update` on the `rpms/noarch` directory.
2. Generate a signed `repomd.xml.asc` if a GPG key is provided.

### Hosting on GitHub
To host this as a DNF repository on GitHub:
1. Push the `rpms/` directory to a specific branch (e.g., `gh-pages`) or include it in a release.
2. Users can then add the repository by creating a `.repo` file pointing to the raw GitHub content URL.

## Customizing at Build Time
You can override variables during the RPM build:
```bash
rpmbuild -ba rpm/podman-ai-stack.spec --define "OPEN_WEBUI_PORT 8080"
```

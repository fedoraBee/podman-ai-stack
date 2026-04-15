Name:           podman-ai-stack
Version:        0.2.11
Release:        1%{?dist}
Summary:        Rootless Podman AI Stack (Open WebUI & Ollama)

# rpmlint filters for expected warnings/errors
# The 'podman-ai' user is a system user, but rpmlint can flag it as non-standard.
# It's intentional and safe in this context.

License:        MIT
URL:            https://github.com/fedoraBee/podman-ai-stack
Source0:        https://github.com/fedoraBee/%{name}/archive/v%{version}/%{name}-%{version}.tar.gz

BuildArch:      noarch
BuildRequires:  make
BuildRequires:  systemd-rpm-macros
Requires:       podman >= 4.6.0
Requires:       systemd

%description
Provides a rootless Podman AI Stack using Quadlets. By default, this 
package installs Quadlets that any user can run via the system 
control command (user mode). Configuration is managed via 
/etc/sysconfig/podman-ai-stack.

%package user
Summary:        Dedicated service user for Podman AI Stack
Requires:       %{name} = %{version}-%{release}
Requires(pre):  shadow-utils
Provides:       user(podman-ai)
Provides:       group(podman-ai)

%description user
Creates a dedicated 'podman-ai' user and enables lingering. This allows
the stack to run as a persistent rootless service without an active login.

%package root
Summary:        Root-full deployment for Podman AI Stack
Requires:       %{name} = %{version}-%{release}

%description root
Installs system-wide Quadlets to run the Podman AI Stack as a 
standard root-full system service.

%prep
%autosetup

%build
# No compilation needed

%install
%define make_vars \
    PREFIX=%{_prefix} \
    SYSCONFDIR=%{_sysconfdir} \
    OPEN_WEBUI_PORT=%{?OPEN_WEBUI_PORT}%{!?OPEN_WEBUI_PORT:3000} \
    OPEN_WEBUI_IMAGE=%{?OPEN_WEBUI_IMAGE}%{!?OPEN_WEBUI_IMAGE:ghcr.io/open-webui/open-webui:main} \
    OLLAMA_IMAGE=%{?OLLAMA_IMAGE}%{!?OLLAMA_IMAGE:docker.io/ollama/ollama:latest} \
    OLLAMA_MEMORY=%{?OLLAMA_MEMORY}%{!?OLLAMA_MEMORY:16G} \
    OLLAMA_CPUS=%{?OLLAMA_CPUS}%{!?OLLAMA_CPUS:4}

# Install everything into buildroot
make install-base DESTDIR=%{buildroot} %{make_vars}
make install-user DESTDIR=%{buildroot} %{make_vars}
make install-root DESTDIR=%{buildroot} %{make_vars}

%check
# Basic verification of installed files in BuildRoot
test -f %{buildroot}%{_sysconfdir}/sysconfig/podman-ai-stack
test -d %{buildroot}/var/lib/podman-ai

%global systemd_runtime_check [ -d /run/systemd/system ] && command -v systemctl >/dev/null 2>&1
%global loginctl_runtime_check [ -d /run/systemd/system ] && command -v loginctl >/dev/null 2>&1

%post
# Reload for the generator to pick up new user-level Quadlets
if %{systemd_runtime_check}; then
    systemctl daemon-reload >/dev/null 2>&1 || :
fi

%postun
if %{systemd_runtime_check}; then
    systemctl daemon-reload >/dev/null 2>&1 || :
fi

%preun
# Stop user-level services for all active users who might be running the stack
# This is a best-effort cleanup for rootless deployments
if [ $1 -eq 0 ] && %{loginctl_runtime_check}; then
    for user_info in $(loginctl list-users --no-legend | awk '{print $1":"$2}'); do
        uid=$(echo $user_info | cut -d: -f1)
        user=$(echo $user_info | cut -d: -f2)
        if [ -d "/run/user/$uid" ]; then
            # Check if the service is loaded before trying to stop it
            if runuser -u "$user" -- env XDG_RUNTIME_DIR="/run/user/$uid" systemctl --user list-units --all | grep -q "podman-ai-stack-pod.service"; then
                runuser -u "$user" -- env XDG_RUNTIME_DIR="/run/user/$uid" systemctl --user stop podman-ai-stack-pod.service || :
            fi
        fi
    done
fi

%pre user
getent group podman-ai >/dev/null || groupadd -r podman-ai
getent passwd podman-ai >/dev/null || \
    useradd -r -g podman-ai -d /var/lib/podman-ai -s /sbin/nologin \
    -c "Podman AI Stack User" podman-ai
exit 0

%post user
if %{loginctl_runtime_check}; then
    loginctl enable-linger podman-ai >/dev/null 2>&1 || :
fi

%postun user
if [ $1 -eq 0 ] && %{loginctl_runtime_check}; then
    loginctl disable-linger podman-ai >/dev/null 2>&1 || :
fi

%post root
if %{systemd_runtime_check}; then
    systemctl daemon-reload >/dev/null 2>&1 || :
    %systemd_post podman-ai-stack-pod
fi

%preun root
if %{systemd_runtime_check}; then
    %systemd_preun podman-ai-stack-pod
fi

%postun root
if %{systemd_runtime_check}; then
    %systemd_postun_with_restart podman-ai-stack-pod
    systemctl daemon-reload >/dev/null 2>&1 || :
fi

%files
%license LICENSE
%doc README.md DEVELOPMENT.md
%config(noreplace) %{_sysconfdir}/sysconfig/podman-ai-stack
%config(noreplace) %{_sysconfdir}/containers/systemd/users/*.container
%config(noreplace) %{_sysconfdir}/containers/systemd/users/*.volume
%config(noreplace) %{_sysconfdir}/containers/systemd/users/*.network
%config(noreplace) %{_sysconfdir}/containers/systemd/users/*.pod

%files user
%license LICENSE
%doc %{_docdir}/%{name}/README.md
%dir %attr(0755, podman-ai, podman-ai) /var/lib/podman-ai

%files root
%license LICENSE
%doc %{_docdir}/%{name}/README.md
%config(noreplace) %{_sysconfdir}/containers/systemd/*.container
%config(noreplace) %{_sysconfdir}/containers/systemd/*.volume
%config(noreplace) %{_sysconfdir}/containers/systemd/*.network
%config(noreplace) %{_sysconfdir}/containers/systemd/*.pod

%changelog
* Wed Apr 15 2026 fedoraBee <9395414+fedoraBee@users.noreply.github.com> - 0.2.11-1
- Configured GitHub Pages deployment to keep existing branch contents so
  prerelease publishes do not remove previously published repository channels
  such as latest/stable
- Preserved multi-channel DNF repository layouts when publishing only a subset
  of paths from rpmbuild/repo during release automation
- Aligned project version references to 0.2.11 across the Makefile, RPM spec,
  and changelog entries

* Wed Apr 15 2026 fedoraBee <9395414+fedoraBee@users.noreply.github.com> - 0.2.10-1
- Replaced the smoke-test download-artifact action with a direct GitHub Actions
  artifact API download to remove the final Node.js 20 deprecation warning in
  push CI runs
- Added actions read permission and passed the uploaded RPM artifact ID between
  CI jobs for API-based artifact retrieval
- Aligned project version references to 0.2.10 across the Makefile, RPM spec,
  and changelog entries

* Wed Apr 15 2026 fedoraBee <9395414+fedoraBee@users.noreply.github.com> - 0.2.9-1
- Scoped the Node.js 24 override to the smoke-test job so download-artifact can
  run without deprecation warnings while the rest of CI stays on native
  Node.js 24-compatible action versions
- Kept the workaround limited to the job that still depends on a Node.js 20
  targeted artifact download action
- Aligned project version references to 0.2.9 across the Makefile, RPM spec,
  and changelog entries

* Wed Apr 15 2026 fedoraBee <9395414+fedoraBee@users.noreply.github.com> - 0.2.8-1
- Updated CI workflow actions to Node.js 24-compatible releases and removed
  the forced Node.js 24 override from push and pull request jobs
- Updated checkout and artifact actions in the release workflow while keeping
  the temporary Node.js 24 override for the GitHub Pages deploy action
- Aligned project version references to 0.2.8 across the Makefile, RPM spec,
  and changelog entries

* Wed Apr 15 2026 fedoraBee <9395414+fedoraBee@users.noreply.github.com> - 0.2.7-1
- Opted GitHub Actions workflows into Node.js 24 to remove deprecation
  warnings for JavaScript-based actions on GitHub runners
- Applied the Node.js 24 runtime setting to both CI and release workflows for
  consistent behavior across automation jobs
- Aligned project version references to 0.2.7 across the Makefile, RPM spec,
  and changelog entries

* Wed Apr 15 2026 fedoraBee <9395414+fedoraBee@users.noreply.github.com> - 0.2.6-1
- Guarded systemctl and loginctl RPM scriptlets so installs succeed in CI
  containers without systemd running as PID 1
- Wrapped root subpackage systemd macros with the same runtime checks to avoid
  transaction failures during smoke-test installs
- Aligned project version references to 0.2.6 across the Makefile, RPM spec,
  and changelog entries

* Wed Apr 15 2026 fedoraBee <9395414+fedoraBee@users.noreply.github.com> - 0.2.5-1
- Added user(podman-ai) and group(podman-ai) provides to the user subpackage
  so DNF can resolve the dedicated service account during smoke-test installs
- Aligned project version references to 0.2.5 across the Makefile, RPM spec,
  and changelog entries

* Wed Apr 15 2026 fedoraBee <9395414+fedoraBee@users.noreply.github.com> - 0.2.4-1
- Fixed dnf install command in CI workflow to avoid broken dependency CI issue
- Aligned project version references to 0.2.4 across the Makefile, RPM spec,
  and changelog entries

* Wed Apr 15 2026 fedoraBee <9395414+fedoraBee@users.noreply.github.com> - 0.2.3-1
- Added systemd-rpm-macros to CI and release workflow dependency installation
- Verified and aligned project version references to 0.2.3

* Wed Apr 15 2026 fedoraBee <9395414+fedoraBee@users.noreply.github.com> - 0.2.2-1
- Add rpmlint filters for non-standard uid/gid for podman-ai user
- Add %%doc to subpackages to resolve no-documentation warnings
- Fixed shellcheck SC2115 warning in scripts/update-repo.sh
- Updated CONTRIBUTING.md with shellcheck and markdownlint-cli installation instructions
- Switched markdownlint configuration to .jsonc and removed legacy YAML/JSON config files
- Updated CI markdown linting to use markdownlint-cli2-action with repository-wide Markdown globs
- Fixed markdown formatting issues in GitHub issue and pull request templates
- Bumped version to 0.2.2

* Wed Apr 15 2026 fedoraBee <9395414+fedoraBee@users.noreply.github.com> - 0.2.1-1
- Improved spec file compliance by adding %%check section and Documentation
- Fixed rpmlint warnings regarding documentation and escaped macros in changelog
- Added systemd-rpm-macros to BuildRequires
- Bumped version to 0.2.1

* Wed Apr 15 2026 fedoraBee <9395414+fedoraBee@users.noreply.github.com> - 0.2.0-1
- Implemented production-quality CI pipeline via GitHub Actions
- Added automated shell (shellcheck), markdown (markdownlint), and RPM (rpmlint) linting
- Added automated packaging verification and install smoke tests
- Refactored Makefile with new lint and verify-rpm targets
- Fixed RPM build errors related to directory ownership and tarball exclusion
- Improved spec file compliance with Fedora packaging standards

* Tue Apr 14 2026 fedoraBee <9395414+fedoraBee@users.noreply.github.com> - 0.1.0-5
- Attempted fix for GitHub workflow RPM signing by escaping positional parameters (%%%%{1} and %%%%{2}) in the %%__gpg_sign_cmd macro definition.
- Added CI-safe GPG settings (loopback mode, batch, no-tty) to GitHub Actions
- Added --pinentry-mode loopback to repository metadata signing for CI reliability
- Exported GPG_TTY in workflow to suppress terminal-related warnings

* Tue Apr 14 2026 fedoraBee <9395414+fedoraBee@users.noreply.github.com> - 0.1.0-4
- Added automatic signature cleanup (rpm --delsig) during signing to handle conflicts
- Refactored Makefile for better maintainability with RPM_DIR variable
- Enhanced update-repo.sh with dependency checks and professional practices

* Tue Apr 14 2026 fedoraBee <9395414+fedoraBee@users.noreply.github.com> - 0.1.0-3
- Improved GPG key discovery in Makefile and update-repo.sh to automatically use %%_gpg_name
- Made GPG_KEY_ID parameter optional for both RPM and repository metadata signing
- Refactored update-repo.sh for better maintainability and professional practices

* Tue Apr 14 2026 fedoraBee <9395414+fedoraBee@users.noreply.github.com> - 0.1.0-2
- Updated DNF repository structure to support versioned channels (vMAJOR.MINOR/channel)
- Modified update-repo.sh to automatically organize RPMs and sync latest pointers
- Updated GitHub Actions workflow to deploy the new repository structure
- Improved documentation for the new build and deployment process

* Sun Apr 12 2026 fedoraBee <9395414+fedoraBee@users.noreply.github.com> - 0.1.0-1
- Marked all Quadlet files as config(noreplace) to preserve user modifications
- Refined automated cleanup of user-level pods to use runuser and XDG_RUNTIME_DIR
- Added automated cleanup of user-level pods during uninstallation
- Initial release of the Podman AI Stack (0.1.0-1)
- Added optional user-specific configuration via ~/.config/podman-ai-stack.env
- Added support for optional built-in Ollama service
- Refactored Quadlet templates for improved rootless compatibility
- Documentation improvements for DNF repository and network configuration

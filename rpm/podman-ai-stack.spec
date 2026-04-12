Name:           podman-ai-stack
Version:        0.1.0
Release:        1%{?dist}
Summary:        Rootless Podman AI Stack (Open WebUI & Ollama)

License:        MIT
URL:            https://github.com/fedoraBee/podman-ai-stack
Source0:        %{name}-%{version}.tar.gz

BuildArch:      noarch
BuildRequires:  make
Requires:       podman >= 4.6.0
Requires:       systemd

%description
Provides a rootless Podman AI Stack using Quadlets. By default, this 
package installs Quadlets that any user can run via 'systemctl --user'.
Configuration is managed via /etc/sysconfig/podman-ai-stack.

%package user
Summary:        Dedicated service user for Podman AI Stack
Requires:       %{name} = %{version}-%{release}
Requires(pre):  shadow-utils

%description user
Creates a dedicated 'podman-ai' user and enables lingering. This allows
the stack to run as a persistent rootless service without an active login.

%package root
Summary:        Rootfull deployment for Podman AI Stack
Requires:       %{name} = %{version}-%{release}

%description root
Installs system-wide Quadlets to run the Podman AI Stack as a 
standard rootfull system service.

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

%post
# Reload for the generator to pick up new user-level Quadlets
systemctl daemon-reload

%postun
systemctl daemon-reload

%preun
# Stop user-level services for all active users who might be running the stack
# This is a best-effort cleanup for rootless deployments
if [ $1 -eq 0 ]; then
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
loginctl enable-linger podman-ai || :

%postun user
if [ $1 -eq 0 ]; then
    loginctl disable-linger podman-ai || :
fi

%post root
%systemd_post podman-ai-stack-pod
systemctl daemon-reload

%preun root
%systemd_preun podman-ai-stack-pod

%postun root
%systemd_postun_with_restart podman-ai-stack-pod
systemctl daemon-reload

%files
%license LICENSE
%doc README.md DEVELOPMENT.md
%config(noreplace) %{_sysconfdir}/sysconfig/podman-ai-stack
%config(noreplace) %{_sysconfdir}/containers/systemd/users/*.container
%config(noreplace) %{_sysconfdir}/containers/systemd/users/*.volume
%config(noreplace) %{_sysconfdir}/containers/systemd/users/*.network
%config(noreplace) %{_sysconfdir}/containers/systemd/users/*.pod

%files user
# This package only manages the user and lingering

%files root
%config(noreplace) %{_sysconfdir}/containers/systemd/*.container
%config(noreplace) %{_sysconfdir}/containers/systemd/*.volume
%config(noreplace) %{_sysconfdir}/containers/systemd/*.network
%config(noreplace) %{_sysconfdir}/containers/systemd/*.pod

%changelog
* Sun Apr 12 2026 fedoraBee <9395414+fedoraBee@users.noreply.github.com> - 0.1.0-1
- Marked all Quadlet files as config(noreplace) to preserve user modifications
- Refined automated cleanup of user-level pods to use runuser and XDG_RUNTIME_DIR
- Added automated cleanup of user-level pods during uninstallation
- Initial release of the Podman AI Stack (0.1.0-1)
- Added optional user-specific configuration via ~/.config/podman-ai-stack.env
- Added support for optional built-in Ollama service
- Refactored Quadlet templates for improved rootless compatibility
- Documentation improvements for DNF repository and network configuration

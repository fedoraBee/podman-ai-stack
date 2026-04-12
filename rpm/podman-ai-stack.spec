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
%systemd_post open-webui.service ollama.service
systemctl daemon-reload

%preun root
%systemd_preun open-webui.service ollama.service

%postun root
%systemd_postun_with_restart open-webui.service ollama.service
systemctl daemon-reload

%files
%license LICENSE
%doc README.md DEVELOPMENT.md
%config(noreplace) %{_sysconfdir}/sysconfig/podman-ai-stack
%{_datadir}/containers/systemd/users/*.container
%{_datadir}/containers/systemd/users/*.volume
%{_datadir}/containers/systemd/users/*.network
%{_datadir}/containers/systemd/users/*.pod

%files user
# This package only manages the user and lingering

%files root
%{_datadir}/containers/systemd/*.container
%{_datadir}/containers/systemd/*.volume
%{_datadir}/containers/systemd/*.network
%{_datadir}/containers/systemd/*.pod

%changelog
* Sat Apr 11 2026 fedoraBee <9395414+fedoraBee@users.noreply.github.com> - 0.1.0-1
- Moved rootless Quadlets to base package for easier manual use
- Refactored -user package to handle only provisioning

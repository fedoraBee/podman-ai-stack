%{!?_version: %define _version X.Y.Z}

Name:           podman-ai-stack
Version:        %{_version}
Release:        1%{?dist}
Summary:        Rootless Podman AI Stack (Open WebUI & Ollama)

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
Provides:       user(podman-ai) = %{version}-%{release}

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
test -f %{buildroot}%{_prefix}/lib/sysusers.d/podman-ai-stack.conf
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
# Fallback user creation for systems where sysusers.d might not be 
# processed early enough or supported (robustness for Fedora 41+)
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
    systemctl enable --now podman-auto-update.timer >/dev/null 2>&1 || :
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
%{_prefix}/lib/sysusers.d/podman-ai-stack.conf
%dir %attr(0755, podman-ai, podman-ai) /var/lib/podman-ai

%files root
%license LICENSE
%doc %{_docdir}/%{name}/README.md
%config(noreplace) %{_sysconfdir}/containers/systemd/*.container
%config(noreplace) %{_sysconfdir}/containers/systemd/*.volume
%config(noreplace) %{_sysconfdir}/containers/systemd/*.network
%config(noreplace) %{_sysconfdir}/containers/systemd/*.pod

%changelog
%include %{_topdir}/changelog
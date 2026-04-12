# Makefile for podman-ai-stack

NAME := podman-ai-stack
VERSION := 0.1.0
PREFIX ?= /usr
DATADIR ?= $(PREFIX)/share
SYSCONFDIR ?= /etc

# Quadlet directories
USER_QUADLET_DIR ?= $(DATADIR)/containers/systemd/users
SYSTEM_QUADLET_DIR ?= $(DATADIR)/containers/systemd

# Default configuration for substitution
OPEN_WEBUI_PORT ?= 3000
OPEN_WEBUI_IMAGE ?= ghcr.io/open-webui/open-webui:main
OLLAMA_IMAGE ?= docker.io/ollama/ollama:latest
OLLAMA_MEMORY ?= 16G
OLLAMA_CPUS ?= 4

SED_ARGS := -e 's|@OPEN_WEBUI_PORT@|$(OPEN_WEBUI_PORT)|g' \
           -e 's|@OPEN_WEBUI_IMAGE@|$(OPEN_WEBUI_IMAGE)|g' \
           -e 's|@OLLAMA_IMAGE@|$(OLLAMA_IMAGE)|g' \
           -e 's|@OLLAMA_MEMORY@|$(OLLAMA_MEMORY)|g' \
           -e 's|@OLLAMA_CPUS@|$(OLLAMA_CPUS)|g'

.PHONY: all install install-base install-user install-root clean rpm sign repo

all:
	@echo "Nothing to build. Use 'make install' or 'make rpm'."

install: install-base install-user

install-base:
	mkdir -p $(DESTDIR)$(SYSCONFDIR)/sysconfig
	install -p -m 644 podman-ai-stack.sysconfig $(DESTDIR)$(SYSCONFDIR)/sysconfig/podman-ai-stack

install-user:
	mkdir -p $(DESTDIR)$(USER_QUADLET_DIR)
	$(foreach f,$(wildcard quadlets/*.in),sed $(SED_ARGS) $(f) > $(DESTDIR)$(USER_QUADLET_DIR)/$(notdir $(basename $(f)));)

install-root:
	mkdir -p $(DESTDIR)$(SYSTEM_QUADLET_DIR)
	$(foreach f,$(wildcard quadlets/*.in),sed $(SED_ARGS) $(f) > $(DESTDIR)$(SYSTEM_QUADLET_DIR)/$(notdir $(basename $(f)));)

rpm:
	mkdir -p rpmbuild/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
	tar -czf rpmbuild/SOURCES/$(NAME)-$(VERSION).tar.gz --exclude=.git --transform 's|^|$(NAME)-$(VERSION)/|' *
	rpmbuild -ba rpm/$(NAME).spec --define "_topdir $(PWD)/rpmbuild"
	@echo "RPMs built in rpmbuild/RPMS/noarch/"

sign:
	@if [ -z "$(GPG_KEY_ID)" ]; then echo "GPG_KEY_ID is not set. Use: make sign GPG_KEY_ID=<your-key-id>"; exit 1; fi
	rpmsign --addsign rpmbuild/RPMS/noarch/*.rpm --define "_gpg_name $(GPG_KEY_ID)"

repo:
	./scripts/update-repo.sh rpmbuild/RPMS/noarch $(GPG_KEY_ID)

clean:
	rm -rf $(NAME)-$(VERSION).tar.gz rpmbuild/

# Makefile for podman-ai-stack

NAME := podman-ai-stack
VERSION := 0.4.10
BUILD_DIR := $(CURDIR)/rpmbuild
RPM_DIR := $(BUILD_DIR)/RPMS/noarch
PREFIX ?= /usr
SYSCONFDIR ?= /etc
DATADIR ?= $(SYSCONFDIR)

# Quadlet directories
SYSTEM_QUADLET_DIR ?= $(DATADIR)/containers/systemd
USER_QUADLET_DIR ?= $(SYSTEM_QUADLET_DIR)/users

# Default configuration for substitution
OPEN_WEBUI_PORT ?= 3000
OPEN_WEBUI_IMAGE ?= ghcr.io/open-webui/open-webui:main
OLLAMA_PORT ?= 11434
OLLAMA_IMAGE ?= docker.io/ollama/ollama:latest
OLLAMA_MEMORY ?= 16G
OLLAMA_CPUS ?= 4

SED_ARGS := -e 's|@OPEN_WEBUI_PORT@|$(OPEN_WEBUI_PORT)|g' \
           -e 's|@OPEN_WEBUI_IMAGE@|$(OPEN_WEBUI_IMAGE)|g' \
           -e 's|@OLLAMA_PORT@|$(OLLAMA_PORT)|g' \
           -e 's|@OLLAMA_IMAGE@|$(OLLAMA_IMAGE)|g' \
           -e 's|@OLLAMA_MEMORY@|$(OLLAMA_MEMORY)|g' \
           -e 's|@OLLAMA_CPUS@|$(OLLAMA_CPUS)|g'

.PHONY: all install install-base install-user install-root prep rpm rpm-build rpm-sign rpm-repo lint lint-shell lint-md lint-spec lint-rpm verify-rpm clean

all:
	@echo "Nothing to build. Use 'make install' or 'make rpm'."

prep:
	@echo "Preparing RPM build environment..."
	rm -rf $(RPM_DIR)/*.rpm
	mkdir -p $(BUILD_DIR)/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
	@echo "Generating RPM changelog..."
	$(CURDIR)/scripts/update-rpm-metadata.py --version $(VERSION) --spec $(CURDIR)/rpm/$(NAME).spec --changelog-in $(CURDIR)/CHANGELOG.md --changelog-out $(BUILD_DIR)/changelog

rpm: prep rpm-build

lint: lint-shell lint-md lint-spec

lint-shell:
	shellcheck $(CURDIR)/scripts/*.sh

lint-md:
	@if command -v markdownlint > /dev/null; then \
		markdownlint --config $(CURDIR)/rpm/.markdownlint.jsonc *.md .github/**/*.md; \
	else \
		echo "Warning: markdownlint not found. Skipping markdown lint."; \
	fi

lint-spec: prep
	@echo "%_topdir $(BUILD_DIR)" > $(BUILD_DIR)/.rpmmacros
	@echo "%_version $(VERSION)" >> $(BUILD_DIR)/.rpmmacros
	HOME=$(BUILD_DIR) rpmlint -v -r $(CURDIR)/rpm/podman-ai-stack.spec.rpmlintrc --ignore-unused-rpmlintrc $(CURDIR)/rpm/$(NAME).spec


lint-rpm:
	rpmlint -v -r $(CURDIR)/rpm/podman-ai-stack.rpm.rpmlintrc --ignore-unused-rpmlintrc $(RPM_DIR)/*.rpm

install: install-base install-user

install-base:
	mkdir -p $(DESTDIR)$(SYSCONFDIR)/sysconfig
	install -p -m 644 podman-ai-stack.sysconfig $(DESTDIR)$(SYSCONFDIR)/sysconfig/podman-ai-stack

install-user:
	mkdir -p $(DESTDIR)$(USER_QUADLET_DIR)
	mkdir -p $(DESTDIR)$(PREFIX)/lib/sysusers.d
	mkdir -p $(DESTDIR)/var/lib/podman-ai
	install -p -m 644 podman-ai-stack.sysusers.conf $(DESTDIR)$(PREFIX)/lib/sysusers.d/podman-ai-stack.conf
	$(foreach f,$(wildcard quadlets/*.in),sed $(SED_ARGS) $(f) > $(DESTDIR)$(USER_QUADLET_DIR)/$(notdir $(basename $(f)));)

install-root:
	mkdir -p $(DESTDIR)$(SYSTEM_QUADLET_DIR)
	$(foreach f,$(wildcard quadlets/*.in),sed $(SED_ARGS) $(f) > $(DESTDIR)$(SYSTEM_QUADLET_DIR)/$(notdir $(basename $(f)));)

rpm-build:
	@echo "Building RPM packages..."
	tar -czf $(BUILD_DIR)/SOURCES/$(NAME)-$(VERSION).tar.gz --exclude=.git --exclude=rpmbuild --transform 's|^|$(NAME)-$(VERSION)/|' .
	rpmbuild -ba $(CURDIR)/rpm/$(NAME).spec --define "_version $(VERSION)" --define "_topdir $(BUILD_DIR)"
	@echo "RPMs built in $(RPM_DIR)"

rpm-sign:
	@echo "Signing RPM packages..."
	@for f in $(RPM_DIR)/*.rpm; do \
		if [ -f "$$f" ]; then \
			echo "Signing $$f..."; \
			if [ -n "$(GPG_KEY_ID)" ]; then \
				rpmsign --addsign "$$f" --define "_gpg_name $(GPG_KEY_ID)" || { \
					echo "Conflict detected, removing old signature and re-signing..."; \
					rpmsign --delsign "$$f"; \
					rpmsign --addsign "$$f" --define "_gpg_name $(GPG_KEY_ID)"; \
				}; \
			elif [ -n "$$(rpm --eval '%{?_gpg_name}')" ]; then \
				rpmsign --addsign "$$f" || { \
					echo "Conflict detected, removing old signature and re-signing..."; \
					rpmsign --delsign "$$f"; \
					rpmsign --addsign "$$f"; \
				}; \
			else \
				echo "Error: GPG_KEY_ID is not set and %_gpg_name macro is not defined."; \
				echo "Use: make sign GPG_KEY_ID=<your-key-id> or configure ~/.rpmmacros"; \
				exit 1; \
			fi; \
		fi; \
	done

CHANNEL ?= $(or $(channel),stable)

rpm-repo:
	$(CURDIR)/scripts/update-repo.sh $(RPM_DIR) $(VERSION) $(CHANNEL) "$(GPG_KEY_ID)"

clean:
	rm -r $(BUILD_DIR)

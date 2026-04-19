# Podman AI Stack: Technical Manifest

The Podman AI Stack is a secure, configurable, and systemd-native orchestration
stack for deploying containerized AI environments (Open WebUI and Ollama). It
leverages Podman Quadlets to provide seamless integration with systemd,
supporting both rootless and rootful deployments on Fedora and other RPM-based
distributions.

## 🏗 Architectural Overview

The project is structured around a base RPM package with deployment-specific
subpackages:

### 1. Base Package (`podman-ai-stack`)

- **Shared Configuration**: Installs `/etc/sysconfig/podman-ai-stack` for
  container environment variables.
- **User-Level Quadlets**: Installs rootless Quadlet templates to
  `/usr/share/containers/systemd/users/`.
- **Manual Usage**: Allows any user to immediately run the stack via
  `systemctl --user start open-webui`.

### 2. User Subpackage (`podman-ai-stack-user`)

- **Provisioning**: Automates the creation of the dedicated `podman-ai` system
  user and group.
- **Persistence**: Enables systemd lingering for the `podman-ai` user, allowing
  services to start at boot without an active login.

### 3. Root Subpackage (`podman-ai-stack-root`)

- **System-Wide Deployment**: Installs system-level Quadlets to
  `/usr/share/containers/systemd/`.
- **System Services**: Automatically enables the generated `open-webui.service`
  and `ollama.service` as standard system services.

## 🛠 Project Standards

- **Quadlet Locations**:
  - Rootless (Global): `/usr/share/containers/systemd/users/`
  - Rootful (System): `/usr/share/containers/systemd/`
- **Variable Substitution**: Quadlet templates (`.in` files) use `@VARIABLE@`
  placeholders which are replaced during `make install` using `sed`.
- **Configuration Persistence**: The `/etc/sysconfig/podman-ai-stack` file is
  marked as `noreplace` to preserve user overrides during package updates.
- **Network Isolation**: Uses a dedicated bridge network
  (`podman-ai-stack.network`) for communication between containers.
- **Security**: Default deployments are rootless for maximum isolation and
  security.
- **Service Naming**: Services are managed via systemd using generated Quadlet
  units (e.g. `open-webui.service`, `ollama.service`, or
  `podman-ai-stack-pod.service` depending on setup).
- **Automated Changelog**: The RPM changelog is generated from `CHANGELOG.md`
  using `scripts/update-rpm-metadata.py` and included in the spec file via
  `%include %{_topdir}/changelog`.
- **Markdown Linting**: All changes to Markdown files (`.md`) must adhere to the
  project's Markdown linting rules, especially MD013 to prevent line length
  overflows.
- **Language Standard**: Always use English when editing any project files,
  including code, comments, and documentation.

## 🚀 Deployment Workflow

To deploy changes locally for testing:

1. **Build the RPM:** `make rpm`
2. **Generate Repo:** `make rpm-repo CHANNEL=testing`
3. **Update Local Repo:** `cp -r rpmbuild/repo/ ../dnf-repos/podman-ai-stack/`
4. **Install/Reinstall:**
   `sudo dnf reinstall -Cy ../dnf-repos/podman-ai-stack/latest/testing/*.rpm`
5. **Reload Systemd:** `systemctl daemon-reload --user`
6. **Restart Service:** `systemctl --user restart podman-ai-stack-pod`

## 🤖 CLI Guidelines

- **Self-Correction**  
  After modifying `AGENTS.md`, immediately re-read it to ensure the active
  context reflects the latest project guidelines.

- **Professionalism**  
  Maintain high engineering standards. Write clean, idiomatic code, communicate
  clearly, and verify all changes before completion.

- **Branching Strategy (Mandatory)**  
  All features, bug fixes, and other changes must be developed in a new branch.
  Never commit directly to `main`.

  Branch names must follow:

  `<type>/v<version>-<short-description>`

  Where:

  - `<type>`: feat | fix | chore | refactor | docs | ci
  - `<version>`: target release version

  Examples:

  - `feat/v0.2.0-add-ollama-healthcheck`
  - `fix/v0.2.1-dnf-repo-signing`
  - `chore/v0.2.0-ci-improvements`
  - `refactor/v0.2.0-quadlet-cleanup`

- **Pull Request Workflow (Mandatory)**  
  Each branch must open a descriptive Pull Request (PR).

  PR creation MUST be performed using the GitOps PR CLI tool provided in this
  repository (located at scripts/gitops-pr-cli-tool.sh).

  Manual PR creation via GitHub UI or `gh pr create` directly is discouraged and
  should only be used for emergency hotfixes.

  The GitOps PR CLI tool enforces:

  - Branch naming validation
  - Version extraction from branch name
  - CHANGELOG validation
  - RPM spec version validation
  - Makefile version validation
  - Commit-based PR body generation
  - CI alignment checks

  Required PR contents (automatically enforced by tool):

  - Clear summary of the change
  - Motivation and context
  - Target version
  - Testing and verification steps
  - Completed engineering and CI checklists

  PR titles MUST follow Conventional Commits.

  The `main` branch must remain stable, protected, and always deployable.

- **CI Requirements**  
  All Pull Requests must pass CI checks before merging. This includes:

  - markdownlint
  - shellcheck
  - rpmlint
  - RPM build and smoke tests

  All checklist items in the Pull Request template must be completed before
  merge.

- **GitOps Tooling Requirement (Mandatory)**  
  All contributors (including automation agents and AI systems) MUST use the
  repository-provided GitOps PR CLI tool for PR creation.

  This ensures:

  - Consistent release metadata
  - Version synchronization across RPM, changelog, and branches
  - CI-safe PR structure
  - Enforced repository conventions

  The tool is the single source of truth for PR creation workflow.

- **Atomic Commits**  
  Commit frequently with small, logical, atomic changes.

  Commits must:

  - Address a single concern
  - Be independently buildable and testable where possible
  - Not mix refactoring with functional changes

  Use clear and structured commit messages following Conventional Commits.

- **Testing**  
  Thoroughly test all changes before committing:

  - Build RPMs using `make rpm`
  - Generate repositories using `make repo`
  - Verify Quadlet deployment and systemd integration
  - Validate scripts and error handling

- **Surgical Updates**  
  When modifying Quadlet templates, preserve `@VARIABLE@` placeholders or update
  the substitution logic in the `Makefile` accordingly.

- **Verification**  
  After modifying the RPM spec or Makefile:

  - Verify file paths
  - Validate installation logic
  - Ensure resulting RPM behaves as expected

- **Documentation**  
  Keep documentation consistent and up to date:

  - Update `DEVELOPMENT.md` for build steps and prerequisites
  - Update `README.md` for installation and user-facing changes

  **Changelog (Mandatory)**

  For every feature, fix, or release:

  - Update `CHANGELOG.md` using the "Keep a Changelog" format.
  - The `CHANGELOG.md` is the **single source of truth** for release notes.
  - The RPM changelog is automatically generated from `CHANGELOG.md` during the
    build process.
  - Updates to files AGENTS.md should never be reflected in the changelog.

- **Versioning Discipline**  
  Any version bump (including patch releases) must be synchronized across:

  - `Makefile` (`VERSION` variable)
  - `rpm/podman-ai-stack.spec` (`Version` field - automatically updated by
    `scripts/update-rpm-metadata.py` from `Makefile`)
  - `CHANGELOG.md` (New version heading)

- **Script Requirements**  
  All scripts (pre/post/postun) must be:

  - Idempotent
  - Safe to re-run
  - Failure-tolerant with proper error handling

- **Definition of Done**  
  A change is considered complete only if:

  - Code is implemented and tested
  - CI passes successfully
  - Documentation is updated
  - `CHANGELOG.md` entries are added
  - Version numbers are synchronized across `Makefile`, `spec`, and
    `CHANGELOG.md`
  - A Pull Request is reviewed and merged

- **Best Practices**  
  Follow established standards:

  - Fedora RPM packaging guidelines
  - Podman Quadlet conventions
  - Ensure scripts are idempotent and failure-safe

## 📦 Reference Docs

- [README.md](README.md): Installation and usage guide.
- [CONTRIBUTING.md](CONTRIBUTING.md): Guidelines for contributors.
- [DEVELOPMENT.md](DEVELOPMENT.md): Build instructions and technical notes.
- [CHANGELOG.md](CHANGELOG.md): Record of notable changes and versions.
- [LICENSE](LICENSE): MIT License.

**Note:** All changes made to this instruction file must also be reflected in
`AGENTS.md`.

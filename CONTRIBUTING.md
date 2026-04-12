# Contributing to podman-ai-stack

Thank you for contributing! This project aims to provide a secure and flexible AI stack for Fedora and other RPM-based distributions using Podman Quadlets.

## 📜 Code of Conduct
By participating in this project, you agree to maintain a professional and respectful environment. Please report any issues or suggested improvements via GitHub Issues.

## 🛠 Development Workflow

### 1. Fork and Clone
Fork the repository and clone it to your local machine (Fedora or another RPM-based distribution is recommended).

### 2. Environment Setup
Ensure you have the necessary development tools installed:
```bash
sudo dnf install make rpm-build podman systemd-devel rpmlint
```

### 3. Project Structure & Standards
- **Quadlets**: Templates are stored in `quadlets/*.in`. Do not edit the generated `.container` files.
- **Variables**: Use `@VARIABLE_NAME@` placeholders in `.in` files. Update the `Makefile` and `rpm/podman-ai-stack.spec` if you add new variables.
- **Deployment**: We support Rootless (default/user) and Rootfull (system) deployment via subpackages.

### 4. Testing Your Changes
Before submitting a pull request, you should:
1.  **Build the RPM**:
    ```bash
    make rpm
    ```
2.  **Lint the Spec File**:
    ```bash
    rpmlint rpm/podman-ai-stack.spec
    ```
3.  **Local Install Test**:
    Test both rootless and rootfull installations if possible.
    ```bash
    # Test local installation of Quadlets
    make install DESTDIR=./test-install
    ```

### 5. Version Management & Changelog
- **RPM Spec**: Increment the `Release` number in `rpm/podman-ai-stack.spec`.
- **CHANGELOG.md**: Add a brief note under the current version.
- **RPM Changelog**: Add a matching entry to the `%changelog` section in the Spec file.

## 📬 Submitting a Pull Request
1. **Commit**: Use descriptive commit messages (e.g., `feat: add support for GPU acceleration in Ollama`).
2. **Push**: Push to your fork and submit a Pull Request to the `main` branch.
3. **Template**: Fill out the Pull Request template completely.

## ⚖️ License
By contributing, you agree that your contributions will be licensed under the **MIT** license, as specified in the `LICENSE` file.

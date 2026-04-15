# Please include the following information in the PR description

## Description

A clear and concise description of the changes you've made.

## Why is this change needed?

Explain the motivation behind this change.

## Engineering Checklist

- [ ] Modified Quadlet templates in `quadlets/*.in`.
- [ ] Updated `Makefile` for any new variable substitutions.
- [ ] Incremented RPM `Release` or `Version` in `rpm/podman-ai-stack.spec`.
- [ ] Updated `%changelog` in the Spec file.
- [ ] Tested rootless and/or rootfull installation paths.

## Testing Details

How did you test these changes? (e.g., `make rpm`, local install, or live
testing on Fedora)

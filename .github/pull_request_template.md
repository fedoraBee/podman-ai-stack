# Pull Request

## Description

Provide a clear and concise description of the changes.

## Why is this change needed?

Explain the motivation and context behind this change.

## Type of Change

- [ ] feat (new feature)
- [ ] fix (bug fix)
- [ ] chore (maintenance / tooling)
- [ ] refactor (code improvement without behavior change)
- [ ] docs (documentation only)
- [ ] ci (CI/CD related changes)

## Version Target

Target version for this change (required):

`vX.Y.Z`

## Engineering Checklist

- [ ] Changes are implemented in a dedicated branch (not `main`)
- [ ] Branch name follows `<type>/v<version>-<description>`
- [ ] PR title follows Conventional Commits
- [ ] Changes are atomic and scoped to a single concern

- [ ] Modified Quadlet templates in `quadlets/*.in` (if applicable)
- [ ] Updated `Makefile` for variable substitutions (if applicable)

- [ ] Incremented RPM `Release` or `Version` in `rpm/podman-ai-stack.spec`
- [ ] Updated `%changelog` in the spec file
- [ ] Updated `CHANGELOG.md`

- [ ] Verified file paths and installation logic
- [ ] Ensured scripts are idempotent and failure-safe

## CI Checklist

- [ ] markdownlint passes
- [ ] shellcheck passes
- [ ] rpmlint passes
- [ ] RPM builds successfully
- [ ] Smoke tests pass

## Testing Details

Describe how you tested the changes:

- [ ] `make rpm`
- [ ] `make repo`
- [ ] Local installation via DNF
- [ ] Rootless deployment tested
- [ ] Rootful deployment tested

Additional notes:

<!-- Add logs, commands, or screenshots if relevant -->

## Breaking Changes

- [ ] This change introduces a breaking change

If yes, describe impact and migration steps:

## Definition of Done

- [ ] Code implemented and tested
- [ ] CI passes successfully
- [ ] Documentation updated
- [ ] Changelog updated
- [ ] Ready for review and merge

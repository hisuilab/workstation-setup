# Tests and Git Hooks

The test and Git hook setup in this repository is optional. The dotfiles can be used without enabling the local pre-commit hook.

Use these checks if you want early feedback when changing shell configuration, Homebrew tools, or chezmoi-managed files. If you prefer a smaller setup with less maintenance, you can keep the bootstrap files and skip the tooling described here.

## Test Commands

### Dotfiles

```bash
bash tests/dotfiles.sh
```

This test applies the repository to a temporary home directory and verifies:

- expected chezmoi targets are generated
- repository-only files are not copied into the home directory
- Zsh, Git, JSON, and Brewfile configuration can be parsed

It does not modify your real home directory.

### Pointer Speed

```bash
bash tests/pointer-speed.sh
```

This test renders the pointer speed script for the current operating system and verifies its commands with mocked system tools. It does not change the pointer speed of the machine running the test.

The macOS and Ubuntu branches are both covered by the GitHub Actions operating-system matrix.

### Homebrew Tools

Check the CLI tools used by CI:

```bash
bash tests/brew-tools.sh verify-ci
```

Check every formula in the Brewfile for the current operating system:

```bash
bash tests/brew-tools.sh verify-all
```

These commands verify Homebrew installation state, command availability, shell paths, and environment variables.

### Shell Quality

```bash
bash tests/shell-quality.sh
```

This command checks shell scripts with:

- `shfmt` for formatting
- `shellcheck` for static analysis

It reports formatting differences but does not rewrite files.

To format the scripts manually:

```bash
shfmt -w -i 2 -ci tests/*.sh .githooks/*
```

## GitHub Actions

The workflow in `.github/workflows/ci.yml` runs on:

- pull requests
- pushes to `main`

It tests the repository on both Ubuntu and macOS. Homebrew dependencies are installed before the tests run.

## Pre-commit Hook

The hook in `.githooks/pre-commit` automatically formats and checks staged shell scripts before a commit.

Enable it once after cloning:

```bash
git config --local core.hooksPath .githooks
```

When enabled, the hook:

1. finds staged shell scripts
2. formats them with `shfmt`
3. checks them with `shellcheck`
4. stages the formatted result

The hook stops when a shell script is only partially staged, preventing unrelated working-tree changes from being included in the commit.

Check whether it is enabled:

```bash
git config --local --get core.hooksPath
```

Disable it:

```bash
git config --local --unset core.hooksPath
```

Skip it for one commit:

```bash
git commit --no-verify
```

Use `--no-verify` sparingly because GitHub Actions will still run the quality checks.

## Minimal Setup

You do not need to maintain the tests or hooks to use the dotfiles.

For a simpler personal setup:

- do not enable `core.hooksPath`
- run tests only before larger changes
- let GitHub Actions provide feedback after pushing

If you do not want testing infrastructure at all in a fork, you can remove:

```text
.github/workflows/ci.yml
.githooks/
tests/
```

You can also remove `shfmt` and `shellcheck` from the Brewfile. If you remove only part of the testing setup, update the workflow and test lists together so they do not reference deleted files or tools.

## Maintenance Notes

The tests intentionally list expected dotfiles and CI formulas explicitly. Update them when:

- adding or removing a chezmoi-managed file
- adding or removing a CLI formula used by CI
- changing shell environment variables checked during startup

For small personal changes that do not affect those areas, the tests usually require no maintenance.

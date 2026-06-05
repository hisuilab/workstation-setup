# Workstation Setup

[![MIT License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

---

![Workstation Setup thumbnail](assets/thumbnail.png)

---

## Overview

This repository provides a lightweight bootstrap flow for restoring a personal macOS workstation with minimal manual work.

It covers the initial setup from Homebrew installation and GitHub SSH access to dotfile restoration, Homebrew bundle installation, and daily service login.

## Table of Contents

- [Dependencies](#dependencies)
- [Create Your Repository](#create-your-repository)
- [Bootstrap Steps](#bootstrap-steps)
- [1. Install Homebrew](#1-install-homebrew)
- [2. Set Up GitHub SSH Access](#2-set-up-github-ssh-access)
- [3. Install chezmoi](#3-install-chezmoi)
- [4. Initialize Dotfiles](#4-initialize-dotfiles)
- [5. Apply the Brewfile](#5-apply-the-brewfile)
- [6. Set Zsh as the Default Shell on Linux](#6-set-zsh-as-the-default-shell-on-linux)
- [7. Install Essential Applications on Ubuntu](#7-install-essential-applications-on-ubuntu)
- [8. Sign in to Services](#8-sign-in-to-services)
- [Optional Quality Checks](#optional-quality-checks)

## Dependencies

This setup assumes the following tools are available or will be installed during bootstrap:

- [chezmoi](https://www.chezmoi.io/) — used to manage and apply dotfiles
- [sheldon](https://sheldon.cli.rs/) — used to manage shell plugins/extensions
- [Homebrew](https://brew.sh/) — used to install packages and apps on macOS and Linux

## Create Your Repository

> [!IMPORTANT]
> Click the green **Use this template** button at the top of this repository, then select **Create a new repository**.

1. Click **Use this template**
2. Select **Create a new repository**
3. Choose an owner and repository name
4. Create the repository

You can also open the creation page directly:

[**Create a repository from this template**](https://github.com/new?template_name=workstation-setup&template_owner=hisuilab)

Using a template creates a new repository without carrying over this repository's commit history. Before applying the dotfiles, review and customize:

- `dot_Brewfile` for the packages and applications you want
- `dot_config/private_karabiner/private_karabiner.json` for your keyboard
- editor and terminal settings under `dot_config/`
- macOS-specific and personal tools that may not apply to your environment

This repository is an opinionated starting point rather than a universal workstation configuration.

## Bootstrap Steps

```text
1. Homebrew
↓
2. GitHub SSH setup
↓
3. chezmoi installation
↓
4. Dotfiles initialization and restore
↓
5. Brewfile execution
↓
6. Linux default shell setup (Linux only)
↓
7. Linux application setup (Linux only)
↓
8. Service logins
```

On macOS, skip steps 6 and 7 and continue directly from step 5 to step 8.

---

## 1. Install Homebrew

### macOS

Install Homebrew with the official installer:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Add Homebrew to the Zsh environment on Apple Silicon:

```bash
grep -qxF 'eval "$(/opt/homebrew/bin/brew shellenv)"' ~/.zprofile 2>/dev/null \
  || echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"
```

On an Intel Mac, use `/usr/local/bin/brew` instead:

```bash
grep -qxF 'eval "$(/usr/local/bin/brew shellenv)"' ~/.zprofile 2>/dev/null \
  || echo 'eval "$(/usr/local/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/usr/local/bin/brew shellenv)"
```

Verify the installation:

```bash
brew --version
```

See the [official Homebrew installation guide for macOS](https://docs.brew.sh/Installation.html).

### Ubuntu / Linux

Install the required system packages:

```bash
sudo apt update
sudo apt install -y build-essential procps curl file git
```

Install Homebrew with the official installer:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Add Homebrew to the Bash environment:

```bash
grep -qxF 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' ~/.bashrc 2>/dev/null \
  || echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.bashrc
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
```

Verify the installation:

```bash
brew --version
```

See the [official Homebrew on Linux guide](https://docs.brew.sh/Homebrew-on-Linux).

---

## 2. Set Up GitHub SSH Access

### Create the SSH directory

```bash
mkdir -p ~/.ssh
chmod 700 ~/.ssh
```

### Generate an SSH key

```bash
ssh-keygen -t ed25519 -C "your_email@example.com" \
  -f ~/.ssh/github_ed25519
```

### Generated files

```text
~/.ssh/github_ed25519
~/.ssh/github_ed25519.pub
```

### Configure SSH

```bash
cat <<EOF > ~/.ssh/config
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/github_ed25519
    IdentitiesOnly yes
EOF
```

### Fix permissions

```bash
chmod 600 ~/.ssh/config
```

### Show the public key

```bash
cat ~/.ssh/github_ed25519.pub
```

Add the key in GitHub:

**Settings → SSH and GPG keys → New SSH key**

### Verify the connection

```bash
ssh -T git@github.com
```

---

## 3. Install chezmoi

```bash
brew install chezmoi
```

---

## 4. Initialize Dotfiles

Open the repository you created from the template on GitHub:

1. Select **Code**
2. Select the **SSH** tab
3. Copy the repository URL

Initialize chezmoi with the copied SSH URL:

```bash
chezmoi init git@github.com:<username>/<repository>.git
```

During the first initialization, enter your Git identity in the CLI:

```text
Git User Name:
Git Email:
```

The values are stored in chezmoi's local configuration and used to generate `~/.gitconfig`. You do not need to edit the template file manually.

To enter the values again on an existing setup:

```bash
chezmoi init --prompt
```

### Apply the dotfiles

Review the source files, then apply them:

```bash
chezmoi apply
```

### Verify Git configuration

```bash
git config --global --list
```

---

## 5. Apply the Brewfile

```bash
brew bundle --file ~/.Brewfile
```

---

## 6. Set Zsh as the Default Shell on Linux

> [!NOTE]
> Linux only. macOS users can skip this section and continue to step 8.

Switch the default shell from Bash to Zsh:

First, register the Homebrew Zsh binary:

```bash
BREW_ZSH="$(brew --prefix)/bin/zsh"
grep -qxF "$BREW_ZSH" /etc/shells || echo "$BREW_ZSH" | sudo tee -a /etc/shells
```

Set it as the default shell:

```bash
chsh -s "$BREW_ZSH"
```

Log out and sign in again, then verify:

```bash
echo "$SHELL"
zsh --version
brew --version
```

This step is not required on systems already using Zsh.

---

## 7. Install Essential Applications on Ubuntu

> [!NOTE]
> Ubuntu only. macOS users can skip this section and continue to step 8.

Homebrew Cask applications are skipped on Linux. Install these required applications separately on Ubuntu.

### Google Chrome

Download the Debian package from the official Google Chrome website:

[**Download Google Chrome**](https://www.google.com/chrome/)

Install the downloaded package:

```bash
sudo apt install ./google-chrome-stable_current_amd64.deb
```

### Tailscale

Run the official Linux installer:

```bash
curl -fsSL https://tailscale.com/install.sh | sh
```

Connect and authenticate:

```bash
sudo tailscale up
```

See the [official Tailscale Linux installation guide](https://tailscale.com/docs/install/linux).

### Visual Studio Code

Install the official Snap package:

```bash
sudo snap install --classic code
```

See the [official VS Code Linux installation guide](https://code.visualstudio.com/docs/setup/linux).

### Ghostty

Install the Snap package listed in the official Ghostty installation guide:

```bash
sudo snap install ghostty --classic
```

Ghostty does not currently provide an official Linux binary. Review the package notes in the [official Ghostty installation guide](https://ghostty.org/docs/install/binary).

### Verify

```bash
google-chrome --version
tailscale version
code --version
ghostty --version
```

---

## 8. Sign in to Services

Recommended login order:

1. Google Chrome
2. Tailscale
3. Google Drive
4. Slack
5. Discord
6. Zoom
7. Docker Desktop
8. GitHub CLI Auth

```bash
gh auth login
```

---

## Optional Quality Checks

This repository includes optional cross-platform tests, shell linting, formatting checks, and a local pre-commit hook.

They are useful when actively maintaining the dotfiles, but they are not required for using the workstation setup. See [Tests and Git Hooks](docs/testing-and-hooks.md) for setup, commands, maintenance notes, and instructions for disabling or removing them.

---

## Done

Your macOS environment should now be restored.

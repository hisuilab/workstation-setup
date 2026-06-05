# Workstation Setup

[![MIT License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

A lightweight bootstrap guide for restoring a personal macOS workstation quickly.

This repository is intended to help you rebuild a Mac from scratch with minimal manual work:

1. install the required base tools
2. set up GitHub SSH access
3. install and initialize `chezmoi`
4. restore dotfiles and shell/tooling configuration
5. install Homebrew packages and apps
6. sign in to the services you use daily

## Dependencies

This setup assumes the following tools are available or will be installed during bootstrap:

- [chezmoi](https://www.chezmoi.io/) — used to manage and apply dotfiles
- [sheldon](https://sheldon.cli.rs/) — used to manage shell plugins/extensions
- [Homebrew](https://brew.sh/) — used to install packages and apps on macOS

## Bootstrap Steps

```text
1. Homebrew
↓
2. GitHub SSH setup
↓
3. chezmoi installation
↓
4. Git identity configuration
↓
5. Dotfiles restore
↓
6. Brewfile execution
↓
7. Service logins
```

---

## 1. Install Homebrew

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### Apple Silicon

```bash
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"
```

### Verify

```bash
brew --version
```

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
    AddKeysToAgent yes
    UseKeychain yes
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

```bash
chezmoi init git@github.com:<username>/<dotfiles-repository>.git
```

### First apply

```bash
chezmoi apply
```

### Enter Git identity on first setup only

```text
Git User Name:
Git Email:
```

The values are stored in chezmoi's local configuration and can be reused the next time you rebuild the machine.

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

## 6. Sign in to Services

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

## Done

Your macOS environment should now be restored.

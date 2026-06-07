#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
brewfile="$repo_root/dot_Brewfile"

# ========================================
# Brewfile package parsing
# ========================================

extract_packages() {
  local target_os="${1:-current}"

  BREWFILE_TARGET_OS="$target_os" ruby - "$brewfile" <<'RUBY'
brewfile = ARGV.fetch(0)
target_os = ENV.fetch("BREWFILE_TARGET_OS")
host_is_mac = /darwin/ === RUBY_PLATFORM
host_is_linux = /linux/ === RUBY_PLATFORM
packages = []

module OS
end

OS.define_singleton_method(:mac?) do
  target_os == "mac" || (target_os == "current" && host_is_mac)
end

OS.define_singleton_method(:linux?) do
  target_os == "linux" || (target_os == "current" && host_is_linux)
end

define_method(:brew) do |name, *|
  packages << "brew:#{name}"
end

define_method(:cask) do |name, *|
  packages << "cask:#{name}"
end

define_method(:mas) do |*|
end

instance_eval(File.read(brewfile), brewfile)
puts packages
RUBY
}

extract_formulas() {
  extract_packages "${1:-current}" | sed -n 's/^brew://p'
}

# ========================================
# CI-safe formula set
# ========================================

ci_formulas=(
  chezmoi
  git
  gh
  zsh
  powerlevel10k
  zoxide
  zsh-autosuggestions
  zsh-completions
  zsh-syntax-highlighting
  wget
  curl
  jq
  eza
  fd
  ripgrep
  fzf
  bat
  unzip
  shfmt
  shellcheck
  nvm
  uv
)

# ========================================
# Shared helpers
# ========================================

require_brew() {
  if ! command -v brew >/dev/null 2>&1; then
    echo "Homebrew is required for this test." >&2
    exit 1
  fi
}

assert_declared_in_brewfile() {
  local formula
  local declared

  declared="$(extract_formulas)"

  for formula in "${ci_formulas[@]}"; do
    if ! grep -Fxq "$formula" <<<"$declared"; then
      echo "CI formula is not declared in Brewfile: $formula" >&2
      exit 1
    fi
  done
}

assert_platform_packages() {
  local mac_packages
  local linux_packages

  mac_packages="$(extract_packages mac)"
  linux_packages="$(extract_packages linux)"

  grep -Fxq "cask:docker-desktop" <<<"$mac_packages"
  grep -Fxq "brew:ollama" <<<"$mac_packages"

  if grep -Eq '^(brew:docker|brew:ollama|cask:docker-desktop)$' <<<"$linux_packages"; then
    echo "Docker and Ollama must use their official installation methods on Linux." >&2
    exit 1
  fi
}

# ========================================
# Installation
# ========================================

install_ci_formulas() {
  require_brew
  assert_declared_in_brewfile
  brew install "${ci_formulas[@]}"
}

# ========================================
# Formula checks
# ========================================

check_formula() {
  local formula="$1"
  local prefix
  prefix="$(brew --prefix)"

  brew list --formula "$formula" >/dev/null

  case "$formula" in
    bat)
      command -v bat >/dev/null
      ;;
    chezmoi)
      command -v chezmoi >/dev/null
      ;;
    curl)
      command -v curl >/dev/null
      ;;
    eza)
      command -v eza >/dev/null
      ;;
    fd)
      command -v fd >/dev/null
      ;;
    fzf)
      command -v fzf >/dev/null
      ;;
    gh)
      command -v gh >/dev/null
      ;;
    git)
      command -v git >/dev/null
      ;;
    jq)
      command -v jq >/dev/null
      ;;
    mas)
      command -v mas >/dev/null
      ;;
    nvm)
      test -f "$prefix/opt/nvm/nvm.sh"
      ;;
    ollama)
      command -v ollama >/dev/null
      ;;
    powerlevel10k)
      test -f "$prefix/share/powerlevel10k/powerlevel10k.zsh-theme"
      ;;
    ripgrep)
      command -v rg >/dev/null
      ;;
    shellcheck)
      command -v shellcheck >/dev/null
      ;;
    shfmt)
      command -v shfmt >/dev/null
      ;;
    tag)
      command -v tag >/dev/null
      ;;
    unzip)
      command -v unzip >/dev/null
      ;;
    uv)
      command -v uv >/dev/null
      ;;
    wget)
      command -v wget >/dev/null
      ;;
    zoxide)
      command -v zoxide >/dev/null
      ;;
    zsh)
      command -v zsh >/dev/null
      ;;
    zsh-autosuggestions)
      test -f "$prefix/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
      ;;
    zsh-completions)
      test -d "$prefix/share/zsh-completions"
      ;;
    zsh-syntax-highlighting)
      test -f "$prefix/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
      ;;
    *)
      echo "No installation check is defined for formula: $formula" >&2
      exit 1
      ;;
  esac
}

verify_formulas() {
  require_brew

  local formulas=("$@")
  local formula

  if [[ "${#formulas[@]}" -eq 0 ]]; then
    while IFS= read -r formula; do
      formulas+=("$formula")
    done < <(extract_formulas)
  fi

  for formula in "${formulas[@]}"; do
    check_formula "$formula"
  done
}

# ========================================
# Shell environment checks
# ========================================

verify_shell_environment() (
  require_brew

  local tmpdir
  local home_dir
  local cache_dir
  local state_file
  local zsh_binary

  tmpdir="$(mktemp -d)"
  trap 'rm -rf "$tmpdir"' EXIT

  home_dir="$tmpdir/home"
  cache_dir="$tmpdir/cache"
  state_file="$tmpdir/chezmoistate.boltdb"

  mkdir -p "$home_dir" "$cache_dir"
  zsh_binary="$(command -v zsh)"

  chezmoi apply \
    --source "$repo_root" \
    --destination "$home_dir" \
    --cache "$cache_dir" \
    --persistent-state "$state_file" \
    --exclude scripts \
    --force \
    --no-tty \
    --override-data '{"git":{"name":"CI User","email":"ci@example.com"}}'

  # shellcheck disable=SC2016
  HOME="$home_dir" PATH="/usr/bin:/bin" "$zsh_binary" -ic '
    [[ -n "$HOMEBREW_PREFIX" ]]
    [[ -d "$HOMEBREW_PREFIX" ]]
    [[ "$XDG_CONFIG_HOME" == "$HOME/.config" ]]
    [[ "$XDG_CACHE_HOME" == "$HOME/.cache" ]]
    [[ "$DEV_DIR" == "$HOME/Developments" ]]
    [[ ":$PATH:" == *":$HOME/.local/bin:"* ]]
    command -v brew >/dev/null
    command -v gh >/dev/null
    command -v rg >/dev/null
    command -v fd >/dev/null
    command -v uv >/dev/null
    type nvm >/dev/null
  '
)

# ========================================
# Command dispatch
# ========================================

case "${1:-verify-ci}" in
  install-ci)
    assert_platform_packages
    install_ci_formulas
    ;;
  verify-ci)
    assert_platform_packages
    assert_declared_in_brewfile
    verify_formulas "${ci_formulas[@]}"
    verify_shell_environment
    ;;
  verify-all)
    assert_platform_packages
    verify_formulas
    verify_shell_environment
    ;;
  *)
    echo "Usage: $0 [install-ci|verify-ci|verify-all]" >&2
    exit 1
    ;;
esac

#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# ========================================
# Test workspace
# ========================================

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

home_dir="$tmpdir/home"
cache_dir="$tmpdir/cache"
state_file="$tmpdir/chezmoistate.boltdb"

mkdir -p "$home_dir" "$cache_dir"

# ========================================
# Render dotfiles into a temporary HOME
# ========================================

chezmoi apply \
  --source "$repo_root" \
  --destination "$home_dir" \
  --cache "$cache_dir" \
  --persistent-state "$state_file" \
  --force \
  --no-tty \
  --override-data '{"git":{"name":"CI User","email":"ci@example.com"}}'

# ========================================
# Expected chezmoi targets
# ========================================

required_files=(
  "$home_dir/.Brewfile"
  "$home_dir/.config/ghostty/config"
  "$home_dir/.config/karabiner/karabiner.json"
  "$home_dir/.config/zed/settings.json"
  "$home_dir/.gitconfig"
  "$home_dir/.p10k.zsh"
  "$home_dir/.zshrc"
)

for file in "${required_files[@]}"; do
  test -f "$file"
done

# ========================================
# Repository-only files must stay ignored
# ========================================

unwanted_paths=(
  "$home_dir/.githooks"
  "$home_dir/docs"
  "$home_dir/README.md"
  "$home_dir/LICENSE"
  "$home_dir/assets"
  "$home_dir/tests"
)

for path in "${unwanted_paths[@]}"; do
  if [[ -e "$path" ]]; then
    echo "Unexpected chezmoi target: $path" >&2
    exit 1
  fi
done

# ========================================
# Syntax and format checks
# ========================================

zsh -n "$home_dir/.zshrc"
zsh -n "$home_dir/.p10k.zsh"

git config --file "$home_dir/.gitconfig" --list >/dev/null

find "$home_dir/.config" -name '*.json' -print0 | xargs -0 jq empty

ruby -c "$home_dir/.Brewfile" >/dev/null

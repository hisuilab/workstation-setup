#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
shell_scripts=(
  "$repo_root/tests/brew-tools.sh"
  "$repo_root/tests/dotfiles.sh"
  "$repo_root/tests/shell-quality.sh"
)

# ========================================
# Required tools
# ========================================

for tool in shfmt shellcheck; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "Required tool is not installed: $tool" >&2
    exit 1
  fi
done

# ========================================
# Formatting
# ========================================

shfmt -d -i 2 -ci "${shell_scripts[@]}"

# ========================================
# Linting
# ========================================

shellcheck "${shell_scripts[@]}"

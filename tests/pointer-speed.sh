#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
template="$repo_root/.chezmoiscripts/run_onchange_after_10-pointer-speed.sh.tmpl"

# ========================================
# Test workspace
# ========================================

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

mock_bin="$tmpdir/bin"
call_log="$tmpdir/calls.log"
expected_log="$tmpdir/expected.log"
rendered_script="$tmpdir/pointer-speed.sh"

mkdir -p "$mock_bin"
touch "$call_log"

# ========================================
# Render the script for the current OS
# ========================================

chezmoi execute-template <"$template" >"$rendered_script"
bash -n "$rendered_script"

# ========================================
# Verify platform-specific commands
# ========================================

case "$(uname -s)" in
  Darwin)
    cat >"$mock_bin/defaults" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$CALL_LOG"
EOF
    chmod +x "$mock_bin/defaults"

    cat >"$expected_log" <<'EOF'
write NSGlobalDomain com.apple.mouse.scaling -float 3.0
write NSGlobalDomain com.apple.trackpad.scaling -float 3.0
EOF
    ;;
  Linux)
    cat >"$mock_bin/gsettings" <<'EOF'
#!/usr/bin/env bash
if [[ "$1" == "list-schemas" ]]; then
  printf '%s\n' \
    org.gnome.desktop.peripherals.mouse \
    org.gnome.desktop.peripherals.touchpad
else
  printf '%s\n' "$*" >>"$CALL_LOG"
fi
EOF
    chmod +x "$mock_bin/gsettings"

    cat >"$expected_log" <<'EOF'
set org.gnome.desktop.peripherals.mouse speed 1.0
set org.gnome.desktop.peripherals.touchpad speed 1.0
EOF
    ;;
  *)
    echo "Unsupported test platform: $(uname -s)" >&2
    exit 1
    ;;
esac

CALL_LOG="$call_log" PATH="$mock_bin:$PATH" bash "$rendered_script"
diff -u "$expected_log" "$call_log"

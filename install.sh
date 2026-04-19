#!/usr/bin/env bash
# Installs the VS Code / Cursor extension half of claude-terminal-focus,
# and copies the hook scripts into ~/.claude/hooks/. Wiring those hooks
# into ~/.claude/settings.json (or installing via the marketplace plugin)
# is a separate step — see README.

set -euo pipefail

REPO_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
EXT_DIR="$REPO_DIR/vscode-extension"
HOOKS_SRC="$REPO_DIR/plugins/claude-terminal-focus/hooks"
HOOKS_DST="${CLAUDE_HOOKS_DIR:-$HOME/.claude/hooks}"

missing=()
command -v terminal-notifier >/dev/null 2>&1 || missing+=("terminal-notifier (brew install terminal-notifier)")
command -v jq >/dev/null 2>&1 || missing+=("jq (brew install jq)")
command -v npx >/dev/null 2>&1 || missing+=("npx (install Node.js)")

have_code=0
have_cursor=0
command -v code >/dev/null 2>&1 && have_code=1
command -v cursor >/dev/null 2>&1 && have_cursor=1

if [ "$have_code" -eq 0 ] && [ "$have_cursor" -eq 0 ]; then
  missing+=("code or cursor CLI on PATH (VS Code -> 'Shell Command: Install code command in PATH'; Cursor -> same under its menu)")
fi

if [ "${#missing[@]}" -gt 0 ]; then
  echo "Missing required commands:" >&2
  printf '  - %s\n' "${missing[@]}" >&2
  exit 1
fi

echo "Packaging VS Code extension..."
pushd "$EXT_DIR" >/dev/null
rm -f ./*.vsix
npx --yes @vscode/vsce@latest package --allow-missing-repository --skip-license >/dev/null
vsix_file=$(ls ./*.vsix | head -n1)
popd >/dev/null

if [ "$have_code" -eq 1 ]; then
  echo "Installing $(basename "$vsix_file") into VS Code..."
  code --install-extension "$EXT_DIR/$vsix_file" --force
fi

if [ "$have_cursor" -eq 1 ]; then
  echo "Installing $(basename "$vsix_file") into Cursor..."
  cursor --install-extension "$EXT_DIR/$vsix_file" --force
fi

echo "Installing hook scripts into $HOOKS_DST..."
mkdir -p "$HOOKS_DST"
for script in notify.sh focus-terminal-tab.sh focus-iterm2-tab.sh; do
  cp "$HOOKS_SRC/$script" "$HOOKS_DST/$script"
  chmod +x "$HOOKS_DST/$script"
done

echo
echo "Done. Next steps:"
echo "  1. Reload your editor window: Cmd+Shift+P -> 'Developer: Reload Window'"
echo "  2. If this is a fresh install, wire the hooks into Claude Code"
echo "     either via the marketplace plugin:"
echo "       /plugin marketplace add syymza/claude-terminal-focus"
echo "       /plugin install claude-terminal-focus@claude-terminal-focus"
echo "     or by adding Notification + Stop entries to ~/.claude/settings.json"
echo "     pointing at $HOOKS_DST/notify.sh."
echo "  3. Make sure terminal-notifier is allowed in"
echo "     System Settings -> Notifications."

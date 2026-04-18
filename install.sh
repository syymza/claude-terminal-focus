#!/usr/bin/env bash
# Installs the VS Code extension half of claude-terminal-focus.
# The Claude Code plugin (hooks) is activated separately via `/plugin install`.

set -euo pipefail

REPO_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
EXT_DIR="$REPO_DIR/vscode-extension"

missing=()
command -v terminal-notifier >/dev/null 2>&1 || missing+=("terminal-notifier (brew install terminal-notifier)")
command -v jq >/dev/null 2>&1 || missing+=("jq (brew install jq)")
command -v code >/dev/null 2>&1 || missing+=("code (VS Code 'Shell Command: Install code command in PATH')")
command -v npx >/dev/null 2>&1 || missing+=("npx (install Node.js)")

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

echo "Installing $(basename "$vsix_file") into VS Code..."
code --install-extension "$EXT_DIR/$vsix_file" --force

echo
echo "Done. Next steps:"
echo "  1. Reload your VS Code window: Cmd+Shift+P -> 'Developer: Reload Window'"
echo "  2. Enable the Claude Code plugin (if not already):"
echo "       /plugin install <this-repo-url>"
echo "     or clone and run: /plugin install $REPO_DIR"
echo "  3. Make sure terminal-notifier is allowed in"
echo "     System Settings -> Notifications."

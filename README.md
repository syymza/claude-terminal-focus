# claude-terminal-focus

Click a Claude Code macOS notification and jump straight back to the terminal tab the session is running in.

## What it does

Claude Code's `Notification` and `Stop` hooks fire a `terminal-notifier` banner whose click-action focuses the exact terminal where Claude is running:

| Terminal          | Click behaviour                                                              |
| ----------------- | ---------------------------------------------------------------------------- |
| VS Code           | Companion VS Code extension focuses the matching integrated terminal tab.    |
| macOS Terminal.app| AppleScript matches the tab by tty and selects its window.                   |
| Anything else     | Banner shows with no click-through (graceful fallback).                      |

## Requirements

- macOS
- [terminal-notifier](https://github.com/julienXX/terminal-notifier) (`brew install terminal-notifier`)
- `jq` (`brew install jq`)
- Node / `npx` (only needed at install time, to package the VS Code extension)
- VS Code `code` CLI on `$PATH` (if you use VS Code)

## Install

1. Clone this repo.
2. Run the bootstrap script (packages + installs the VS Code extension):
   ```bash
   ./install.sh
   ```
3. Reload your VS Code window: `Cmd+Shift+P` -> `Developer: Reload Window`.
4. Install the Claude Code plugin half (wires up the hooks):
   ```
   /plugin install <this-repo-url>
   ```
   Or from a local clone:
   ```
   /plugin install /absolute/path/to/claude-terminal-focus
   ```
5. Confirm `terminal-notifier` is allowed in **System Settings -> Notifications**. If banners don't appear, open `/opt/homebrew/Cellar/terminal-notifier/*/terminal-notifier.app` once so macOS registers it.
6. Optional: set **Alert Style -> Persistent** (older macOS labels this "Alerts") so banners stay on screen until clicked instead of auto-dismissing.

## Uninstall

```bash
code --uninstall-extension claude-code-community.claude-focus
# and in Claude Code:
/plugin uninstall claude-terminal-focus
```

## Troubleshooting

- **Banner never appears** — `terminal-notifier` isn't allowed to post notifications. Check System Settings -> Notifications.
- **Click lands on wrong tab (VS Code)** — probably started Claude in a different window than the one currently focused when you clicked. VS Code routes `vscode://` URIs to the focused window only.
- **Click does nothing (Terminal.app)** — automation permission prompt may have been denied. Check System Settings -> Privacy & Security -> Automation -> `terminal-notifier` -> Terminal.

## Repo layout

```
.claude-plugin/plugin.json     Claude Code plugin manifest
hooks/hooks.json               Hook declarations (Notification + Stop)
hooks/notify.sh                Main hook: picks focus strategy by $TERM_PROGRAM
hooks/focus-terminal-tab.sh    AppleScript helper for Terminal.app
vscode-extension/              Source for the companion VS Code extension
install.sh                     Packages + installs the VS Code extension
```

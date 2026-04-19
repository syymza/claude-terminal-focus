# claude-terminal-focus

Click a Claude Code macOS notification and jump straight back to the terminal tab the session is running in.

## What it does

Claude Code's `Notification` and `Stop` hooks fire a `terminal-notifier` banner whose click-action focuses the exact terminal where Claude is running:

| Terminal           | Click behaviour                                                             |
| ------------------ | --------------------------------------------------------------------------- |
| VS Code            | Companion extension focuses the matching integrated terminal tab.           |
| Cursor             | Same extension (installed into Cursor) focuses the matching terminal tab.   |
| macOS Terminal.app | AppleScript matches the tab by tty and selects its window.                  |
| iTerm2             | AppleScript matches the session by tty and selects its tab/window.          |
| Warp               | Activates Warp (no tab-level focus — Warp's AppleScript surface is limited).|
| cmux               | `cmux focus-surface` focuses the exact pane (requires the `cmux` CLI on PATH). |
| Ghostty (plain)    | Banner shows with no click-through (Ghostty has no scriptable tab focus).   |
| Anything else      | Banner shows with no click-through (graceful fallback).                     |

## Requirements

- macOS
- [terminal-notifier](https://github.com/julienXX/terminal-notifier) (`brew install terminal-notifier`)
- `jq` (`brew install jq`)
- Node / `npx` (only needed at install time, to package the editor extension)
- `code` or `cursor` CLI on `$PATH` (only if you use VS Code and/or Cursor — `install.sh` installs into whichever CLIs it finds)
- `cmux` CLI on `$PATH` (only if you use [cmux](https://github.com/manaflow-ai/cmux) — ships with the app; install its "cmux" shell command from the menu bar)

## Install

1. Wire up the Claude Code plugin (required — this is what fires the notifications):
   ```
   /plugin marketplace add syymza/claude-terminal-focus
   /plugin install claude-terminal-focus@claude-terminal-focus
   ```
2. **VS Code / Cursor users only** — clone this repo and run the bootstrap script to install the companion editor extension. It packages the VSIX and installs into both `code` and `cursor` if their CLIs are on PATH:
   ```bash
   git clone https://github.com/syymza/claude-terminal-focus.git
   cd claude-terminal-focus
   ./install.sh
   ```
   Then reload your editor window: `Cmd+Shift+P` -> `Developer: Reload Window`. Terminal.app / iTerm2 / Warp users can skip this step entirely.
3. Confirm `terminal-notifier` is allowed in **System Settings -> Notifications**. If banners don't appear, open `/opt/homebrew/Cellar/terminal-notifier/*/terminal-notifier.app` once so macOS registers it.
4. Optional: set **Alert Style -> Persistent** (older macOS labels this "Alerts") so banners stay on screen until clicked instead of auto-dismissing.

## Uninstall

```bash
# In Claude Code:
/plugin uninstall claude-terminal-focus

# Then, if you installed the editor extension:
code --uninstall-extension claude-code-community.claude-focus 2>/dev/null
cursor --uninstall-extension claude-code-community.claude-focus 2>/dev/null
```

## Troubleshooting

- **Banner never appears** — `terminal-notifier` isn't allowed to post notifications. Check System Settings -> Notifications.
- **Click does nothing (Terminal.app or iTerm2)** — automation permission prompt may have been denied. Check System Settings -> Privacy & Security -> Automation -> `terminal-notifier` -> enable the matching target (Terminal or iTerm).
- **Click does nothing (cmux)** — the `cmux` CLI isn't on PATH, or `CMUX_SURFACE_ID` isn't set in the pane. Run `command -v cmux` and `echo $CMUX_SURFACE_ID` in the pane; if the binary isn't found, install the cmux shell command from cmux's menu bar.

## Repo layout

```
.claude-plugin/marketplace.json                       Marketplace manifest
plugins/claude-terminal-focus/
  .claude-plugin/plugin.json                          Plugin manifest
  hooks/hooks.json                                    Notification + Stop hook declarations
  hooks/notify.sh                                     Main hook: picks focus strategy by $TERM_PROGRAM
  hooks/focus-terminal-tab.sh                         AppleScript helper for Terminal.app
  hooks/focus-iterm2-tab.sh                           AppleScript helper for iTerm2
vscode-extension/                                     Source for the VS Code / Cursor extension
install.sh                                            Packages + installs the extension into VS Code / Cursor
```

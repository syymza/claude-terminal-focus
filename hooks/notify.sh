#!/usr/bin/env bash
# Claude Code notification hook.
# Dispatches a macOS banner via terminal-notifier whose click-action
# focuses the exact terminal tab Claude is running in.
#
# Supported terminals (via $TERM_PROGRAM):
#   - vscode          -> vscode:// URI handled by the claude-focus VS Code extension
#   - Apple_Terminal  -> AppleScript matching Terminal.app tab by tty
#   - anything else   -> banner only, no click-through
#
# Banner layout:
#   title    = "Claude Code"
#   subtitle = <project-dir-name> [(<git-branch>)]
#   message  = event-specific:
#              - Notification -> .message from payload
#              - Stop         -> first line of Claude's last assistant text

set -u

MAX_MSG_LEN=110

event="${1:-notification}"
payload=$(cat)

cwd=$(jq -r '.cwd // empty' <<<"$payload")
transcript=$(jq -r '.transcript_path // empty' <<<"$payload")

# Subtitle: project name + git branch (when inside a repo)
subtitle=""
if [ -n "$cwd" ] && [ -d "$cwd" ]; then
  project_name=$(basename "$cwd")
  toplevel=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null || true)
  [ -n "$toplevel" ] && project_name=$(basename "$toplevel")
  branch=$(git -C "$cwd" rev-parse --abbrev-ref HEAD 2>/dev/null || true)
  if [ -n "${branch:-}" ] && [ "$branch" != "HEAD" ]; then
    subtitle="$project_name ($branch)"
  else
    subtitle="$project_name"
  fi
fi

truncate_msg() {
  local text="$1"
  local first_line
  first_line=$(printf '%s' "$text" | head -n 1)
  if [ "${#first_line}" -gt "$MAX_MSG_LEN" ]; then
    printf '%s…' "$(printf '%s' "$first_line" | head -c "$MAX_MSG_LEN")"
  else
    printf '%s' "$first_line"
  fi
}

last_assistant_text() {
  [ -z "$transcript" ] || [ ! -f "$transcript" ] && return 0
  # tail -r: reverse file (BSD/macOS); GNU users should have `tac` but we
  # target macOS so tail -r is fine.
  tail -r "$transcript" 2>/dev/null | head -n 200 | \
    jq -r 'select(.type=="assistant") | ([.message.content[]? | select(.type=="text") | .text] | last // empty) | select(length > 0)' 2>/dev/null | \
    awk 'NF { print; exit }'
}

case "$event" in
  notification)
    raw=$(jq -r '.message // "Needs your attention"' <<<"$payload")
    msg=$(truncate_msg "$raw")
    sound="Glass"
    ;;
  stop)
    raw=$(last_assistant_text)
    if [ -n "$raw" ]; then
      msg=$(truncate_msg "$raw")
    else
      msg="Task complete"
    fi
    sound="Hero"
    ;;
  *)
    msg="Claude Code"
    sound="Glass"
    ;;
esac

# Walk up the process tree to find the interactive shell PID.
# VS Code / Terminal.app spawn zsh/bash/fish directly; Claude Code is
# a Node child of that shell; the hook is a sh/bash child of Claude.
# Start from PPID so we skip this script's own bash interpreter.
pid=$PPID
for _ in 1 2 3 4 5 6 7 8; do
  comm=$(ps -o comm= -p "$pid" 2>/dev/null | awk '{print $NF}')
  case "$comm" in
    *zsh|*bash|*fish) break ;;
  esac
  parent=$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ')
  if [ -z "$parent" ] || [ "$parent" = "0" ] || [ "$parent" = "1" ] || [ "$parent" = "$pid" ]; then
    break
  fi
  pid="$parent"
done

SELF_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

case "${TERM_PROGRAM:-}" in
  vscode)
    # The publisher/name must match what the VS Code extension registers.
    execute_cmd="open 'vscode://claude-code-community.claude-focus/focus?pid=${pid}'"
    ;;
  Apple_Terminal)
    tty_path=$(ps -o tty= -p "$pid" 2>/dev/null | tr -d ' ')
    execute_cmd="$SELF_DIR/focus-terminal-tab.sh '$tty_path'"
    ;;
  *)
    execute_cmd=""
    ;;
esac

# -group keyed on the shell PID so repeat notifications from the same
# Claude session replace the older entry in Notification Center instead
# of piling up. Different sessions (different PIDs) still stack.
group="claude-code-$pid"

args=(
  -title 'Claude Code'
  -message "$msg"
  -sound "$sound"
  -group "$group"
)
[ -n "$subtitle" ] && args+=(-subtitle "$subtitle")
[ -n "$execute_cmd" ] && args+=(-execute "$execute_cmd")

terminal-notifier "${args[@]}"

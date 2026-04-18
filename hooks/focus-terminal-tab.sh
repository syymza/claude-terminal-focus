#!/usr/bin/env bash
# Focus a macOS Terminal.app tab whose tty matches the given path.
# Called from notify.sh via terminal-notifier's -execute.

tty_path="${1:-}"
if [ -z "$tty_path" ]; then
  exit 0
fi

case "$tty_path" in
  /dev/*) ;;
  *) tty_path="/dev/$tty_path" ;;
esac

osascript \
  -e 'on run argv' \
  -e '  set targetTty to item 1 of argv' \
  -e '  tell application "Terminal"' \
  -e '    activate' \
  -e '    repeat with w in windows' \
  -e '      repeat with t in tabs of w' \
  -e '        if tty of t is targetTty then' \
  -e '          set selected of t to true' \
  -e '          set frontmost of w to true' \
  -e '          return' \
  -e '        end if' \
  -e '      end repeat' \
  -e '    end repeat' \
  -e '  end tell' \
  -e 'end run' \
  -- "$tty_path"

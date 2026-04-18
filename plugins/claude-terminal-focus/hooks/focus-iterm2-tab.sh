#!/usr/bin/env bash
# Focus an iTerm2 session by its tty (e.g. /dev/ttys001).
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
  -e '  tell application "iTerm2"' \
  -e '    activate' \
  -e '    repeat with w in windows' \
  -e '      repeat with t in tabs of w' \
  -e '        repeat with s in sessions of t' \
  -e '          try' \
  -e '            if tty of s is targetTty then' \
  -e '              select s' \
  -e '              tell w to select t' \
  -e '              return' \
  -e '            end if' \
  -e '          end try' \
  -e '        end repeat' \
  -e '      end repeat' \
  -e '    end repeat' \
  -e '  end tell' \
  -e 'end run' \
  -- "$tty_path"

#!/bin/sh
# Claude Code hook: mark the tmux pane running Claude while it waits for the user.
#   set   -> Stop / Notification (finished replying, or asking for permission)
#   clear -> UserPromptSubmit / PostToolUse / SessionEnd (user answered, work resumed)
# The status bar and the terminal title read the pane option @claude_wait (see .tmux.conf).
# The outer terminal tab (Windows Terminal) gets OSC 9;4: state 2 = red progress ring, 0 = cleared.
[ -n "$TMUX_PANE" ] || exit 0
case "$1" in
  set)   tmux set-option -p -t "$TMUX_PANE" @claude_wait 1 ;;
  clear) tmux set-option -p -u -t "$TMUX_PANE" @claude_wait ;;
  *)     exit 0 ;;
esac

any=$(tmux display -p -t "$TMUX_PANE" '#{W:#{P:#{@claude_wait}}}')
if [ -n "$any" ]; then state=2; else state=0; fi
# PostToolUse fires on every tool call; only write to the tty when the tab state changes.
last=$(tmux show-option -qv @claude_tab_state)
if [ "$state" != "$last" ]; then
  tmux set-option -q @claude_tab_state "$state"
  tty=$(tmux display -p -t "$TMUX_PANE" '#{pane_tty}')
  # DCS tmux; passthrough (needs allow-passthrough all so it reaches the tab from a hidden window)
  [ -w "$tty" ] && printf '\033Ptmux;\033\033]9;4;%s;100\007\033\\' "$state" > "$tty"
fi
tmux refresh-client -S 2>/dev/null
exit 0

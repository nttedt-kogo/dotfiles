#!/usr/bin/env bash
# tmux popup から fzf でファイルを選び、呼び出し元ペインへ送り込む。
#   - file モード(既定): rg --files をfzfであいまい検索（batプレビュー）
#   - grep モード      : rg で全文検索（Ctrl-s で切替。記事のC-s相当）
# 送信形式: 呼び出し元が AI(claude等) なら "@path"、通常シェルならエスケープ済みパス。
# 使い方（.tmux.conf）:
#   bind -n M-f display-popup -E -w 80% -h 80% -d '#{pane_current_path}' \
#     "~/dotfiles/scripts/tmux-file-picker.sh"
set -uo pipefail

SELF="$(realpath "$0")"
RG_GREP="rg --column --line-number --no-heading --color=always --smart-case"

case "${1:-files}" in
  # ---- 選択結果を呼び出し元ペインへ送信（enter:become から呼ばれる）----
  --send)
    listfile="${2:-}"
    [ -f "$listfile" ] || exit 0
    target=$(tmux display-message -p '#{pane_id}')          # popup内から見た=呼び出し元ペイン
    cmd=$(tmux display-message -p -t "$target" '#{pane_current_command}')
    payload=""
    # grep結果(file:line:col:text)はfile部分を取り出し、重複は除去
    while IFS= read -r f; do
      [ -z "$f" ] && continue
      case "$cmd" in
        *claude*|*node*|*aider*|*python*) ref="@$f" ;;
        *) ref="$(printf '%q' "$f")" ;;
      esac
      payload="${payload:+$payload }$ref"
    done < <(sed 's/:[0-9].*$//' "$listfile" | awk 'NF && !seen[$0]++')
    [ -n "$payload" ] && tmux send-keys -t "$target" "$payload "
    ;;

  # ---- grep モード（全文検索）----
  grep)
    : | fzf --ansi --multi --disabled \
      --prompt 'grep> ' \
      --header 'Ctrl-s:fileモード  Enter:送信  Tab:複数選択' \
      --delimiter : \
      --bind "start:reload:$RG_GREP {q} 2>/dev/null || true" \
      --bind "change:reload:sleep 0.1; $RG_GREP {q} 2>/dev/null || true" \
      --bind "ctrl-s:become($SELF files)" \
      --bind "enter:become($SELF --send {+f})" \
      --preview 'bat --style=numbers --color=always --highlight-line {2} {1} 2>/dev/null || cat {1}' \
      --preview-window 'right,60%,border-left,+{2}+3/3'
    ;;

  # ---- file モード（既定）----
  *)
    rg --files --hidden --glob '!.git/*' 2>/dev/null | fzf --ansi --multi \
      --prompt 'files> ' \
      --header 'Ctrl-s:grepモード  Enter:送信  Tab:複数選択' \
      --bind "ctrl-s:become($SELF grep)" \
      --bind "enter:become($SELF --send {+f})" \
      --preview 'bat --style=numbers --color=always --line-range :300 {} 2>/dev/null || cat {}' \
      --preview-window 'right,60%,border-left'
    ;;
esac
exit 0

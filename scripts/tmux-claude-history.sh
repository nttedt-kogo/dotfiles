#!/usr/bin/env bash
# Claude Code の過去会話を fzf で選び、claude --resume で再開する（記事のC-h相当）。
#   既定: 呼び出し元ペインのcwdのプロジェクトの履歴
#   Ctrl-a: 全プロジェクト / Ctrl-p: 現プロジェクト に切替
#   Enter : そのセッションを呼び出し元ペインで claude --resume
# 履歴の場所: ~/.claude/projects/<cwdを/→-変換>/<セッションID>.jsonl
# 使い方（.tmux.conf）:
#   bind -n M-r display-popup -E -w 85% -h 85% -d '#{pane_current_path}' \
#     "~/dotfiles/scripts/tmux-claude-history.sh"
set -uo pipefail

SELF="$(realpath "$0")"
ROOT="$HOME/.claude/projects"

# セッション一覧: "日時\tタイトル\tjsonlパス"（新しい順）
list() {
  local scope="$1" dirs d enc
  if [ "$scope" = current ]; then
    enc=$(printf '%s' "$PWD" | sed 's:/:-:g')   # /home/kazu/dotfiles -> -home-kazu-dotfiles
    dirs="$ROOT/$enc"
  else
    dirs=$(find "$ROOT" -mindepth 1 -maxdepth 1 -type d 2>/dev/null)
  fi
  for d in $dirs; do
    [ -d "$d" ] || continue
    find "$d" -maxdepth 1 -name '*.jsonl' -printf '%T@\t%p\n' 2>/dev/null
  done | sort -rn | while IFS=$'\t' read -r epoch f; do
    local ts title
    ts=$(date -d "@${epoch%.*}" '+%m/%d %H:%M' 2>/dev/null || echo '--/-- --:--')
    title=$(jq -r 'select(.type=="ai-title").aiTitle' "$f" 2>/dev/null | tail -1)
    if [ -z "$title" ]; then
      title=$(jq -r 'select(.type=="user") | (.message.content | if type=="string" then . else (map(select(.type?=="text").text)|join(" ")) end)' "$f" 2>/dev/null | grep -v '^[[:space:]]*$' | head -1)
    fi
    title=$(printf '%s' "$title" | tr '\n' ' ' | cut -c1-70)
    [ -z "$title" ] && title="(no title)"
    printf '%s\t%s\t%s\n' "$ts" "$title" "$f"
  done
}

# プレビュー: 会話をmarkdownとして描画
preview() {
  local f="$1"
  jq -r '
    select(.type=="user" or .type=="assistant")
    | (if .type=="user" then "### 👤 You" else "### 🤖 Claude" end)
      + "\n\n"
      + ((.message.content) | if type=="string" then . else (map(select(.type?=="text").text)|join("\n")) end)
      + "\n"
  ' "$f" 2>/dev/null | grep -v '^[[:space:]]*$' | bat --language=md --color=always --style=plain 2>/dev/null
}

# 選択セッションを呼び出し元ペインで再開
resume() {
  local f="$1" sid target
  sid=$(basename "$f" .jsonl)
  target=$(tmux display-message -p '#{pane_id}')
  tmux send-keys -t "$target" "claude --resume $sid" C-m
}

case "${1:-}" in
  --list)    list "${2:-current}"; exit 0 ;;
  --preview) preview "${2:-}"; exit 0 ;;
  --resume)  resume "${2:-}"; exit 0 ;;
  *)
    fzf --ansi --delimiter '\t' --with-nth 1,2 \
      --prompt 'history(current)> ' \
      --header 'Ctrl-a:全プロジェクト  Ctrl-p:現プロジェクト  Enter:resume' \
      --bind "start:reload:$SELF --list current" \
      --bind "ctrl-a:change-prompt(history(all)> )+reload($SELF --list all)" \
      --bind "ctrl-p:change-prompt(history(current)> )+reload($SELF --list current)" \
      --bind "enter:become($SELF --resume {3})" \
      --preview "$SELF --preview {3}" \
      --preview-window 'right,65%,border-left,wrap'
    ;;
esac
exit 0

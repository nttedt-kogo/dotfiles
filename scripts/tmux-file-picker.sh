#!/usr/bin/env bash
# tmux popup から fzf+rg でファイルを選び、呼び出し元ペインへ送り込む。
#   - 呼び出し元が AI(claude等) なら "@path" 形式（Claudeのファイル参照記法）
#   - 通常のシェルなら シェルエスケープ済みのパス
# 使い方（.tmux.conf）:
#   bind f display-popup -E -w 80% -h 80% -d '#{pane_current_path}' \
#     "~/dotfiles/scripts/tmux-file-picker.sh '#{pane_id}'"
set -euo pipefail

# 送信先ペインの特定。
# display-popup はコマンド文字列内の #{pane_id} を展開しないため、引数が無効なら
# popup内から「現在アクティブなペイン(=呼び出し元)」を自分で取得する。
target_pane="${1:-}"
case "$target_pane" in
  %[0-9]*) : ;;  # 正しい pane id が渡された場合はそれを使う
  *) target_pane=$(tmux display-message -p '#{pane_id}') ;;
esac
[ -z "$target_pane" ] && { echo "送信先ペインを特定できませんでした"; sleep 1; exit 1; }

# ファイル一覧（rg優先、なければfind）。bat でプレビュー。複数選択可（Tab）。
list_cmd='rg --files --hidden --glob "!.git/*"'
command -v rg >/dev/null 2>&1 || list_cmd='find . -type f -not -path "*/.git/*"'

preview='bat --style=numbers --color=always --line-range :300 {} 2>/dev/null || cat {}'
command -v bat >/dev/null 2>&1 || preview='cat {}'

selected=$(eval "$list_cmd" \
  | fzf --multi \
        --height 100% \
        --preview "$preview" \
        --preview-window 'right,60%,border-left' \
        --prompt 'file> ' \
        --header 'Enter:送信  Tab:複数選択  Esc:中止') || exit 0
[ -z "$selected" ] && exit 0

# 呼び出し元ペインで動いているコマンドで送信形式を切り替え
cmd=$(tmux display-message -p -t "$target_pane" '#{pane_current_command}')

payload=""
while IFS= read -r f; do
  [ -z "$f" ] && continue
  case "$cmd" in
    *claude*|*node*|*aider*|*python*) ref="@$f" ;;          # AIエージェント → @path
    *) ref="$(printf '%q' "$f")" ;;                          # 通常シェル → エスケープ済み
  esac
  payload="${payload:+$payload }$ref"
done <<< "$selected"

# 末尾スペース付きで送信（Enterは送らない＝続けて入力・確認できる）
tmux send-keys -t "$target_pane" "$payload "

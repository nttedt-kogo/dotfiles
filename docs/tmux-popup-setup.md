# tmux popup ツール

`display-popup` を使った浮かぶ小窓の機能群。キーは全て prefix 不要の Alt 系。

| キー | 機能 | スクリプト/コマンド |
|---|---|---|
| `Alt+f` | ファイルピッカー（fzf+rg → `@path`/パス送信） | `scripts/tmux-file-picker.sh` |
| └ popup内 `Ctrl-s` | grep(全文検索) ⇄ file モード切替 | 同上 |
| `Alt+r` | Claude会話履歴 → 元ペインで `claude --resume` | `scripts/tmux-claude-history.sh` |
| └ popup内 `Ctrl-a`/`Ctrl-p` | 全プロジェクト / 現プロジェクト 切替 | 同上 |
| `Alt+g` | lazygit（git TUI） | `lazygit` バイナリ |

## 仕組みのメモ

- `display-popup` は **コマンド文字列内の `#{pane_id}` を展開しない**（`-d` 等の専用オプションは展開する）。
  そのため送信先ペインはスクリプト側で `tmux display-message -p '#{pane_id}'`（popup内から見た=呼び出し元）で特定する。
- 会話履歴の resume は呼び出し元ペインで実行（シェルなら send-keys、claude等なら respawn-pane で置換）。
- 履歴の場所: `~/.claude/projects/<cwdを/→-変換>/<セッションID>.jsonl`。一覧は `ai-title` を使用。

## 再現用セットアップ（別マシン）

依存: `fzf` `rg` `bat` `jq`（履歴用）。スクリプトはこのリポジトリの `scripts/` に含まれる。

### lazygit（バイナリ・git管理外。要再取得）
```sh
gh release download --repo jesseduffield/lazygit \
  --pattern "lazygit_*_linux_x86_64.tar.gz" --output /tmp/lazygit.tar.gz --clobber
mkdir -p /tmp/lg && tar -xzf /tmp/lazygit.tar.gz -C /tmp/lg
install -m 755 /tmp/lg/lazygit ~/.local/bin/lazygit
```

### キーバインドは `.tmux.conf` の「popup」セクションに定義済み
`~/.config/tmux` 等ではなく `~/.tmux.conf`（このリポジトリへのシンボリックリンク）。

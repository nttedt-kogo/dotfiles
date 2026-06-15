# tmux × Claude Code 開発環境 強化ロードマップ

参考記事: <https://dev.classmethod.jp/articles/shuntaka-claude-code-tmux-personal-tips/>

このリポジトリの環境を段階的に育てるための計画。各フェーズは独立して着手・完了できる。

## 現状（2026-06-15 時点）

- **OS**: ネイティブ Linux（Linux 6.17 / not WSL）
- **tmux**: 3.4（`display-popup` 対応 ✓）
- **claude**: 2.1.177
- **zsh**: oh-my-zsh + starship + fzf + fzf-tab
- **導入済み**: `rg` `fzf` `bat` `eza` `gh`
- **未導入**: `lazygit` `glow` `nvim` `delta` `direnv` `zoxide`
- **既知のバグ**: `.tmux.conf` L99-101 のコピー先が `clip.exe`（Windows用）。ネイティブ Linux では動かないため `wl-copy`/`xclip` へ要修正。

## フェーズ一覧

### Phase 1: ペイン共有ワークフロー ＋ クリップボード修正  ⬜
- **目的**: ゼロ手間で最大効果。Claude に `tmux pane %X を見て` でログ/エラーを丸ごと渡す運用を確立。
- **作業**:
  - [ ] `.tmux.conf` のコピー先を `clip.exe` → `wl-copy`（Wayland）/ `xclip`（X11）に修正
  - [ ] ステータスバー等にペインID（`#{pane_id}`）を表示し、参照しやすくする（任意）
  - [ ] 運用メモを CLAUDE.md か本ファイルに記載（"pane %X を見て" の定型文）
- **必要ツール**: なし（`wl-clipboard` か `xclip` の導入のみ）

### Phase 2: C-f ファイルピッカーポップアップ  ⬜
- **目的**: tmux ポップアップで `fzf`+`rg` のファイル選択を起動 → 選んだファイルを `@path` 形式で Claude ペインへ送信。
- **作業**:
  - [ ] `scripts/tmux-file-picker.sh` を作成（fzf + rg + bat プレビュー）
  - [ ] AIプロセス判定 → `@path` 送信 / 通常シェル → エスケープ済みパス送信
  - [ ] `.tmux.conf` に `bind C-f display-popup ...` を追加
- **必要ツール**: 導入済み（`fzf` `rg` `bat`）

### Phase 3: レイアウト一発起動 ＋ nvim  ⬜
- **目的**: コマンド一発で nvim + Claude×2 + shell のtmux構成を立ち上げる。
- **作業**:
  - [ ] `nvim` を導入
  - [ ] zsh 関数 `dev`（記事の `dhh` 相当）を作成
- **必要ツール**: `nvim`

### Phase 4: lazygit ポップアップ（C-g）  ⬜
- **目的**: tmux popup で lazygit を起動し git 操作を高速化。
- **作業**:
  - [ ] `lazygit` を導入
  - [ ] `.tmux.conf` に `bind C-g display-popup -E lazygit`
  - [ ] （任意）`delta` を導入して diff を綺麗に
- **必要ツール**: `lazygit`（+ `delta`）

### Phase 5: git worktree 並行作業 ＋ direnv  ⬜
- **目的**: 複数ブランチを worktree で隔離し、Claude を並行実行。
- **作業**:
  - [ ] `direnv` `zoxide` を導入
  - [ ] worktree 用ディレクトリ構成と `.envrc` 継承の運用を定義
  - [ ] worktree 作成ヘルパー関数 or `worktrunk` 検討
  - [ ] `M-S` ウィンドウソート（`tmux-sort-windows.sh`）
- **必要ツール**: `direnv` `zoxide`

### Phase 6: 会話履歴ポップアップ（C-h）  ⬜
- **目的**: 過去の Claude Code 会話を `fzf`+`glow` で選び `claude --resume` に直結。
- **作業**:
  - [ ] `glow` を導入
  - [ ] `~/.claude/projects/` の履歴を走査するスクリプト作成（chathist 相当の自作）
  - [ ] `.tmux.conf` に `bind C-h display-popup ...`
- **必要ツール**: `glow`（履歴ツールは自作）

## 進め方

各フェーズ完了時にチェックボックスを埋め、コミットする。順番は前後してもよいが、Phase 1 から始めるのが最も費用対効果が高い。

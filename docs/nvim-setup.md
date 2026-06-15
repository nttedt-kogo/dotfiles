# Neovim 環境（kickstart.nvim + claudecode.nvim）

ターミナル完結のエディタとして Neovim を導入。`dev nvim`（.zshrc）で「左nvim + 右Claude×2」のレイアウトが立ち上がる。

- ベース: **kickstart.nvim**（教材型の単一init.lua。`vim.pack`=Neovim 0.12内蔵のプラグイン管理を使用）
- 追加: **coder/claudecode.nvim**（nvim ↔ Claude Code CLI 連携）
- 設定本体は `~/dotfiles/nvim/`、`~/.config/nvim` はそこへのシンボリックリンク。

## 主要キーマップ（リーダー = Space）

| キー | 動作 |
|---|---|
| `Space`（押して待つ） | which-key が候補ポップアップ表示 |
| `Space s f` / `Space s g` | ファイル検索 / grep検索（Telescope） |
| `Space a c` | nvim内にClaude Codeを開く/閉じる（連携起動） |
| `Space a s`（ビジュアル選択中） | 選択範囲をClaudeに送る |
| `Space a a` / `Space a d` | Claudeの差分を承認 / 却下 |
| `-`（netrwで） | 上のディレクトリへ |
| `:q` / `:wq` | 終了 / 保存して終了 |

## セットアップ手順（別マシン再現用）

### 前提ツール
`git` `cc/gcc` `make` `rg` `fd` `node` `unzip` が必要（大半は標準で入っている）。

### 1. Neovim 本体（公式バイナリを ~/.local へ。sudo不要）
```sh
gh release download --repo neovim/neovim --pattern "nvim-linux-x86_64.tar.gz" \
  --output /tmp/nvim.tar.gz --clobber
tar -xzf /tmp/nvim.tar.gz -C /tmp
cp -r /tmp/nvim-linux-x86_64/bin/*   ~/.local/bin/
cp -r /tmp/nvim-linux-x86_64/lib/*   ~/.local/lib/
cp -r /tmp/nvim-linux-x86_64/share/* ~/.local/share/
```

### 2. tree-sitter CLI（パーサーのコンパイルに必須）
これが無いと treesitter パーサーのビルドが `tree-sitter not found` で失敗する。
```sh
npm config set prefix ~/.local   # 未設定なら（sudo回避）
npm install -g tree-sitter-cli
```

### 3. 設定はこのリポジトリの `nvim/` を `~/.config/nvim` にリンク
```sh
ln -s ~/dotfiles/nvim ~/.config/nvim
```

### 4. プラグインのインストール
nvim を起動すれば `vim.pack` が自動でプラグインを取得する。ヘッドレスで一括導入する場合:
```sh
nvim --headless "+qa!"                                   # プラグイン取得
nvim --headless "+lua require('nvim-treesitter').install({'lua','bash','c','markdown','markdown_inline','vim','vimdoc','query','diff','html'}):wait(300000)" "+qa!"  # パーサー
```

## claudecode.nvim の追加方法（参考）

`nvim/lua/custom/plugins/claudecode.lua` に `vim.pack` 方式で定義済み。
`nvim/init.lua` 末尾の `require 'custom.plugins'` を有効化してあるので、
`lua/custom/plugins/*.lua` は自動で読み込まれる。

## メモ

- `nvim-pack-lock.json` を追跡している（プラグイン版固定）。更新は nvim内で `:lua vim.pack.update()`。
- 画像（mermaid等）のnvim内レンダリングは未導入。Windows Terminal は sixel のみ対応で
  image.nvim と相性が悪いため。図はターミナルの `mma`（ASCII）を利用する方針。

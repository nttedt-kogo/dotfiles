# dotfiles

自分用のターミナル環境設定 + Airgrow (uav-dev-env) 開発環境ブートストラップ。

## 含まれるもの

### ターミナル
- **zsh** + Oh My Zsh + プラグイン
- **Starship** プロンプト (Tokyo Night テーマ)
- **tmux** 設定
- **fzf** ファジーファインダー
- **eza** モダンな ls
- **bat** モダンな cat

### 開発ツール (install.sh で自動セットアップ)
- **Docker** + docker-compose plugin (uav-dev-env 必須)
- **GitHub CLI** (`gh`)
- **Tailscale** (リモート接続用)
- **Claude Code** (native installer)
- ビルドツール一式: `build-essential`, `cmake`, `pkg-config`, `ripgrep`, `fd`, `jq`, `python3-pip` など

### Claude Code 設定
- `~/.claude/settings.local.json` (グローバル permissions)

## インストール

```bash
git clone https://github.com/nttedt-kogo/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

`install.sh` は idempotent。複数回実行しても安全。

### インストール後の手動手順

1. **zsh をデフォルトシェルに**
   ```bash
   chsh -s "$(which zsh)"
   ```
2. **Docker グループ反映**: ログアウト → ログインし直し
3. **外部サービス認証**
   ```bash
   gh auth login                      # GitHub CLI
   sudo tailscale up                  # Tailscale (URL に従って認証)
   claude                             # Claude Code (初回 OAuth フロー)
   ```
4. **GitHub SSH 鍵** (まだ無ければ)
   ```bash
   ssh-keygen -t ed25519 -C "$(git config user.email)"
   gh ssh-key add ~/.ssh/id_ed25519.pub --title "$(hostname)"
   ```
5. **(オプション) `~/.ssh/config`** ― GitHub が 22 番でブロックされる環境では:
   ```
   Host github.com
     Hostname ssh.github.com
     Port 443
   ```
6. **(オプション) ロケール** ― 日本語設定が欲しければ `~/.pam_environment` に:
   ```
   LANG	DEFAULT=en_US.UTF-8
   LC_TIME	DEFAULT=ja_JP.UTF-8
   LC_NUMERIC	DEFAULT=ja_JP.UTF-8
   ```
   （ログイン時に反映）

## uav-dev-env (Airgrow) のセットアップ

dotfiles インストール後、別途プロジェクトを clone する:

```bash
mkdir -p ~/dev && cd ~/dev
git clone --recursive git@github.com:<org>/uav-dev-env.git
cd uav-dev-env
make help
```

詳細は uav-dev-env リポジトリの `CLAUDE.md` / `README.md` を参照。

## 主なキーバインド

### tmux

| キー | 動作 |
|------|------|
| `Ctrl+a \|` | 縦分割 |
| `Ctrl+a -` | 横分割 |
| `Ctrl+a h/j/k/l` | ペイン移動 |
| `Alt+矢印` | ペイン移動 |
| `Shift+左右` | ウィンドウ切替 |
| `Ctrl+a r` | 設定リロード |

### fzf

| キー | 動作 |
|------|------|
| `Ctrl+R` | 履歴検索 |
| `Ctrl+T` | ファイル検索 |
| `Alt+C` | ディレクトリ移動 |

## ファイル構成

```
dotfiles/
├── install.sh                       # ブートストラップスクリプト (apt + Docker + Claude Code 等)
├── .zshrc                           # → ~/.zshrc に symlink
├── .tmux.conf                       # → ~/.tmux.conf に symlink
├── .config/starship.toml            # → ~/.config/starship.toml に symlink
└── .claude/
    └── settings.local.json          # → ~/.claude/settings.local.json に symlink (Claude Code permissions)
```

## 注意事項

- `.zshrc` 末尾の `export DISPLAY=:10` は VNC :10 を立てている前提。別運用にする場合は条件分岐に変える
- Claude Code の permissions (`.claude/settings.local.json`) は symlink なので、新しい permission を追加したら dotfiles を commit して全 PC に反映できる

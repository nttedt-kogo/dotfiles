# dotfiles

自分用のターミナル環境設定。

## 含まれるもの

- **zsh** + Oh My Zsh + プラグイン
- **Starship** プロンプト (Tokyo Night テーマ)
- **tmux** 設定
- **fzf** ファジーファインダー
- **eza** モダンな ls
- **bat** モダンな cat

## インストール

```bash
git clone https://github.com/YOUR_USERNAME/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

## 必要なもの

- zsh (`sudo apt install zsh`)
- git
- curl

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

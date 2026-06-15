# ターミナルで mermaid 図を見る環境

ターミナル上で mermaid 図を表示するための環境メモ。2方式を併用する。

| コマンド | 方式 | 用途 | 依存 |
|---|---|---|---|
| `mma file.mmd` | ASCII/Unicodeアート | **日常使い**。サイズ切れなし・スクロール可・軽量 | `mermaid-ascii`（Goバイナリ） |
| `mmd file.mmd [幅]` | sixel画像 | 綺麗に見たい時（ただし画像サイズ制約あり） | `chafa` + `mermaid-cli`(Chromium) |

`.zshrc` に `mma`(alias) と `mmd`(関数)、`.tmux.conf` に sixel 受け渡し設定を定義済み。
バイナリ/パッケージ類は git管理外なので、別マシンでは以下を再実行する。

## セットアップ手順（再現用）

### 1. ASCII方式（mma）— おすすめ・これだけでほぼ足りる

`mermaid-ascii`（Go製バイナリ、Chromium不要）を GitHub Release から取得して `~/.local/bin` へ。

```sh
# x86_64 / Linux の例（最新版は releases を確認）
gh release download --repo AlexanderGrooff/mermaid-ascii \
  --pattern "mermaid-ascii_Linux_x86_64.tar.gz" --output /tmp/ma.tar.gz --clobber
mkdir -p /tmp/ma && tar -xzf /tmp/ma.tar.gz -C /tmp/ma
install -m 755 /tmp/ma/mermaid-ascii ~/.local/bin/mermaid-ascii
```

使い方:
```sh
mma diagram.mmd            # 表示
mermaid-ascii -f x.mmd -x 3 -y 3   # ノード間余白を詰める
mermaid-ascii -f x.mmd -a          # 拡張文字を使わない素のASCII
```

### 2. sixel画像方式（mmd）— 任意（綺麗に見たい時のみ）

```sh
# 表示ツール
sudo apt install -y chafa

# mermaid → PNG 変換（Chromium込み。npm prefixはユーザー領域推奨）
npm config set prefix ~/.local
npm install -g @mermaid-js/mermaid-cli

# Ubuntu 23.10+ は AppArmor で Chromium sandbox が動かないため --no-sandbox 設定
mkdir -p ~/.config/mermaid
printf '{ "args": ["--no-sandbox"] }\n' > ~/.config/mermaid/puppeteer-config.json
```

Chromium ランタイム依存（Ubuntu 24.04ではt64名）は標準で導入済みのことが多い。
起動失敗時は `libnss3 libatk1.0-0t64 libatk-bridge2.0-0t64 libcups2t64 libasound2t64 libgtk-3-0t64` 等を確認。

### 3. tmux 側（sixel をクライアント端末へ通す）

`.tmux.conf` に設定済み:
```
set -as terminal-features ",*:sixel"
set -g allow-passthrough on
```
※ 変更後は **デタッチ→再アタッチ**（`C-a d` → `tmux attach`）で反映される。

## 端末側の前提

- 接続元端末（Windows Terminal 1.22+ 等）が **sixel 対応**であること（mmd方式のみ）。
- mma方式は普通の文字なので端末を選ばない。

## 経緯メモ

- 当初 mmd(sixel) を導入したが、tmux内で画像が「ペインに収まらず切れる/小さい」問題があり、
  拡大・スクロールができない静止画像方式の限界と判断。
- ASCII方式(mma)に切り替えてサイズ問題を解消。mma を日常使いの主とし、mmd は補助に。

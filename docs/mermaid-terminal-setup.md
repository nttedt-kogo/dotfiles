# ターミナルで mermaid 図を見る環境

ターミナル上で mermaid 図を **ASCII/Unicodeアート** で表示する。
`.zshrc` に `mma` エイリアスを定義済み。

| コマンド | 方式 | 依存 |
|---|---|---|
| `mma file.mmd` | ASCII/Unicodeアート | `mermaid-ascii`（Goバイナリ・Chromium不要） |

画像方式（sixel）は採用しなかった（経緯は末尾）。文字描画なのでサイズ切れ・拡大不可の問題がなく軽い。

## セットアップ手順（再現用）

`mermaid-ascii`（Go製バイナリ）を GitHub Release から取得して `~/.local/bin` へ。
バイナリは git管理外なので、別マシンでは以下を再実行する。

```sh
# x86_64 / Linux の例（最新版は releases を確認）
gh release download --repo AlexanderGrooff/mermaid-ascii \
  --pattern "mermaid-ascii_Linux_x86_64.tar.gz" --output /tmp/ma.tar.gz --clobber
mkdir -p /tmp/ma && tar -xzf /tmp/ma.tar.gz -C /tmp/ma
install -m 755 /tmp/ma/mermaid-ascii ~/.local/bin/mermaid-ascii
```

## 使い方

```sh
mma diagram.mmd                    # 表示
mermaid-ascii -f x.mmd -x 3 -y 3   # ノード間の余白を詰める（横長になりすぎる時）
mermaid-ascii -f x.mmd -a          # 拡張文字を使わない素のASCII（コピペ先で崩れにくい）
cat x.mmd | mermaid-ascii -f -      # stdin から
```

## 経緯メモ（なぜ画像方式をやめたか）

- 当初 sixel画像方式（`mmdc`+`chafa`）も導入したが、2つの理由で撤去した:
  1. **使い勝手**: tmux内で画像が「ペインに収まらず切れる/小さい」。静止画像なので拡大・スクロールができず、大きい図に弱い。
  2. **重さ**: `mermaid-cli` は図の描画に headless Chromium を使うため、合計1GB超のディスクを消費していた。
- ASCII方式（`mma`）はこれらの問題がなく軽量なので、こちらに一本化した。
- なお `.tmux.conf` の sixel 受け渡し設定（`terminal-features sixel` / `allow-passthrough`）と `chafa` は
  汎用の画像表示用として残してある（mermaid専用ではないため）。不要なら削除可。

#!/usr/bin/env bash
# dotfiles セットアップ（別マシン用）。
#   1. シンボリックリンク作成（.tmux.conf / .zshrc / nvim / CLAUDE.md）
#   2. バイナリ導入（nvim / lazygit / mermaid-ascii / tree-sitter-cli を ~/.local へ）
#   3. apt パッケージ（rg/fzf/bat/jq/chafa 等）の不足分を案内・任意で導入
# 何度実行しても安全（既に揃っているものはスキップ）。x86_64 Linux 前提。
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCAL_BIN="$HOME/.local/bin"
mkdir -p "$LOCAL_BIN" "$HOME/.local/lib" "$HOME/.local/share" "$HOME/.config" "$HOME/.claude"

info(){ printf '\033[1;34m==>\033[0m %s\n' "$*"; }
ok(){   printf '\033[1;32m  ok\033[0m %s\n' "$*"; }
warn(){ printf '\033[1;33m  !!\033[0m %s\n' "$*"; }
have(){ command -v "$1" >/dev/null 2>&1; }

# ---- 1. シンボリックリンク -------------------------------------------------
link(){ # link <repo相対パス> <リンク先>
  local src="$REPO/$1" tgt="$2"
  [ -e "$src" ] || { warn "ソースが無い: $src"; return; }
  if [ -L "$tgt" ] && [ "$(readlink -f "$tgt")" = "$(readlink -f "$src")" ]; then
    ok "リンク済: $tgt"; return
  fi
  if [ -e "$tgt" ] || [ -L "$tgt" ]; then
    mv "$tgt" "$tgt.bak-$(date +%s)"; warn "既存を退避: $tgt -> $tgt.bak-*"
  fi
  mkdir -p "$(dirname "$tgt")"
  ln -s "$src" "$tgt"; ok "リンク作成: $tgt -> $src"
}

info "シンボリックリンクを作成"
link ".tmux.conf"      "$HOME/.tmux.conf"
link ".zshrc"          "$HOME/.zshrc"
link "nvim"            "$HOME/.config/nvim"
link "claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"

# ---- 2. バイナリ導入（~/.local、sudo不要）---------------------------------
if [ "$(uname -m)" != "x86_64" ]; then
  warn "x86_64 以外のため、バイナリ自動導入はスキップ（手動で導入してください）"
else
  latest_tag(){ curl -fsSL "https://api.github.com/repos/$1/releases/latest" | grep -oP '"tag_name":\s*"\K[^"]+'; }

  info "Neovim"
  if have nvim; then ok "既存"; else
    t=$(mktemp -d); curl -fsSL -o "$t/n.tgz" "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz" \
      && tar -xzf "$t/n.tgz" -C "$t" \
      && cp -r "$t"/nvim-linux-x86_64/bin/* "$LOCAL_BIN"/ \
      && cp -r "$t"/nvim-linux-x86_64/lib/* "$HOME/.local/lib/" 2>/dev/null \
      && cp -r "$t"/nvim-linux-x86_64/share/* "$HOME/.local/share/" 2>/dev/null \
      && ok "導入" || warn "導入失敗"; rm -rf "$t"
  fi

  info "lazygit"
  if have lazygit; then ok "既存"; else
    tag=$(latest_tag jesseduffield/lazygit); ver=${tag#v}; t=$(mktemp -d)
    curl -fsSL -o "$t/lg.tgz" "https://github.com/jesseduffield/lazygit/releases/download/$tag/lazygit_${ver}_linux_x86_64.tar.gz" \
      && tar -xzf "$t/lg.tgz" -C "$t" && install -m755 "$t/lazygit" "$LOCAL_BIN/lazygit" \
      && ok "導入" || warn "導入失敗"; rm -rf "$t"
  fi

  info "mermaid-ascii"
  if have mermaid-ascii; then ok "既存"; else
    t=$(mktemp -d)
    curl -fsSL -o "$t/ma.tgz" "https://github.com/AlexanderGrooff/mermaid-ascii/releases/latest/download/mermaid-ascii_Linux_x86_64.tar.gz" \
      && tar -xzf "$t/ma.tgz" -C "$t" && install -m755 "$t/mermaid-ascii" "$LOCAL_BIN/mermaid-ascii" \
      && ok "導入" || warn "導入失敗"; rm -rf "$t"
  fi

  info "tree-sitter-cli (nvim treesitterのパーサーコンパイル用)"
  if have tree-sitter; then ok "既存"
  elif have npm; then npm config set prefix "$HOME/.local" >/dev/null 2>&1; npm install -g tree-sitter-cli && ok "導入" || warn "導入失敗"
  else warn "npm が無いためスキップ（nodejs導入後に: npm i -g tree-sitter-cli）"; fi
fi

# ---- 3. apt パッケージ -----------------------------------------------------
# コマンド名:パッケージ名 の対応（Ubuntu/Debian）
declare -A APT=( [rg]=ripgrep [fzf]=fzf [jq]=jq [chafa]=chafa [git]=git [zsh]=zsh [node]=nodejs [bat]=bat [fd]=fd-find )
missing=()
for cmd in "${!APT[@]}"; do have "$cmd" || missing+=("${APT[$cmd]}"); done
if [ ${#missing[@]} -eq 0 ]; then
  info "apt: 必要なコマンドは揃っています"
else
  info "apt: 不足パッケージ: ${missing[*]}"
  if [ -t 0 ]; then
    read -rp "  sudo apt install しますか？ [y/N] " ans
    if [[ "$ans" =~ ^[Yy]$ ]]; then sudo apt-get update && sudo apt-get install -y "${missing[@]}"; fi
  else
    warn "手動で: sudo apt install ${missing[*]}"
  fi
  warn "Ubuntuでは bat→batcat, fd→fdfind の名前になる場合あり（.zshrcのaliasは bat/fd 前提）"
fi

# ---- 仕上げ ---------------------------------------------------------------
info "完了。次の手順:"
echo "  1) 新しいシェルを開く（exec zsh）→ PATHと関数を読み込み"
echo "  2) nvim を起動 → プラグインが自動インストールされる"
echo "  3) tmux を起動/再アタッチ → 設定反映（sixel等はデタッチ→再アタッチで有効化）"

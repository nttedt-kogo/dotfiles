#!/bin/bash
set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
echo "=== Dotfiles Installer ==="
echo "Installing from: $DOTFILES_DIR"
echo ""

# 色付き出力
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

# ===== Zsh確認 =====
if ! command -v zsh &> /dev/null; then
    warn "zsh not found. Please install zsh first:"
    echo "  Ubuntu/Debian: sudo apt install zsh"
    echo "  Then run: chsh -s \$(which zsh)"
    exit 1
fi

# ===== Oh My Zsh =====
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    info "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
    info "Oh My Zsh already installed"
fi

# ===== Zsh Plugins =====
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

plugins=(
    "zsh-users/zsh-autosuggestions"
    "zsh-users/zsh-syntax-highlighting"
    "zsh-users/zsh-completions"
    "Aloxaf/fzf-tab"
)

for plugin in "${plugins[@]}"; do
    plugin_name=$(basename "$plugin")
    plugin_dir="$ZSH_CUSTOM/plugins/$plugin_name"
    if [ ! -d "$plugin_dir" ]; then
        info "Installing $plugin_name..."
        git clone --depth=1 "https://github.com/$plugin" "$plugin_dir"
    else
        info "$plugin_name already installed"
    fi
done

# ===== fzf =====
if [ ! -d "$HOME/.fzf" ]; then
    info "Installing fzf..."
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    ~/.fzf/install --all --no-bash --no-fish
else
    info "fzf already installed"
fi

# ===== Starship =====
if ! command -v starship &> /dev/null; then
    info "Installing Starship..."
    curl -sS https://starship.rs/install.sh | sh -s -- -y
else
    info "Starship already installed"
fi

# ===== eza =====
mkdir -p ~/.local/bin
if ! command -v eza &> /dev/null && [ ! -f "$HOME/.local/bin/eza" ]; then
    info "Installing eza..."
    curl -sL https://github.com/eza-community/eza/releases/latest/download/eza_x86_64-unknown-linux-gnu.tar.gz | tar xz -C /tmp
    mv /tmp/eza ~/.local/bin/
    chmod +x ~/.local/bin/eza
else
    info "eza already installed"
fi

# ===== bat =====
if ! command -v bat &> /dev/null && [ ! -f "$HOME/.local/bin/bat" ]; then
    info "Installing bat..."
    curl -sL https://github.com/sharkdp/bat/releases/download/v0.24.0/bat-v0.24.0-x86_64-unknown-linux-gnu.tar.gz | tar xz -C /tmp
    mv /tmp/bat-v0.24.0-x86_64-unknown-linux-gnu/bat ~/.local/bin/
    chmod +x ~/.local/bin/bat
else
    info "bat already installed"
fi

# ===== シンボリックリンク作成 =====
info "Creating symlinks..."

# バックアップして置き換え
backup_and_link() {
    local src="$1"
    local dest="$2"
    if [ -f "$dest" ] && [ ! -L "$dest" ]; then
        warn "Backing up existing $dest to ${dest}.backup"
        mv "$dest" "${dest}.backup"
    fi
    ln -sf "$src" "$dest"
    info "Linked: $dest -> $src"
}

backup_and_link "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
backup_and_link "$DOTFILES_DIR/.tmux.conf" "$HOME/.tmux.conf"

mkdir -p "$HOME/.config"
backup_and_link "$DOTFILES_DIR/.config/starship.toml" "$HOME/.config/starship.toml"

# ===== 完了 =====
echo ""
echo "========================================="
echo -e "${GREEN}Installation complete!${NC}"
echo "========================================="
echo ""
echo "Next steps:"
echo "  1. Restart your terminal or run: source ~/.zshrc"
echo "  2. If zsh is not your default shell, run: chsh -s \$(which zsh)"
echo ""

# Path
# システムの標準パス(/usr/bin等)を明示的に含める。
# 引き継いだ$PATHが壊れていても(tmuxやexec zsh経由で/usr/binが抜ける事がある)復旧できるようにする。
typeset -U path PATH   # 重複エントリを自動で除去
export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH

# Oh My Zsh
export ZSH="$HOME/.oh-my-zsh"

# Starshipを使うのでテーマは無効
ZSH_THEME=""

# 更新チェック
zstyle ':omz:update' mode auto
zstyle ':omz:update' frequency 7

# 履歴設定
HISTSIZE=50000
SAVEHIST=50000
HIST_STAMPS="yyyy-mm-dd"
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS

# 補完設定
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# プラグイン（fzf-tabは最初に読み込む）
plugins=(
  fzf-tab
  git
  z
  docker
  docker-compose
  kubectl
  npm
  extract
  colored-man-pages
  command-not-found
  zsh-completions
  zsh-autosuggestions
  zsh-syntax-highlighting  # これは最後
)

# zsh-completionsのパス追加
fpath+=${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions/src

source $ZSH/oh-my-zsh.sh

# Starship prompt
eval "$(starship init zsh)"

# fzf
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# fzf設定
export FZF_DEFAULT_OPTS='
  --height 40%
  --layout=reverse
  --border
  --inline-info
  --color=fg:#c0caf5,bg:#1a1b26,hl:#bb9af7
  --color=fg+:#c0caf5,bg+:#292e42,hl+:#7dcfff
  --color=info:#7aa2f7,prompt:#7dcfff,pointer:#7dcfff
  --color=marker:#9ece6a,spinner:#9ece6a,header:#9ece6a
'

# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# エディタ
export EDITOR='vim'

# eza (モダンなls)
alias ls='eza --icons'
alias ll='eza -alh --icons --git'
alias la='eza -a --icons'
alias l='eza --icons'
alias lt='eza --tree --icons --level=2'
alias lta='eza --tree --icons -a --level=2'

# bat (モダンなcat)
alias cat='bat --paging=never'
alias catp='bat'  # ページャー付き
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Git shortcuts
alias g='git'
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'
alias gd='git diff'
alias gco='git checkout'
alias gb='git branch'
alias glog='git log --oneline --graph --decorate'

# Docker shortcuts
alias d='docker'
alias dc='docker-compose'
alias dps='docker ps'

# 安全なrm
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# カラフルなgrep
alias grep='grep --color=auto'

# 便利な関数
mkcd() { mkdir -p "$1" && cd "$1"; }

# mermaid図をASCII/Unicodeアートで表示（画像不要・サイズ切れなし・軽量）
# 使い方: mma diagram.mmd    （stdinは mermaid-ascii -f - ）
alias mma='mermaid-ascii -f'

# 作業レイアウトを一発起動（新規tmuxウィンドウ "dev"）
#   レイアウト: 左=エディタ / 右上=Claude / 右下=Claude / 下段=全幅シェル
#   dev        : 左=Claude
#   dev nvim   : 左=nvim
# 全ペインとも現在のディレクトリで開く
dev() {
  if [ -z "$TMUX" ]; then echo "dev: tmux セッションの中で実行してください"; return 1; fi
  local left_cmd
  case "${1:-claude}" in
    claude|c) left_cmd="claude" ;;
    nvim|n)   left_cmd="nvim ." ;;
    *) echo "usage: dev [claude|nvim]"; return 1 ;;
  esac
  # 注意: zshでは変数名 path は PATH と連動する特別変数。絶対に使わないこと
  local dir="$PWD" pe prt prb psh
  pe=$(tmux new-window    -P -F '#{pane_id}' -c "$dir" -n dev)             # 左=エディタ
  psh=$(tmux split-window -v -l 8 -P -F '#{pane_id}' -t "$pe"  -c "$dir")  # 下段=全幅シェル(先に切り出す)
  prt=$(tmux split-window -h      -P -F '#{pane_id}' -t "$pe"  -c "$dir")  # 右上=Claude
  prb=$(tmux split-window -v      -P -F '#{pane_id}' -t "$prt" -c "$dir")  # 右下=Claude
  tmux send-keys -t "$pe"  "$left_cmd" C-m
  tmux send-keys -t "$prt" "claude" C-m
  tmux send-keys -t "$prb" "claude" C-m
  # 下段シェル(psh)は素のまま（コマンド実行・ログ確認用）
  tmux select-pane -t "$pe"
}

export DISPLAY=:10

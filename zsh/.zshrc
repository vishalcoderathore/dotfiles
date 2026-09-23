# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Adding Homebrew (must precede oh-my-zsh so plugins like tmux can find brew binaries)
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time Oh My Zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
#ZSH_THEME="powerlevel10k/powerlevel10k"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git zsh-autosuggestions fast-syntax-highlighting tmux)

# Ensure ~/.local/bin is in the PATH
export PATH=$HOME/.local/bin:$PATH

# Load Oh My Zsh
source $ZSH/oh-my-zsh.sh

# Set Oh My Posh as the prompt
eval "$(oh-my-posh init zsh --config ~/.config/oh-my-posh/jandedobbeleer.omp.json)"


# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='nvim'
# fi

export EDITOR='nvim'
export VISUAL='nvim'

# ---------------------------------------------------------------------------
# fzf
# ---------------------------------------------------------------------------

# Source list: fd is faster than find, honours .gitignore, and still shows dotfiles.
if command -v fd >/dev/null 2>&1; then
  export FZF_DEFAULT_COMMAND='fd --type=f --hidden --follow --exclude .git'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_ALT_C_COMMAND='fd --type=d --hidden --follow --exclude .git'
fi

# --height keeps fzf inline, so the prompt and scrollback above it survive
# instead of being wiped by the alternate screen. --layout=reverse then draws
# the prompt at the top of that box, putting the best match on the first row.
export FZF_DEFAULT_OPTS="
  --height=60%
  --layout=reverse
  --border=rounded
  --info=inline
  --scrollbar
  --pointer=▶
  --marker=✚
  --preview='$HOME/.config/fzf/preview.sh {}'
  --preview-window=right,55%,border-left,nowrap
  --bind=ctrl-/:toggle-preview
  --bind=alt-w:toggle-preview-wrap
  --bind=alt-u:preview-half-page-up
  --bind=alt-d:preview-half-page-down
"

# Ctrl-R lists shell history, not files, so swap the file preview for a wrapped
# view of the command itself ({2..} drops fzf's leading history index).
export FZF_CTRL_R_OPTS="
  --preview='echo {2..}'
  --preview-window=down,4,wrap,border-top
  --bind='ctrl-y:execute-silent(printf %s {2..} | wl-copy)+abort'
  --header='ctrl-y: copy command to clipboard'
"

# Ctrl-T insert file path | Ctrl-R search history | Alt-C cd into a subdirectory
for _fzf_init in /usr/share/doc/fzf/examples/key-bindings.zsh \
                 /usr/share/doc/fzf/examples/completion.zsh \
                 ~/.fzf.zsh; do
  [ -f "$_fzf_init" ] && source "$_fzf_init"
done
unset _fzf_init

# Compilation flags
# export ARCHFLAGS="-arch $(uname -m)"

# Set personal aliases, overriding those provided by Oh My Zsh libs,
# plugins, and themes. Aliases can be placed here, though Oh My Zsh
# users are encouraged to define aliases within a top-level file in
# the $ZSH_CUSTOM folder, with .zsh extension. Examples:
# - $ZSH_CUSTOM/aliases.zsh
# - $ZSH_CUSTOM/macos.zsh
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
# [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

export GIT_SSH_COMMAND='ssh'

# Load NVM into the current shell session
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Add .NET SDK and tools to PATH
export DOTNET_ROOT="$HOME/.dotnet"
export PATH="$HOME/.dotnet:$HOME/.dotnet/tools:$PATH"

# Add rbenv
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"

# Setup default Node Version
function change_node_version {
	nvmrc="./.nvmrc"
	if [ -f "$nvmrc" ]; then
		version="$(cat "$nvmrc")"
		nvm use $version
	fi
}
chpwd_functions=(change_node_version)

# Custom Aliases
alias upd="sudo nala update"
alias upg="sudo nala upgrade"
alias autoclean="sudo apt-get autoclean"
alias install="sudo nala install"
alias remove="sudo nala remove --purge"
alias -g G="| grep"
alias py="python3"
alias gl="git log --oneline"
alias gs="git status"
alias dn="dotnet"
alias ls="lsd"
alias n="nnn"
alias ic="$HOME/.ssh/instanceTunnel.sh"
alias vi="nvim"
alias clr="clear"
alias bat="batcat"
alias cat="batcat"
alias vis="v"   # previous name, kept for muscle memory
alias ldo="lazydocker"
alias cld="claude"
alias update-joplin='wget -O - https://raw.githubusercontent.com/laurent22/joplin/dev/Joplin_install_and_update.sh | bash'

# v -- fuzzy-find a file and open it in $EDITOR.
#   v         search from the current directory
#   v src     search inside src/ when it is a directory, else seed the query
#   Tab marks several files and they all open at once.
v() {
	local dir=. query=
	if [[ -n $1 ]]; then
		if [[ -d $1 ]]; then dir=$1; else query=$*; fi
	fi

	local out
	out=$(fd --type=f --hidden --follow --exclude .git . "$dir" 2>/dev/null |
		fzf --multi --query="$query" \
			--prompt='⁙ ' \
			--header='tab mark · ctrl-/ preview · alt-w wrap' \
			--bind='ctrl-a:select-all,ctrl-x:deselect-all') || return
	[[ -n $out ]] || return

	local -a files=("${(@f)out}")
	${EDITOR:-nvim} -- "${files[@]}"
}

export OBSIDIAN_VAULT="$HOME/Documents/Obsidian Vault"

# on -- fuzzy-find a note in the Obsidian vault and open it in $EDITOR.
#   on            browse every note by title
#   on idempot    seed the query
#   alt-f         switch to full-text search; ripgrep re-runs on each keystroke
#   alt-n         switch back to titles
#   alt-o         open the highlighted note in the Obsidian app instead
#   Tab marks several notes and they all open at once.
#
# Two modes rather than one because they answer different questions: titles for
# "where did I put that", full text for "I know I wrote this phrase somewhere".
# The query carries across the switch, so a title search that comes up empty is
# one keystroke away from being retried against the bodies.
on() {
	local vault=$OBSIDIAN_VAULT
	[[ -d $vault ]] || { print -u2 "on: no vault at $vault"; return 1 }

	local helper=$HOME/.config/fzf/obsidian-note.sh

	# Titles come from fd, bodies from rg, both printing vault-relative paths so
	# the helper and the editor step below can treat the two modes alike.
	local titles='fd --type=f --extension=md'
	# Guard the empty query: `rg -- ""` matches every line of every note, which
	# is a wall of text, not a search. Excalidraw notes are markdown wrapped
	# round a drawing blob -- findable by title, but grepping them spews base64,
	# so they sit out the text mode; drop the -g to let them back in.
	local bodies='[ -n {q} ] && rg --column --line-number --no-heading --color=always --smart-case -g "!*.excalidraw.md" -- {q} || true'

	local out
	out=$(cd "$vault" && FZF_DEFAULT_COMMAND=$titles fzf \
		--ansi --multi --query="$*" \
		--height=80% \
		--prompt='◈ title ' \
		--header='alt-f full text · alt-n titles · alt-o obsidian · tab mark' \
		--preview="$helper preview {}" \
		--preview-window='right,60%,border-left,wrap' \
		--bind="start:unbind(change)" \
		--bind="alt-f:change-prompt(◈ text )+disable-search+reload($bodies)+rebind(change)" \
		--bind="change:reload:sleep 0.1; $bodies" \
		--bind="alt-n:unbind(change)+change-prompt(◈ title )+enable-search+reload($titles)" \
		--bind="alt-o:execute-silent($helper open {})+abort" \
		--bind='ctrl-a:select-all,ctrl-x:deselect-all') || return
	[[ -n $out ]] || return

	# fzf hands back the line as it read it, escape codes and all, and in text
	# mode that line is path:line:column:match -- so strip, then split.
	out=$(printf '%s\n' "$out" | sed $'s/\E\\[[0-9;]*m//g')

	local -a files=()
	local entry file jump=
	for entry in "${(@f)out}"; do
		if [[ $entry =~ '^(.+\.md):([0-9]+):' ]] && [[ -f $vault/$match[1] ]]; then
			file=$match[1]
			[[ -n $jump ]] || jump=$match[2]
		else
			file=$entry
		fi
		files+=("$vault/$file")
	done
	[[ ${#files} -gt 0 ]] || return

	# +N lands on the matched line, but only the first file gets a cursor
	# position; the rest open as a normal buffer list.
	if [[ -n $jump ]]; then
		${EDITOR:-nvim} "+$jump" -- "${files[@]}"
	else
		${EDITOR:-nvim} -- "${files[@]}"
	fi
}


# Yazi Setup
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}

# RUST Path
export PATH="$HOME/.cargo/bin:$PATH"

# Setting Xterm
export TERM=xterm-256color

# Adding typescript language server to PATH
export PATH="$PATH:$(npm prefix -g)/bin"

# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
export PATH="$PATH:$HOME/.rvm/bin"

# Load RVM into the shell session as a function
[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"


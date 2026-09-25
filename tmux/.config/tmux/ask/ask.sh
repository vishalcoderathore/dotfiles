#!/usr/bin/env bash
# Popup launcher (bound to prefix + a). First choose a mode:
#   terminal - a shell in the current pane's directory, inside a nested tmux
#              session named "popup". A real tmux pane answers terminal queries
#              (background color, emulator), which a bare popup doesn't; tools
#              like yazi otherwise lose their colors and stall on quit.
#   nvim     - ask an LLM harness a Neovim question; offers only the harnesses
#              installed on this machine and starts an interactive session in
#              this folder so it picks up AGENTS.md / CLAUDE.md.

# Icon + color per entry: terminal, Neovim logo, Claude's starburst (orange),
# Nerd Font robot for Codex
declare -A icons=([terminal]=$'' [nvim]=$'' [claude]=$'✻' [codex]=$'\U000F06A9')
declare -A colors=([terminal]=$'\e[37m' [nvim]=$'\e[32m' [claude]=$'\e[38;2;217;119;87m' [codex]=$'\e[37m')
declare -A labels=([terminal]="regular terminal" [nvim]="nvim question" [claude]="claude" [codex]="codex")
reset=$'\e[0m'

# pick PROMPT NAME... -> prints the chosen name, empty if cancelled.
# Each line is "name<TAB>icon label"; fzf shows only the second field.
pick() {
  local prompt=$1; shift
  for o in "$@"; do printf '%s\t%s%s%s %s\n' "$o" "${colors[$o]}" "${icons[$o]}" "$reset" "${labels[$o]}"; done |
    fzf --ansi --delimiter=$'\t' --with-nth=2 --prompt="$prompt: " --height=~10 --reverse |
    cut -f1
}

mode=$(pick "popup" terminal nvim)
case "$mode" in
  # destroy-unattached: the session dies with the popup, however it's closed
  terminal) exec env -u TMUX tmux new-session -s popup -c "$PWD" \; set destroy-unattached on ;;
  nvim) ;;
  *) exit 0 ;;
esac

options=()
command -v claude >/dev/null && options+=("claude")
command -v codex  >/dev/null && options+=("codex")

if [ ${#options[@]} -eq 0 ]; then
  read -n 1 -p "No harness found (claude/codex). Press any key..."
  exit 1
elif [ ${#options[@]} -eq 1 ]; then
  choice=${options[0]}
else
  choice=$(pick "harness" "${options[@]}")
  [ -z "$choice" ] && exit 0
fi

cd "$(dirname "$(readlink -f "$0")")" || exit 1

# \001 \002 mark the color codes as zero-width so readline editing stays aligned
read -e -p $'\001'"${colors[$choice]}"$'\002'"${icons[$choice]}"$'\001'"$reset"$'\002'" ask $choice: " q
[ -z "$q" ] && exit 0

exec "$choice" "$q"

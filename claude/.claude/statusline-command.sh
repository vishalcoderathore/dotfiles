#!/usr/bin/env bash
input=$(cat)

# ── Colors ────────────────────────────────────────────────────────────────────
RESET=$'\033[0m'
BOLD=$'\033[1m'
CYAN=$'\033[36m'
GREEN=$'\033[32m'
YELLOW=$'\033[33m'
MAGENTA=$'\033[35m'
BLUE=$'\033[34m'
RED=$'\033[31m'
DIM=$'\033[2m'
WHITE=$'\033[97m'
ESC=$'\033'
BEL=$'\007'

# ── Input fields ──────────────────────────────────────────────────────────────
user=$(whoami)
host=$(hostname -s)
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
[ -z "$cwd" ] && cwd=$(pwd)
cwd="${cwd/#$HOME/\~}"

model=$(echo "$input" | jq -r '.model.display_name // ""')

used=$(echo "$input"   | jq -r '.context_window.used_percentage // 0')
used_int=$(printf '%.0f' "$used")

cost=$(echo "$input"   | jq -r '.cost.total_cost_usd // 0')
cost_fmt=$(printf '$%.4f' "$cost")

dur_ms=$(echo "$input" | jq -r '.cost.total_duration_ms // 0')
dur_s=$(( ${dur_ms%.*} / 1000 ))
dur_fmt=$(printf '%dm%02ds' $((dur_s / 60)) $((dur_s % 60)))

lines_add=$(echo "$input" | jq -r '.cost.total_lines_added // 0')
lines_del=$(echo "$input" | jq -r '.cost.total_lines_removed // 0')

# ── Context progress bar (20 chars wide) ──────────────────────────────────────
BAR_WIDTH=20
filled=$(( used_int * BAR_WIDTH / 100 ))
empty=$(( BAR_WIDTH - filled ))
bar=""
for ((i=0; i<filled; i++)); do bar="${bar}▓"; done
for ((i=0; i<empty;  i++)); do bar="${bar}░"; done

# Color the bar: green < 60%, yellow < 85%, red >= 85%
if   (( used_int >= 85 )); then bar_color="$RED"
elif (( used_int >= 60 )); then bar_color="$YELLOW"
else                             bar_color="$GREEN"
fi

# ── Git info ──────────────────────────────────────────────────────────────────
git_part=""
if git -C "${cwd/#\~/$HOME}" rev-parse --git-dir > /dev/null 2>&1; then
  branch=$(git -C "${cwd/#\~/$HOME}" branch --show-current 2>/dev/null)
  [ -z "$branch" ] && branch=$(git -C "${cwd/#\~/$HOME}" rev-parse --short HEAD 2>/dev/null)

  staged=$(git   -C "${cwd/#\~/$HOME}" diff --cached --numstat 2>/dev/null | wc -l | tr -d ' ')
  modified=$(git -C "${cwd/#\~/$HOME}" diff          --numstat 2>/dev/null | wc -l | tr -d ' ')
  untracked=$(git -C "${cwd/#\~/$HOME}" ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')

  git_part=" ${DIM}│${RESET} 🌿 ${CYAN}${branch}${RESET}"
  (( staged   > 0 )) && git_part="${git_part} ${GREEN}✚${staged}${RESET}"
  (( modified > 0 )) && git_part="${git_part} ${YELLOW}✎${modified}${RESET}"
  (( untracked > 0 )) && git_part="${git_part} ${RED}?${untracked}${RESET}"

  # Clickable OSC 8 link to remote (if available)
  remote_url=$(git -C "${cwd/#\~/$HOME}" remote get-url origin 2>/dev/null)
  if [ -n "$remote_url" ]; then
    # Convert SSH → HTTPS
    remote_url=$(echo "$remote_url" \
      | sed 's|git@github\.com:|https://github.com/|' \
      | sed 's|\.git$||')
    repo_name=$(basename "$remote_url")
    git_part="${git_part} ${DIM}│${RESET} 🔗 ${ESC}]8;;${remote_url}${BEL}${BLUE}${repo_name}${RESET}${ESC}]8;;${BEL}"
  fi
fi

# ── Rate limits (Pro/Max only) ─────────────────────────────────────────────────
rate_part=""
five=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
week=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
if [ -n "$five" ] || [ -n "$week" ]; then
  rate_part=" ${DIM}│${RESET} 🚦"
  [ -n "$five" ] && rate_part="${rate_part} ${DIM}5h:$(printf '%.0f' "$five")%${RESET}"
  [ -n "$week" ] && rate_part="${rate_part} ${DIM}7d:$(printf '%.0f' "$week")%${RESET}"
fi

# ── Line 1: identity + cwd + git ──────────────────────────────────────────────
printf "${CYAN}%s${RESET}@${GREEN}%s${RESET}:${YELLOW}%s${RESET}" "$user" "$host" "$cwd"
[ -n "$model" ] && printf " ${DIM}│${RESET} 🤖 ${MAGENTA}${BOLD}%s${RESET}" "$model"
printf "%s\n" "$git_part"

# ── Line 2: context bar + cost + duration + lines ─────────────────────────────
printf "🧠 ${bar_color}%s${RESET} ${WHITE}%s%%${RESET}" "$bar" "$used_int"
printf "  ${DIM}│${RESET}  💰 ${GREEN}%s${RESET}" "$cost_fmt"
printf "  ${DIM}│${RESET}  ⏱ ${DIM}%s${RESET}" "$dur_fmt"
(( lines_add + lines_del > 0 )) && \
  printf "  ${DIM}│${RESET}  📝 ${GREEN}+%s${RESET} ${RED}-%s${RESET}" "$lines_add" "$lines_del"
printf "%s\n" "$rate_part"

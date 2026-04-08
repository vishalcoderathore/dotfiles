#!/usr/bin/env bash
input=$(cat)

user=$(whoami)
host=$(hostname -s)
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
[ -z "$cwd" ] && cwd=$(pwd)
# Abbreviate home directory with ~
cwd="${cwd/#$HOME/\~}"

model=$(echo "$input" | jq -r '.model.display_name // ""')

used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
ctx_part=""
if [ -n "$used" ]; then
  ctx_part=" | ctx:$(printf '%.0f' "$used")%"
fi

rate_part=""
five=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
week=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
if [ -n "$five" ] || [ -n "$week" ]; then
  rate_part=" |"
  [ -n "$five" ] && rate_part="$rate_part 5h:$(printf '%.0f' "$five")%"
  [ -n "$week" ] && rate_part="$rate_part 7d:$(printf '%.0f' "$week")%"
fi

printf "\033[36m%s\033[0m@\033[32m%s\033[0m:\033[33m%s\033[0m" "$user" "$host" "$cwd"
[ -n "$model" ] && printf " \033[35m[%s]\033[0m" "$model"
printf "%s%s\n" "$ctx_part" "$rate_part"

#!/usr/bin/env bash
# Helper for the `on` note picker. Called as: obsidian-note.sh <preview|open> {}
#
# The picker has two modes and they hand back different shapes of line, so
# rather than swapping commands mid-flight both are parsed here:
#   Concepts/Idempotency.md            (title mode) -> whole note
#   Concepts/Idempotency.md:42:retry   (text mode)  -> line 42 in context
# Paths are vault-relative because fzf runs with the vault as its cwd; the
# preview and execute-silent subshells do not inherit that, so $OBSIDIAN_VAULT
# anchors them again here.

set -u

action=${1:-preview}
line=${2:-}
[ -n "$line" ] || exit 0

vault=${OBSIDIAN_VAULT:-$HOME/Documents/Obsidian Vault}
cd "$vault" 2>/dev/null || exit 0

# ripgrep colours its output and fzf hands the line over with the escapes
# still in it, so strip them before anything is treated as a path.
plain=$(printf '%s' "$line" | sed 's/\x1b\[[0-9;]*m//g')

if [[ $plain =~ ^(.+\.md):([0-9]+): ]]; then
    file=${BASH_REMATCH[1]}
    lineno=${BASH_REMATCH[2]}
    # The match above is greedy, so a note quoting "other.md:12:" in its own
    # text would swallow the separator. Fall back to the leftmost candidate.
    if [ ! -f "$file" ] && [[ ${plain%%:[0-9]*} =~ \.md$ ]]; then
        file=${plain%%:[0-9]*}
        lineno=${plain#"$file":}
        lineno=${lineno%%:*}
    fi
else
    file=$plain
    lineno=
fi

[ -f "$file" ] || exit 0

if [ "$action" = open ]; then
    # Obsidian's URI scheme takes an absolute path, percent-encoded. The vault
    # is registered with the app, so it resolves to the right window.
    encoded=$(jq -rn --arg p "$PWD/$file" '$p|@uri' 2>/dev/null) || encoded=
    [ -n "$encoded" ] || exit 0
    xdg-open "obsidian://open?path=$encoded" >/dev/null 2>&1 &
    exit 0
fi

BAT=$(command -v batcat || command -v bat || true)

# A grep hit is about one line, so keep the numbers, mark the match and show
# enough either side to judge it without opening the note.
if [ -n "$lineno" ]; then
    from=$(( lineno > 12 ? lineno - 12 : 1 ))
    if [ -n "$BAT" ]; then
        "$BAT" --color=always --style=numbers --language=md \
               --highlight-line="$lineno" \
               --line-range="$from:$(( lineno + 40 ))" -- "$file"
    else
        sed -n "$from,$(( lineno + 40 ))p" -- "$file"
    fi
    exit 0
fi

# Title mode is for reading, so render the markdown rather than showing source.
# The head cap keeps an Excalidraw note (markdown wrapped round a drawing blob)
# from stalling the pane.
if command -v glow >/dev/null 2>&1; then
    head -n 400 -- "$file" | glow --style=dark --width="${FZF_PREVIEW_COLUMNS:-80}" -
elif [ -n "$BAT" ]; then
    "$BAT" --color=always --style=numbers --language=md --line-range=:400 -- "$file"
else
    head -n 400 -- "$file"
fi

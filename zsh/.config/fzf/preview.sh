#!/usr/bin/env bash
# Preview dispatcher for fzf. Called as: preview.sh {}
#
# fzf runs previews through `$SHELL -c`, which never sees the aliases and
# functions defined in .zshrc -- hence a real script rather than an inline
# snippet. Directories render as a shallow tree, text goes through bat, and
# everything else falls back to a description so the pane is never blank.

set -u

target=${1:-}
[ -n "$target" ] || exit 0

# Not a path (a history entry, a process line, a git branch): just echo it back
# so long lines are at least readable in the wrapped preview pane.
if [ ! -e "$target" ]; then
    printf '%s\n' "$target"
    exit 0
fi

# Debian/Ubuntu ship bat as `batcat`.
BAT=$(command -v batcat || command -v bat || true)

if [ -d "$target" ]; then
    if command -v lsd >/dev/null 2>&1; then
        lsd --tree --depth 2 --almost-all --color=always --group-directories-first -- "$target"
    else
        ls -lAh --color=always -- "$target"
    fi
    exit 0
fi

case "$(file --brief --dereference --mime -- "$target")" in
    text/* | *json* | *xml* | *javascript* | *x-shellscript* | inode/x-empty*)
        if [ -n "$BAT" ]; then
            "$BAT" --color=always --style=numbers,changes --line-range=:500 -- "$target"
        else
            head -n 500 -- "$target"
        fi
        ;;
    image/*)
        printf 'Image  %s\n' "$target"
        file --brief --dereference -- "$target"
        du -Lh -- "$target" 2>/dev/null | cut -f1 | sed 's/^/Size   /'
        ;;
    *)
        file --brief --dereference -- "$target"
        du -Lh -- "$target" 2>/dev/null | cut -f1 | sed 's/^/Size   /'
        ;;
esac

# Tmux Key Bindings

Prefix key: `Ctrl+a`

---

## Sessions

| Action | Key |
|---|---|
| New session | `tmux new -s <name>` |
| Attach to session | `tmux attach -t <name>` |
| List sessions | `tmux ls` |
| Detach from session | `prefix + d` |
| Switch session | `prefix + s` |
| Rename session | `prefix + $` |

---

## Windows

| Action | Key |
|---|---|
| New window | `prefix + c` |
| Switch to window | `prefix + 1/2/3...` |
| Next window | `prefix + n` |
| Previous window | `prefix + p` |
| Rename window | `prefix + ,` |
| Close window | `prefix + &` |

---

## Panes

| Action | Key |
|---|---|
| Split vertically | `prefix + \|` |
| Split horizontally | `prefix + -` |
| Navigate panes | `prefix + h/j/k/l` |
| Resize pane left | `prefix + H` |
| Resize pane down | `prefix + J` |
| Resize pane up | `prefix + K` |
| Resize pane right | `prefix + L` |
| Zoom pane (toggle fullscreen) | `prefix + z` |
| Close pane | `prefix + x` |

---

## General

| Action | Key |
|---|---|
| Reload config | `prefix + r` |
| Command prompt | `prefix + :` |
| Scroll mode | `prefix + [` (use arrow keys or j/k, q to exit) |

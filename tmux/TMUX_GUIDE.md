# Tmux Guide

A practical reference for getting comfortable with tmux day to day.

---

## What is tmux?

tmux is a terminal multiplexer. It lets you:
- Split one terminal window into multiple panes
- Run multiple windows inside one terminal session
- Detach from a session and come back to it later (even after closing the terminal)
- Keep processes running on a remote server after you disconnect

**The prefix key for this config is `Ctrl+a`**
Every tmux shortcut starts with the prefix, then another key.

---

## Sessions

A session is the top-level container. Think of it as a workspace. You can have multiple sessions, each with their own windows and panes.

| Action | Command |
|---|---|
| Start a new named session | `tmux new -s <name>` |
| Attach to an existing session | `tmux attach -t <name>` |
| List all sessions | `tmux ls` |
| Detach from session (keeps it running) | `prefix + d` |
| Switch between sessions | `prefix + s` |
| Rename current session | `prefix + $` |
| Kill a session | `tmux kill-session -t <name>` |

**Tip:** Always name your sessions. `tmux new -s work` is much easier to come back to than `tmux attach -t 0`.

---

## Windows

A window is like a tab. Each session can have multiple windows.

| Action | Key |
|---|---|
| New window (opens in current directory) | `prefix + c` |
| Switch to window by number | `prefix + 1 / 2 / 3 ...` |
| Next window | `prefix + n` |
| Previous window | `prefix + p` |
| Rename current window | `prefix + ,` |
| Close current window | `prefix + &` |

---

## Panes

A pane is a split within a window. This is where you spend most of your time.

| Action | Key |
|---|---|
| Split vertically (side by side) | `prefix + \|` |
| Split horizontally (top/bottom) | `prefix + -` |
| Navigate panes | `prefix + h / j / k / l` |
| Zoom pane (toggle fullscreen) | `prefix + z` |
| Resize pane | `prefix + H / J / K / L` |
| Close pane | `prefix + x` |
| Show pane numbers | `prefix + q` |
| Convert pane to window | `prefix + !` |

**Tip:** Zoom (`prefix + z`) is great when you need to focus on one pane temporarily. Press it again to zoom back out. The `[Z]` indicator in the status bar tells you when a pane is zoomed.

---

## Copy Mode (Scrolling)

Copy mode lets you scroll through the terminal history and copy text.

| Action | Key |
|---|---|
| Enter copy mode | `prefix + [` |
| Scroll up/down | Arrow keys or `j` / `k` |
| Search upward | `?` |
| Search downward | `/` |
| Start selection | `Space` |
| Copy selection | `Enter` |
| Exit copy mode | `q` |

**Tip:** You can also scroll with the mouse since mouse mode is enabled.

---

## Plugins

Plugins are managed by **TPM** (Tmux Plugin Manager).

| Action | Key |
|---|---|
| Install plugins | `prefix + I` (capital i) |
| Update plugins | `prefix + U` |
| Remove unlisted plugins | `prefix + Alt + u` |

### Installed Plugins

**tmux-sensible** — applies a set of sane defaults automatically.

**catppuccin/tmux** — Catppuccin Mocha theme for the status bar.

**tmux-resurrect** — manually save and restore sessions.

| Action | Key |
|---|---|
| Save session | `prefix + Ctrl+s` |
| Restore session | `prefix + Ctrl+r` |

**tmux-continuum** — automatically saves your session every 10 minutes and restores it when tmux starts. Works silently in the background — nothing to do.

---

## General

| Action | Key |
|---|---|
| Reload config | `prefix + r` |
| Command prompt | `prefix + :` |
| Show all keybindings | `prefix + ?` |

---

## Status Bar

The status bar shows (left to right):
- **Session name** — which workspace you are in
- **Window count** — how many windows are in this session
- **[Z]** — appears when a pane is zoomed (fullscreen)
- **IP address** — current machine's IP (useful when SSHed into a server)
- **Date and time**
- **Hostname** — which machine you are on

---

## Typical Workflow

### On your local machine
```bash
# Start a named session
tmux new -s dev

# Split into panes: editor on the left, terminal on the right
prefix + |

# Navigate between panes
prefix + h / l

# Detach when done (session keeps running)
prefix + d

# Come back later
tmux attach -t dev
```

### SSHing into an EC2 server
```bash
# SSH into your server
ssh user@your-ec2-ip

# Start or attach to a tmux session on the server
tmux new -s server
# or
tmux attach -t server

# Now if your SSH connection drops, your session is still running on the server
# Just SSH back in and run: tmux attach -t server
```

**This is the main reason to use tmux on a remote server** — if your connection drops, your work keeps running and you can pick up exactly where you left off.

---

## Quick Reference Card

```
prefix = Ctrl+a

Sessions        Windows         Panes
─────────       ───────         ─────
d  detach       c  new          |  split vertical
s  switch       n  next         -  split horizontal
$  rename       p  prev         h/j/k/l  navigate
                ,  rename       H/J/K/L  resize
                &  close        z  zoom toggle
                                x  close

General
───────
r  reload config
[  scroll/copy mode
?  list all keys
```

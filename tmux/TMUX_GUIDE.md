# tmux — A User Guide

A learning guide for this config. Start at the top and work down; each section builds on the one before it.

**Prefix key: `Ctrl+s`** — config lives at `~/.config/tmux/tmux.conf`, symlinked from this repo by stow.

---

## Contents

| Section | What it covers |
|---|---|
| [1. What tmux is for](#1-what-tmux-is-for) | Why bother |
| [2. The mental model](#2-the-mental-model) | Sessions, windows, panes |
| [3. The prefix key](#3-the-prefix-key) | How every shortcut works |
| [4. Your first session](#4-your-first-session) | Getting started |
| [5. Panes](#5-panes) | Splitting the screen |
| [6. Windows](#6-windows) | Tabs |
| [7. Sessions](#7-sessions) | Detach and reattach |
| [8. Copy mode](#8-copy-mode) | Scrolling and copying |
| [9. Reading the status bar](#9-reading-the-status-bar) | What's on screen |
| [10. Plugins](#10-plugins) | What's installed |
| [11. Workflows](#11-workflows) | Putting it together |
| [12. Gotchas](#12-gotchas) | When something looks wrong |
| [13. Quick reference](#13-quick-reference) | The cheat sheet |

---

## 1. What tmux is for

tmux is a terminal multiplexer. One terminal window becomes many.

| Problem | What tmux does |
|---|---|
| You need an editor and a server log side by side | Split one window into panes |
| You close your terminal and lose everything | Detach instead — the session keeps running |
| Your SSH connection drops mid-build | The build survives on the server; reattach and it's still there |
| You juggle three projects in three terminal tabs | One named session per project |

That fourth row is the one that changes how you work. The third is the one that saves you.

---

## 2. The mental model

Everything in tmux is three nested things. Learn this and the rest follows:

```
Session  "dev"                      ← a workspace, survives terminal close
└── Window 1  "editor"              ← like a browser tab
    ├── Pane 1   nvim               ← a split within the tab
    └── Pane 2   zsh
└── Window 2  "server"
    └── Pane 1   npm run dev
```

| Level | Think of it as | You typically have |
|---|---|---|
| **Session** | A project or workspace | One per project |
| **Window** | A tab | A few per session |
| **Pane** | A split within a tab | Two or three per window |

Panes live inside windows; windows live inside sessions. Splitting the screen adds a **pane**, not a window — which is why your status bar still shows one entry after a split.

---

## 3. The prefix key

Every tmux shortcut is **two keystrokes**, not one chord:

1. Tap **`Ctrl+s`** and let go — this arms tmux for the next key
2. Press the command key

Written `prefix + x` throughout this guide, meaning: `Ctrl+s`, release, then `x`.

The common beginner mistake is holding `Ctrl` while pressing the second key. Tap, release, then press.

The prefix exists so tmux commands never collide with your shell or editor. Without it, tmux would swallow keys your programs need.

> **One exception in this config:** `Ctrl+h/j/k/l` move between panes with **no prefix**. See [Panes](#5-panes).

---

## 4. Your first session

```bash
tmux new -s dev      # start a session named "dev"
```

You'll know it worked when the Catppuccin status bar appears at the top of the screen.

| Command | What it does |
|---|---|
| `tmux new -s <name>` | Start a named session |
| `tmux` | Start an unnamed session (called `0`) |
| `tmux ls` | List running sessions |
| `tmux attach -t <name>` | Reattach to a session |
| `tmux kill-session -t <name>` | Destroy a session |

**Always name your sessions.** `tmux attach -t api` is something you can remember a day later; `tmux attach -t 0` is not.

---

## 5. Panes

A pane is a split within a window. This is where you spend most of your time.

### Creating

| Action | Keys | Result |
|---|---|---|
| Split vertically | `prefix + \|` | Two panes side by side |
| Split horizontally | `prefix + -` | Two panes stacked |

The symbol matches the divider you get: `|` gives a vertical line, `-` a horizontal one. New panes open in the **same directory** you were already in.

### Navigating

| Action | Keys |
|---|---|
| Move left / down / up / right | `Ctrl+h` `Ctrl+j` `Ctrl+k` `Ctrl+l` |
| Same, tmux-only | `prefix + h/j/k/l` |
| Show pane numbers | `prefix + q` |

**`Ctrl+h/j/k/l` needs no prefix.** It also crosses into Neovim splits — tmux detects that a pane is running Neovim and hands the key over instead of switching panes. So the same four keys move you around your whole screen, editor splits included, with no mental gear change at the border. That's the `vim-tmux-navigator` plugin, and it requires its Neovim counterpart (`nvim/.config/nvim/lua/plugins/tmux-navigator.lua`) to work in both directions.

### Managing

| Action | Keys |
|---|---|
| Zoom pane to fullscreen (toggle) | `prefix + z` |
| Resize left / down / up / right | `prefix + H/J/K/L` |
| Close pane | `prefix + x` then `y`, or just `exit` |
| Convert pane into its own window | `prefix + !` |
| Cycle through layouts | `prefix + Space` |

**`prefix + z` is the one you'll use constantly.** Split to keep context visible, zoom when you need to focus, unzoom when you're done. The `[Z]` in the status bar tells you a pane is zoomed — worth knowing, because a zoomed pane looks exactly like a window with no splits.

---

## 6. Windows

A window is a tab. Each fills the whole screen and holds its own panes.

| Action | Keys |
|---|---|
| New window | `prefix + c` |
| Next / previous window | `prefix + n` / `prefix + p` |
| Jump to window by number | `prefix + 1`, `prefix + 2`, ... |
| Pick from a list | `prefix + w` |
| Rename current window | `prefix + ,` |
| Close window | `prefix + &` then `y` |

Windows are numbered from **1** in this config, not the tmux default of 0 — so the numbers match the keyboard. New windows open in your current directory.

Reach for a window when the work is genuinely separate (a different service, a different repo). Reach for a pane when you need to see two things at once.

---

## 7. Sessions

A session is the outermost container, and the reason tmux matters.

| Action | Keys / Command |
|---|---|
| Detach (leave it running) | `prefix + d` |
| Reattach | `tmux attach -t dev` |
| Switch between sessions | `prefix + s` |
| Rename session | `prefix + $` |
| List sessions | `tmux ls` |

**Detaching is not quitting.** `prefix + d` returns you to your normal shell while everything in the session keeps running — servers stay up, builds keep going. Close the terminal entirely and the session still survives. Reattach whenever, and it's exactly as you left it.

This is also what makes tmux essential over SSH:

```bash
ssh user@server
tmux new -s deploy      # start work inside tmux
# connection drops...
ssh user@server
tmux attach -t deploy   # everything still running
```

Without tmux, a dropped connection kills whatever was running. With it, the work is untouched.

---

## 8. Copy mode

Copy mode is how you scroll back through output and copy text. This config uses **vi keys**.

| Action | Keys |
|---|---|
| Enter copy mode | `prefix + [` |
| Move around | `h/j/k/l`, `w`, `b` |
| Jump to top / bottom | `gg` / `G` |
| Search down / up | `/` / `?` |
| Start selecting | `Space` |
| Block (rectangle) selection | `v` |
| Copy and exit | `Enter` |
| Exit without copying | `q` |

Mouse mode is on, so **scrolling with the wheel drops you into copy mode automatically**. That surprises people — if your scroll wheel stops doing what you expect, press `q` to get out. Scrollback holds 10,000 lines.

---

## 9. Reading the status bar

The bar sits at the **top** and is transparent, inheriting your terminal background.

| Position | Shows | Example |
|---|---|---|
| Left | Session name | `dev` |
| Left | Window count | `1 windows` |
| Middle | Window list — current one highlighted | `zsh in dotfiles` |
| Right | `[Z]` when a pane is zoomed | `[Z]` |
| Right | Machine's IP address | `192.168.178.48` |
| Right | Date and time | `Sat 12 Sep 14:19` |
| Right | Hostname | `pop-os` |

Two things that commonly confuse people here:

**The window list shows windows, not panes.** Split the screen and it stays one entry. Press `prefix + c` and a second appears.

**The hostname is your machine's name, not your OS.** It reads like an OS here only because the machine is named after the distro. Its real value shows when you SSH somewhere — the bar tells you which box you're on.

---

## 10. Plugins

Managed by **TPM**, installed to `~/.tmux/plugins/`.

| Action | Keys |
|---|---|
| Install plugins listed in the config | `prefix + I` (capital i) |
| Update all plugins | `prefix + U` |
| Remove plugins no longer listed | `prefix + Alt+u` |

### What's installed

| Plugin | What it gives you |
|---|---|
| **tpm** | The plugin manager itself |
| **tmux-sensible** | Sane defaults everyone agrees on |
| **vim-tmux-navigator** | `Ctrl+h/j/k/l` across tmux panes and Neovim splits |
| **catppuccin/tmux** | The Mocha theme on the status bar |
| **tmux-resurrect** | Save and restore sessions by hand |
| **tmux-continuum** | Autosaves every 10 minutes, restores on start |

### Saving and restoring sessions

| Action | Keys |
|---|---|
| Save now | `prefix + Ctrl+s` (i.e. `Ctrl+s Ctrl+s`) |
| Restore last save | `prefix + Ctrl+r` |

Continuum handles this automatically, so you rarely need the manual keys. Pane contents are captured too, not just the layout.

> The config pins `TMUX_PLUGIN_MANAGER_PATH` to `~/.tmux/plugins/` on purpose. Left at its default, TPM installs to `~/.config/tmux/plugins/` — which stow symlinks back into this repo, dumping megabytes of plugin checkouts into version control.

---

## 11. Workflows

### Starting a project

```bash
tmux new -s api           # name it after the project
# prefix + |              → split: editor left, shell right
# Ctrl+l                  → move to the right pane
npm run dev               # start the server there
# Ctrl+h                  → back to the left pane
nvim .                    # edit, with the server still visible
# Ctrl+l / Ctrl+h         → hop between nvim and the shell freely
# prefix + d              → detach, everything keeps running
```

Later:

```bash
tmux attach -t api        # exactly as you left it
```

### Focusing on one thing

Split panes are for context, not for cramming. When you need to concentrate, `prefix + z` to zoom, work, then `prefix + z` again to bring the context back. Nothing is lost while zoomed.

### Working on a server

```bash
ssh user@server
tmux new -s deploy        # or: tmux attach -t deploy
```

Start tmux *first thing* after connecting, before you run anything long. That way a dropped connection costs nothing.

---

## 12. Gotchas

| What you see | What's happening |
|---|---|
| "tmux-resurrect file not found" on startup | Nothing has been saved yet. Press `Ctrl+s Ctrl+s` once, or wait 10 minutes for the autosave. It stops after that. |
| Shortcuts do nothing | You're holding `Ctrl` for the second key. Tap `Ctrl+s`, **release**, then press the key. |
| Scroll wheel acts strangely | You're in copy mode. Press `q`. |
| Config changes have no effect | Reload with `prefix + r`. Some options need a fully new session. |
| Split looks like it vanished | You may be zoomed. Look for `[Z]` on the right, press `prefix + z`. |
| `Ctrl+h/j/k/l` stops at Neovim's edge | The Neovim half of `vim-tmux-navigator` is missing or didn't load. |
| Colours look flat or wrong | The terminal isn't advertising truecolor. This config sets `tmux-256color` with an RGB override. |
| `Ctrl+s` freezes your terminal **outside** tmux | That's the shell's legacy flow control (XOFF), unrelated to tmux. `Ctrl+q` unfreezes it; `stty -ixon` in `.zshrc` disables it for good. |

### Reloading after an edit

```
prefix + r
```

Shows "Config reloaded!" when it works.

---

## 13. Quick reference

```
prefix = Ctrl+s   (tap and release, then the next key)

PANES                           WINDOWS
─────                           ───────
prefix |    split vertical      prefix c    new window
prefix -    split horizontal    prefix n    next
prefix z    zoom toggle         prefix p    previous
prefix x    close               prefix 1-9  jump to number
prefix H/J/K/L  resize          prefix w    list windows
prefix q    show numbers        prefix ,    rename
prefix !    pane → window       prefix &    close window

NO PREFIX                       SESSIONS
─────────                       ────────
Ctrl+h  left   (+ nvim)         prefix d    detach
Ctrl+j  down   (+ nvim)         prefix s    switch session
Ctrl+k  up     (+ nvim)         prefix $    rename session
Ctrl+l  right  (+ nvim)         tmux ls     list
                                tmux attach -t <name>

COPY MODE                       PLUGINS
─────────                       ───────
prefix [    enter               prefix I        install
/  ?        search down/up      prefix U        update
Space       start selection     prefix Ctrl+s   save session
v           block selection     prefix Ctrl+r   restore session
Enter       copy and exit
q           exit                GENERAL
gg / G      top / bottom        ───────
                                prefix r    reload config
                                prefix :    command prompt
                                prefix ?    list every binding
```

**`prefix + ?` lists every active binding** — the authoritative answer when this guide and the config disagree.

---

## Running this config elsewhere

tmux is POSIX-only, so there's no native Windows build. On Windows, use **WSL2** — install a distro, `apt install tmux stow`, clone this repo and stow it. The config itself is portable and needs no changes. Point WezTerm at it with `config.default_domain = 'WSL:Ubuntu'`.

Two things behave differently under WSL2: the status bar's IP shows the WSL VM's internal NAT address rather than your LAN IP, and copying to the Windows clipboard needs output piped through `clip.exe`.

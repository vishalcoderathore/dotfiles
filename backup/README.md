# backup — pCloud → external drive mirror

One-way backup of a pCloud account onto an external drive, using
[rclone](https://rclone.org). Run by hand, whenever the drive is plugged in.

```
pcloud-backup            # sync
pcloud-backup --dry-run  # preview, writes nothing
pcloud-backup --verify   # full checksum audit (slow)
```

> **Scope.** This mirrors a cloud account onto a disk. It is not a system imager
> and will not restore an OS. Machine-specific recovery notes (disk layout,
> hardware, what to reinstall) deliberately live on the backup drive itself as
> `backup-context.md`, not in this public repo.

---

## Install on a fresh machine

### 1. rclone

Distro packages lag badly — Ubuntu 24.04 ships 1.60 (2022). Get the current build:

```bash
curl -fsSL -o /tmp/rclone.zip https://downloads.rclone.org/rclone-current-linux-amd64.zip
unzip -q /tmp/rclone.zip -d /tmp
install -Dm755 /tmp/rclone-v*/rclone ~/.local/bin/rclone
```

### 2. Point rclone at the right pCloud region

**This is the step that wastes an afternoon if you get it wrong.** pCloud runs
separate US and EU stacks. rclone defaults to the US endpoint
(`api.pcloud.com`); an EU account authenticating against it fails with an
opaque auth error rather than anything that names the real problem.

This setup is on the **EU** stack:

```bash
rclone config create pcloud pcloud hostname eapi.pcloud.com --non-interactive
rclone config reconnect pcloud:      # opens a browser
```

To re-derive the region on a machine that still has the pCloud desktop client,
its own database records it:

```bash
sqlite3 "file:$HOME/.pcloud/data.db?immutable=1" \
  "select id, value from setting where id in ('api_server','location_id');"
```

`location_id = 2` and an `api_server` beginning `bin**e**api.` both mean EU. For
a US account, drop the `hostname` line and use the default.

### 3. Stow the script

```bash
git clone git@github.com:vishalcoderathore/dotfiles.git ~/dotfiles
cd ~/dotfiles && stow backup
```

Puts `pcloud-backup` at `~/.local/bin/pcloud-backup`. Make sure that directory
is on `$PATH`.

---

## Layout it produces

| Path | Contents |
|---|---|
| `<drive>/pcloud/` | Exact mirror of the pCloud root |
| `<drive>/pcloud-archive/YYYY-MM-DD/` | Files deleted or overwritten on pCloud that day |
| `<drive>/backup-context.md` | Machine-specific recovery notes (not in this repo) |

Defaults to `/media/$USER/Backup`. Override with `PCLOUD_BACKUP_ROOT` and
`PCLOUD_BACKUP_LABEL`. Throttle with `PCLOUD_BWLIMIT=10M`.

Logs land in `~/.local/share/pcloud-backup/logs/`, last 30 runs kept.

---

## Design decisions

**One-way, always.** pCloud is the source of truth; the drive never writes back
during normal operation. A two-way sync means a stale or damaged mirror can
propagate destruction upward into live data.

**Deletions are archived, not applied.** `--backup-dir` diverts anything the
sync would delete or overwrite into `pcloud-archive/<date>/`. Without this, a
mirror faithfully reproduces your mistakes: delete a folder by accident, run the
sync, and the backup dutifully erases its own copy. Costs disk space, buys an
undo history.

**It refuses to run unless the target is verified.** Two checks: the destination
must be a real mountpoint, *and* the underlying block device must carry the
expected filesystem label.

```bash
mountpoint -q "$DEST_ROOT"                  # is anything mounted here?
lsblk -no LABEL "$(findmnt -no SOURCE ...)" # is it the right disk?
```

The mountpoint check matters more than it looks. With the drive unplugged,
`/media/$USER/Backup` reverts to an ordinary empty directory on the root
filesystem — a sync would cheerfully write the entire cloud account onto the
system disk until it filled. The label check catches the other case: some *other*
removable disk mounted where the backup drive usually goes.

**One run at a time.** `flock` on `~/.local/share/pcloud-backup/lock`. Two
concurrent syncs sharing an archive directory corrupt each other's history.

**Fast by default, thorough on request.** Normal runs compare size and mtime, so
an unchanged run is quick. `--verify` does a full checksum comparison, which
reads every byte back off the drive — an occasional audit, not a routine.

---

## exFAT caveats

exFAT is used for cross-platform readability, and it constrains things:

- **Illegal filename characters.** exFAT rejects `\ : ? * | < > "` and trailing
  dots/spaces. rclone substitutes full-width Unicode lookalikes on write and
  reverses them on read, via `--local-encoding`. **Restore with rclone, not
  `cp`** — otherwise the substituted names stay mangled.
- **No journal.** Do not unplug mid-sync; unmount cleanly.
- **No permissions, ownership, or symlinks.** A data backup, not a bit-exact
  clone.
- **Timestamp granularity** is coarse, hence `--modify-window 1s`.

Repair with `fsck.exfat`, addressing the disk by UUID rather than `/dev/sdX`
(the letter changes between boots).

---

## Restoring

```bash
# pull the mirror back to a local directory
rclone copy <drive>/pcloud ~/restored --progress

# find and recover a single deleted file
find <drive>/pcloud-archive -iname '*fragment*'
rclone copy "<drive>/pcloud-archive/2026-08-16/Work/report.docx" ~/

# push back up to a repaired or empty pCloud account
rclone copy <drive>/pcloud pcloud: --progress
```

Use `rclone copy`, **never `sync`**, when restoring *into* pCloud. `sync` makes
the destination match the source, so an out-of-date mirror would delete live
files that are newer than the backup.

---

## Not covered by this backup

- **pCloud Crypto folder.** Client-side encrypted; the API cannot read it and it
  is excluded outright. It is recoverable only from pCloud with the Crypto
  passphrase, which cannot be reset by pCloud support. Back it up separately,
  by hand, while unlocked.
- **Credentials of any kind** — SSH keys, GPG keyring, cloud provider configs,
  the rclone OAuth token itself. Deliberately excluded: the drive is
  unencrypted and portable. Restoring these always requires a human. For a
  drive that *should* hold secrets, put them behind an `rclone crypt` remote or
  a LUKS volume first.
- **Anything on the machine that was never in pCloud.** The sync covers the
  cloud account only.

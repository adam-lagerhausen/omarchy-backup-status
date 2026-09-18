# Backup Status

An Omarchy bar widget for the four-hour database backup and the nightly home archive. It reads systemd user units and local STATUS files. It never loads Borg credentials or talks to BorgBase.

This is unofficial and not affiliated with Omarchy.

## Install

```
omarchy plugin add https://github.com/adam-lagerhausen/omarchy-backup-status.git --enable
```

The chip lands on the right of the bar. Left-click opens the panel. Right-click refreshes. Escape closes it. `R` refreshes while the panel is open.

```
omarchy bar move io.github.adam-lagerhausen.backup-status --section right
```

## What it shows

The icon stays in the theme foreground while both jobs are healthy. It turns red if anything is wrong: a failed job, a missing timer, an overdue run, lingering off, or the repo over 90% of quota. A run in progress pulses in accent.

The panel lists:

- BorgBase unique size against a 250 GB quota
- The four-hour `database-backup` job
- The nightly `workstation-backup` job
- Notes for collation warnings, BorgBase slot waits, lingering, and failures

## What it reads

- `database-backup.timer` / `database-backup.service`
- `workstation-backup.timer` / `workstation-backup.service`
- `~/.local/state/workstation-backup/STATUS`
- `~/.local/state/database-backup/staging/backup.log`
- the user journal for those two units
- `loginctl` lingering

## Configure

```
omarchy bar set io.github.adam-lagerhausen.backup-status barStyle pip
omarchy bar set io.github.adam-lagerhausen.backup-status quotaGb 250
omarchy bar set io.github.adam-lagerhausen.backup-status refreshIntervalSec 60
```

`barStyle` is `icon` (default), `pip`, or `label`.

## Remove

```
omarchy plugin remove io.github.adam-lagerhausen.backup-status
```

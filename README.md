<p align="right"><a href="./README.zh-CN.md">简体中文</a></p>

# inkwell

[![Latest release](https://img.shields.io/github/v/release/jiachliu666/inkwell)](../../releases/latest)
[![Downloads](https://img.shields.io/github/downloads/jiachliu666/inkwell/total)](../../releases)
[![Platform](https://img.shields.io/badge/platform-reMarkable%202%20%7C%20Paper%20Pro-blue)](../../releases)
[![License](https://img.shields.io/github/license/jiachliu666/inkwell)](./LICENSE)

**rm-agent** turns your reMarkable tablet into one that writes back.

Tap a corner of the page with the pen and it answers your handwritten
question, or sketches whatever you asked it to draw — using the tablet's own
pen digitizer, so the reply looks and feels like real ink, not an imported
image. Runs on both the **reMarkable 2** and the **reMarkable Paper Pro**.

## Features

- **Tap to ask** — tap the corner icon to have a handwritten question
  answered.
- **Real pen strokes, not an import** — replies are replayed as actual pen
  digitizer events, starting exactly where you last touched the page, so
  they show up as native ink.
- **Context-aware, without re-reading the whole page** — each round diffs
  the new screenshot against the one right after the last reply, and sends
  Gemini the full page with the *new* content outlined in a red box —
  keeping surrounding context (e.g. a diagram your question refers to)
  without diluting the prompt with old, already-answered material. Erased
  content is ignored, so cleaning up old writing never confuses the diff.
- **No PC, no cables** — runs entirely on-device as a background service; no
  syncing to a computer or import step required.
- **Starts on boot** — installed as a systemd service that starts after the
  reMarkable's own UI and restarts automatically if it crashes, including
  automatically refreshing its login session if the device stays on for
  days at a stretch.

## Demo

![Demo](./demo.gif)

Watch rm-agent answer a handwritten question and sketch a drawing request,
both written back in the tablet's own pen strokes (recorded on a reMarkable 2).

## Download

This repo holds no source code — only compiled `rm-agent` binaries. Grab the
latest release for your device from the [Releases](../../releases) page:

| Device | Binary | Extra files needed |
| --- | --- | --- |
| reMarkable 2 | `rm-agent-*-armv7-unknown-linux-musleabihf` | `rm-agent.service`, `rm-agent.env.example` |
| reMarkable Paper Pro | `rm-agent-*-aarch64-unknown-linux-musl` | `rm-agent-paperpro.service`, `goMarkableStream.service`, `rm-agent.env.example` |

## Installation — reMarkable 2

The binary is compiled for the reMarkable 2 itself (ARM, musl libc) — it
does **not** run on your Mac or PC directly. Download it there, then copy it
onto the tablet over SSH and set it up as a background service.

Before you start:

- Enable SSH on the reMarkable: **Settings → About → Copyrights and
  licenses** shows the device's root password. Also note its IP address
  from **Settings → About → General** (or check your router).
- Get a [Gemini API key](https://aistudio.google.com/apikey) with access to
  an image-generation-capable model.

### On macOS

```sh
# 1. copy the binary and service files to the device
scp rm-agent-*-armv7-unknown-linux-musleabihf remarkable:/home/root/rm-agent
scp rm-agent.service remarkable:/etc/systemd/system/rm-agent.service
scp rm-agent.env.example remarkable:/home/root/.config/rm-agent.env

# (if `remarkable` isn't a configured SSH host alias, use root@<device-ip> instead)

# 2. make it executable and fill in your API key
ssh remarkable 'chmod +x /home/root/rm-agent'
ssh remarkable 'vi /home/root/.config/rm-agent.env'   # set GEMINI_API_KEY

# 3. enable and start the service
ssh remarkable 'systemctl daemon-reload && systemctl enable --now rm-agent.service'
```

### On Windows

Windows 10/11 ship an OpenSSH client, so the same `scp`/`ssh` commands work
from PowerShell — just use the device's IP address instead of an SSH alias
(unless you've set one up in `~/.ssh/config`):

```powershell
# 1. copy the binary and service files to the device
scp rm-agent-*-armv7-unknown-linux-musleabihf root@<device-ip>:/home/root/rm-agent
scp rm-agent.service root@<device-ip>:/etc/systemd/system/rm-agent.service
scp rm-agent.env.example root@<device-ip>:/home/root/.config/rm-agent.env

# 2. make it executable and fill in your API key
ssh root@<device-ip> "chmod +x /home/root/rm-agent"
ssh root@<device-ip> "vi /home/root/.config/rm-agent.env"   # set GEMINI_API_KEY

# 3. enable and start the service
ssh root@<device-ip> "systemctl daemon-reload && systemctl enable --now rm-agent.service"
```

If `scp`/`ssh` aren't recognized, enable them under **Settings → Apps →
Optional features → OpenSSH Client**, or use an SFTP client like WinSCP
instead for the file transfer.

### Verify it's running

```sh
ssh remarkable 'systemctl status rm-agent'
ssh remarkable 'journalctl -u rm-agent -f'
```

Then tap the bottom-left corner of the screen with the pen to ask a
question.

## Installation — reMarkable Paper Pro

Paper Pro support needs a couple of things the reMarkable 2 doesn't:

- **[goMarkableStream](https://github.com/owulveryck/goMarkableStream)** — a
  third-party tool rm-agent relies on for the screenshot/login API (xochitl
  doesn't expose one natively). Download the `gomarkablestream-RMPRO` asset
  from its [releases page](https://github.com/owulveryck/goMarkableStream/releases).
- A different way of making services survive a reboot. On Paper Pro, `/etc`
  is a *volatile* overlay filesystem that resets on every boot — anything
  dropped into `/etc/systemd/system` disappears on restart. Unit files need
  to go in `/lib/systemd/system` instead (alongside xochitl's own), which
  means briefly remounting the normally-read-only root filesystem
  read-write to install them.

Before you start:

- Enable Developer Mode: **Settings → General → Paper Tablet → Software →
  Advanced → Developer Mode** (this resets the device and re-runs the
  onboarding steps).
- Get the root password: **Settings → General → Help → About → Copyrights
  and licenses**, scroll to the GPLv3 Compliance section.
- SSH is USB-only by default. Connect via USB, then SSH to `10.11.99.1`
  with the password above. Once in, run `rm-ssh-over-wlan on` to enable SSH
  over WiFi too (convenient for everything after this).
- Get a [Gemini API key](https://aistudio.google.com/apikey) with access to
  an image-generation-capable model.

### 1. Install goMarkableStream

```sh
scp gomarkablestream-RMPRO root@<device-ip>:/home/root/goMarkableStream
scp goMarkableStream.service root@<device-ip>:/lib/systemd/system/goMarkableStream.service
ssh root@<device-ip> 'chmod +x /home/root/goMarkableStream'
```

### 2. Install rm-agent

```sh
scp rm-agent-*-aarch64-unknown-linux-musl root@<device-ip>:/home/root/rm-agent
scp rm-agent-paperpro.service root@<device-ip>:/lib/systemd/system/rm-agent.service
scp rm-agent.env.example root@<device-ip>:/home/root/.config/rm-agent.env
ssh root@<device-ip> 'chmod +x /home/root/rm-agent'
ssh root@<device-ip> 'vi /home/root/.config/rm-agent.env'   # set GEMINI_API_KEY
```

### 3. Wire both services to start on boot

This is the part that's different from the reMarkable 2: the enablement
symlinks need to live on the *persistent* filesystem, so they're created
under `xochitl.service.wants/` in `/lib` instead of the usual `/etc` path.

```sh
ssh root@<device-ip> '
mount -o remount,rw /
mkdir -p /lib/systemd/system/xochitl.service.wants
ln -sf /lib/systemd/system/goMarkableStream.service /lib/systemd/system/xochitl.service.wants/goMarkableStream.service
ln -sf /lib/systemd/system/rm-agent.service /lib/systemd/system/xochitl.service.wants/rm-agent.service
mount -o remount,ro /
systemctl daemon-reload
systemctl enable --now goMarkableStream.service
systemctl enable --now rm-agent.service
'
```

### Verify it's running

```sh
ssh root@<device-ip> 'systemctl status goMarkableStream rm-agent'
ssh root@<device-ip> 'journalctl -u rm-agent -f'
```

Both services should say `active (running)`. A reboot test is worthwhile
the first time — `ssh root@<device-ip> reboot`, wait for it to come back,
then re-run the status check above.

Then tap the corner icon on the page with the pen to ask a question.

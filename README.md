<p align="right"><a href="./README.zh-CN.md">简体中文</a></p>

# inkwell

[![Latest release](https://img.shields.io/github/v/release/jiachliu666/inkwell)](../../releases/latest)
[![Downloads](https://img.shields.io/github/downloads/jiachliu666/inkwell/total)](../../releases)
[![Platform](https://img.shields.io/badge/platform-reMarkable%202-blue)](../../releases)
[![License](https://img.shields.io/github/license/jiachliu666/inkwell)](./LICENSE)

**rm-agent** turns your reMarkable 2 into a tablet that writes back.

Tap a corner of the page with the pen and it answers your handwritten
question, or sketches whatever you asked it to draw — using the tablet's own
pen digitizer, so the reply looks and feels like real ink, not an imported
image.

## Features

- **Tap to ask** — tap the bottom-left corner to have a handwritten question
  answered.
- **Tap to draw** — tap the bottom-right corner to have a drawing request
  sketched out.
- **Real pen strokes, not an import** — replies are replayed as actual pen
  digitizer events, starting exactly where you last touched the page, so
  they show up as native ink.
- **No PC, no cables** — runs entirely on-device as a background service; no
  syncing to a computer or import step required.
- **Starts on boot** — installed as a systemd service that starts after the
  reMarkable's own UI and restarts automatically if it crashes.

## Demo

<!-- TODO: replace with the actual demo link/embed once recorded -->
https://github.com/jiachliu666/inkwell/assets/demo-placeholder

Watch rm-agent answer a handwritten question and sketch a drawing request,
both written back in the tablet's own pen strokes.

## Download

This repo holds no source code — only compiled `rm-agent` binaries for the
reMarkable 2. Grab the latest one from the [Releases](../../releases) page.
Each release also includes `rm-agent.service` (systemd unit) and
`rm-agent.env.example` (config template) — download those too.

## Installation

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
question, or the bottom-right corner to have something drawn.

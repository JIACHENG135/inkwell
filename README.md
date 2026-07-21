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
- **[Experimental] Three-finger translate** *(reMarkable 2 only)* — circle,
  underline, or box a word, phrase, or whole passage and three-finger-tap
  to pop up its Chinese translation right on the page, with an example
  sentence for single words/phrases. See [below](#experimental-three-finger-translate-remarkable-2)
  — this one's built on a third-party framework and comes with real
  caveats, read before installing.

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

## Experimental: Three-Finger Translate (reMarkable 2)

Circle a word, underline a sentence, or box a whole paragraph, then
three-finger-tap the page — a popup appears with the Chinese translation
(a single word/phrase also gets a short example sentence with the target
word bolded in both languages; a longer passage just gets translated in
full). The popup can be dragged anywhere on screen and dismisses on tap
or after a few seconds.

**Read this whole section before installing.** Unlike rm-agent itself
(which just runs alongside xochitl, untouched), this feature works by
patching xochitl's live QML UI using **[XOVI](https://github.com/asivery/rm-xovi-extensions)**,
an unofficial, community-built hooking framework — not something
reMarkable supports or ships. That means real, specific risks:

- **A bad patch can crash-loop xochitl.** During development, one wrong
  QML property name made xochitl exit immediately on every launch —
  the tablet looked stuck "restarting" forever until the patch was
  reverted. The install steps below include a safe verification step
  (`xovi/debug`, foreground, easy to abort) before ever switching to the
  persistent mode — **do not skip it**, and know the one-line revert
  (`xovi/stock`) before you start.
- **The patch is locked to one firmware version.** XOVI translates QML
  property/type names to numeric hashes generated from your *exact*
  xochitl build; this only ships one pre-hashed patch, built and tested
  against **firmware 3.27.3.0**. If your device is on a different
  version, you'll need to regenerate the hash table and re-hash the
  patch yourself (steps below) — using the wrong hash table's patch
  can produce anything from "does nothing" to the crash-loop above, so
  don't skip the `xovi/debug` check regardless of which firmware you're on.
- **reMarkable 2 only, for now.** Not yet ported to Paper Pro.
- **`xovi/start` doesn't survive a reboot on its own** (it's a tmpfs
  mount) — the install below adds a small systemd unit
  (`xovi-start.service`) that reruns it automatically at boot, so this
  isn't something you need to remember to do by hand, but it is one
  more thing running at every startup.

If any of that sounds like more risk than you want on your tablet,
skip this section — the core rm-agent feature above doesn't need any of it.

### What's in this folder

| File | Purpose |
| --- | --- |
| `translate-daemon-v0.1.0-armv7-unknown-linux-musleabihf` | The companion background service — captures screenshots, diffs them to isolate what you marked, and calls Gemini to translate it. Reuses the same screenshot API as rm-agent itself. |
| `three_finger_translate.rm2-fw3.27.3.0.qmd` | The XOVI patch, pre-hashed for firmware 3.27.3.0 — adds the gesture and the popup UI to xochitl's document view. |
| `three_finger_translate.source.qmd` | The same patch in plain, human-readable form (not hashed to any firmware) — start here if you're on a different firmware version. |
| `NotoSansSC.ttf`, `NotoSansSC-Bold.ttf` | Chinese-capable fonts for the popup — the reMarkable 2's stock fonts are Latin-only and render Chinese as blank boxes otherwise. |
| `xovi-start.service` | Reruns `xovi/start` at every boot (see the reboot-persistence caveat above). |
| `translate-daemon.service`, `goMarkableStream.service`, `rm-agent.service` | systemd units, ordered to start only after XOVI has finished patching xochitl for the boot (this specific ordering avoids a real bug: without it, goMarkableStream can grab xochitl's *pre-patch* process id and then fail every screenshot with a 500 error until manually restarted). **These `goMarkableStream.service`/`rm-agent.service` replace the ones from the base install above** — if you already installed the core feature, you'll overwrite them as part of this. |

### Prerequisites

- The core rm-agent feature already installed and working (above) —
  this reuses its Gemini API key and screenshot login.
- SSH access to the tablet (same as above).

### 1. Install the XOVI framework

Skip this if `/home/root/xovi` already exists on your device.

```sh
# on your Mac/PC — grab the latest armv7 XOVI release
curl -sL -o xovi-arm32.tar.gz "$(curl -sL https://api.github.com/repos/asivery/rm-xovi-extensions/releases/latest \
  | grep -o '"browser_download_url": *"[^"]*xovi-arm32[^"]*"' | head -1 | sed -E 's/.*"(https[^"]+)"/\1/')"
mkdir xovi && tar -xzf xovi-arm32.tar.gz -C xovi --strip-components=1
scp -r xovi root@<device-ip>:/home/root/xovi

# the transfer drops two symlinks scp can't follow — recreate them on-device
ssh root@<device-ip> '
ln -sf /home/root/xovi/extensions.d /home/root/xovi/services/xochitl.service/extensions.d
ln -sf /home/root/xovi/exthome /home/root/xovi/services/xochitl.service/exthome
'
```

Activate the two extensions this feature needs:

```sh
ssh root@<device-ip> '
mv /home/root/xovi/inactive-extensions/qt-resource-rebuilder.so /home/root/xovi/extensions.d/ 2>/dev/null
mv /home/root/xovi/inactive-extensions/qt-command-executor.so /home/root/xovi/extensions.d/ 2>/dev/null
ls /home/root/xovi/extensions.d/
'
```

### 2. Get the hash table for your firmware

Check your firmware version first:

```sh
ssh root@<device-ip> "grep REMARKABLE_RELEASE_VERSION /usr/share/remarkable/update.conf"
```

**If it says `3.27.3.0`**, skip ahead to step 3 — `three_finger_translate.rm2-fw3.27.3.0.qmd` in this folder already matches.

**On any other version**, you need to build a hash table for your exact
firmware and re-hash `three_finger_translate.source.qmd` against it:

```sh
# this runs xochitl once and needs your device passcode when prompted —
# it stops xochitl and everything depending on it while it runs
ssh -t root@<device-ip> '/home/root/xovi/rebuild_hashtable'
scp root@<device-ip>:/home/root/xovi/exthome/qt-resource-rebuilder/hashtab ./hashtab
ssh root@<device-ip> 'systemctl start xochitl'   # bring it back

# build qmldiff (needs a Rust toolchain: https://rustup.rs)
git clone --depth 1 https://github.com/asivery/qmldiff.git
(cd qmldiff && cargo build --release)

# hash the patch against your hashtable (rewrites the file in place)
cp three_finger_translate.source.qmd my-translate.qmd
./qmldiff/target/release/qmldiff hash-diffs ./hashtab my-translate.qmd
```

Use `my-translate.qmd` in place of `three_finger_translate.rm2-fw3.27.3.0.qmd`
in the next step.

### 3. Install the patch, fonts, and daemon

```sh
ssh root@<device-ip> 'mkdir -p /home/root/xovi/exthome/translate'
scp three_finger_translate.rm2-fw3.27.3.0.qmd \
    root@<device-ip>:/home/root/xovi/exthome/qt-resource-rebuilder/three_finger_translate.qmd
scp NotoSansSC.ttf NotoSansSC-Bold.ttf root@<device-ip>:/home/root/xovi/exthome/translate/

scp translate-daemon-v0.1.0-armv7-unknown-linux-musleabihf root@<device-ip>:/home/root/translate_daemon
ssh root@<device-ip> 'chmod +x /home/root/translate_daemon'

scp xovi-start.service translate-daemon.service goMarkableStream.service rm-agent.service \
    root@<device-ip>:/etc/systemd/system/
ssh root@<device-ip> 'systemctl daemon-reload'
```

### 4. Verify with `xovi/debug` before going persistent — do not skip this

`xovi/debug` runs xochitl in the foreground with the patch applied, so
you can see immediately if anything's wrong and just Ctrl-C out —
nothing persists yet at this point.

```sh
ssh root@<device-ip> 'systemctl stop xochitl'
ssh root@<device-ip> '/home/root/xovi/debug'
```

Watch the output. If you see a line like `Cannot assign to non-existent
property` or `Type ... unavailable`, something's wrong (wrong hash table
is the most likely cause) — press Ctrl-C, then run
`ssh root@<device-ip> '/home/root/xovi/stock'` to make sure xochitl goes
back to its normal, unpatched self, and don't proceed to step 5. Otherwise,
if the tablet's UI comes up looking normal, Ctrl-C out of the SSH session
(this stops the foreground xochitl it started) and continue.

### 5. Go persistent

```sh
ssh root@<device-ip> '
/home/root/xovi/start
systemctl enable xovi-start.service goMarkableStream.service rm-agent.service translate-daemon.service
systemctl restart goMarkableStream rm-agent translate-daemon
systemctl is-active xochitl goMarkableStream rm-agent translate-daemon xovi-start
'
```

All five should print `active`. A reboot test is worthwhile the first
time, same as the base install.

### Using it

Open a document, circle/underline/box something with the pen, then
three-finger-tap anywhere on the page (mark first, *then* tap — the tap
is what triggers translation of whatever's new since the last one). The
popup shows up within a few seconds; drag it anywhere, tap elsewhere or
the **×** to dismiss it early.

### If something goes wrong

- **Tablet stuck "restarting" / xochitl won't stay up**: `ssh root@<device-ip> '/home/root/xovi/stock'` immediately reverts to plain, unpatched xochitl — the tablet is safe as soon as that finishes.
- **Screenshots fail with a 500 error**: `ssh root@<device-ip> 'systemctl restart goMarkableStream'` — it needs restarting if it ever grabs xochitl's process id before XOVI finishes patching it.
- **Popup shows Chinese as blank boxes**: the fonts didn't make it to `/home/root/xovi/exthome/translate/` — re-run the `scp` in step 3.

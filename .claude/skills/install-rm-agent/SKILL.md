---
name: install-rm-agent
description: Use when a user wants to install rm-agent (tap-to-ask AI on a reMarkable tablet) and/or the experimental three-finger translate feature from this repo onto their reMarkable 2 or reMarkable Paper Pro. Drives the SSH-based install end to end — device detection, prerequisite checks, copying binaries/services, enabling systemd units, verifying, and the extra XOVI safety checks the translate feature needs.
---

# Install rm-agent / three-finger translate

## Overview

This repo (`inkwell`) ships prebuilt binaries for two features, on two
device types:

- **rm-agent** (core): tap a corner with the pen, get a handwritten
  reply written back in real ink. Works the same way conceptually on
  both devices, but the install mechanics differ (see Device Notes).
- **three-finger translate** (experimental, optional): circle/underline/box
  something, three-finger-tap, get a popup translation. Built on **XOVI**,
  an unofficial framework that patches xochitl's live UI — meaningfully
  riskier than the core feature (can crash-loop the tablet if the patch
  doesn't match the firmware). Only do this after the user has explicitly
  opted in with the risks understood.

All the files this skill needs (binaries, `.service` units, fonts, the
XOVI patch) already live at the root of this repo and in
`xovi-translate/` (reMarkable 2) / `xovi-translate-paperpro/` (Paper
Pro) — no need to hit the GitHub Releases API, just use the checked-out
repo. Run this skill with the repo as the working directory.

**Do not fabricate SSH/device output.** Every "verify" step below runs a
real command over SSH and reports what it actually says. If a command
fails or the device isn't reachable, say so and stop — don't guess at
what it would have shown.

## Step 0 — Gather inputs

Ask the user (don't assume):

1. **Which device?** reMarkable 2 or reMarkable Paper Pro — the file
   paths, service locations, and even the systemd persistence mechanism
   differ (see Device Notes).
2. **Device IP address.** rM2: Settings → About → General. Paper Pro:
   same menu, or `10.11.99.1` over USB before WiFi SSH is enabled.
3. **Just the core feature, or translate too?** Confirm the base feature
   first — translate depends on it being installed already for both its
   Gemini key and the screenshot API. If they want translate, walk
   through the risk callouts in "Before installing translate" below and
   get explicit confirmation before touching XOVI.
4. **Gemini API key** — https://aistudio.google.com/apikey (needs an
   image-generation-capable model for rm-agent's own drawing replies;
   translate-only installs can use a lighter text model but the key
   still needs to work for at least text generation).

## Step 1 — Confirm SSH access

```sh
ssh -o BatchMode=yes -o ConnectTimeout=5 root@<device-ip> 'echo ok'
```

- If this prints `ok`, passwordless key auth is already set up — proceed
  automatically for the rest of this skill.
- If it hangs or asks for a password, **stop and hand this back to the
  user**: passwordless SSH must be set up first, since password-prompt
  SSH can't be driven non-interactively.
  - Get the root password (rM2: Settings → About → Copyrights and
    licenses; Paper Pro: Settings → General → Help → About →
    Copyrights and licenses, GPLv3 Compliance section).
  - Paper Pro only: SSH is USB-only until enabled — have the user
    connect via USB, SSH to `10.11.99.1` once with the password, then
    run `rm-ssh-over-wlan on` so WiFi SSH works for the rest of this.
  - Ask the user to run `ssh-copy-id root@<device-ip>` themselves
    (enters the password once, interactively, in their own terminal —
    not something to attempt over the Bash tool). Confirm with them
    once done, then re-run the `BatchMode=yes` check above yourself
    before continuing.

## Step 2 — Install rm-agent (core)

### reMarkable 2

```sh
scp rm-agent-*-armv7-unknown-linux-musleabihf root@<device-ip>:/home/root/rm-agent
scp rm-agent.service root@<device-ip>:/etc/systemd/system/rm-agent.service
scp rm-agent.env.example root@<device-ip>:/home/root/.config/rm-agent.env
ssh root@<device-ip> 'chmod +x /home/root/rm-agent'
```

Set the API key — edit `/home/root/.config/rm-agent.env` on the device
(`GEMINI_API_KEY=...`). Do this with the user present (it's their key);
don't invent or reuse a key from anywhere else.

```sh
ssh root@<device-ip> 'systemctl daemon-reload && systemctl enable --now rm-agent.service'
```

### reMarkable Paper Pro

Needs two things rM2 doesn't:

- **goMarkableStream** — third-party tool providing the screenshot/login
  API xochitl doesn't expose natively. Get the `gomarkablestream-RMPRO`
  asset from https://github.com/owulveryck/goMarkableStream/releases
  (if this repo will *also* get the translate feature installed later,
  use `gomarkablestream-RMPRO-lite` instead — see the translate section's
  Paper Pro gotcha).
- Paper Pro's `/etc` is a volatile overlay that resets every boot — unit
  files go in `/lib/systemd/system` instead, which means briefly
  remounting root read-write.

```sh
scp gomarkablestream-RMPRO root@<device-ip>:/home/root/goMarkableStream
scp goMarkableStream.service root@<device-ip>:/lib/systemd/system/goMarkableStream.service
ssh root@<device-ip> 'chmod +x /home/root/goMarkableStream'

scp rm-agent-*-aarch64-unknown-linux-musl root@<device-ip>:/home/root/rm-agent
scp rm-agent-paperpro.service root@<device-ip>:/lib/systemd/system/rm-agent.service
scp rm-agent.env.example root@<device-ip>:/home/root/.config/rm-agent.env
ssh root@<device-ip> 'chmod +x /home/root/rm-agent'
```

Set the API key with the user present, same as above, then wire both
services to start on boot (tell the user you're briefly remounting `/`
read-write to drop the boot-enablement symlinks, then back to read-only
— this is expected and not risky, just non-default):

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

## Step 3 — Verify core install

```sh
ssh root@<device-ip> 'systemctl status rm-agent'          # rM2
ssh root@<device-ip> 'systemctl status goMarkableStream rm-agent'   # Paper Pro
ssh root@<device-ip> 'journalctl -u rm-agent -n 30 --no-pager'
```

Report the actual `active (running)`/`failed`/whatever it says — don't
paraphrase into "should be working." Suggest the user tap the corner
icon with the pen to try it, and ask them to confirm it worked before
moving on to translate (if they want it).

A reboot test (`ssh root@<device-ip> reboot`, wait, re-check status) is
worth suggesting on Paper Pro specifically, since its persistence
mechanism is non-default and easy to get subtly wrong.

## Before installing translate — required risk callout

**Do not proceed to Step 4 without walking the user through this and
getting explicit confirmation.** This is not a formality — during this
feature's own development, a wrong QML property name crash-looped
xochitl (stuck "restarting" until the patch was reverted). Tell the user,
plainly:

- This patches xochitl's live UI via XOVI, an unofficial framework —
  not something reMarkable supports.
- A bad or mismatched patch can make xochitl fail to start at all. The
  install below has a mandatory safe-check step (`xovi/debug`,
  foreground) before anything persists — **never skip it**, regardless
  of how confident anyone is the firmware matches.
- The one-line revert-to-safety is `/home/root/xovi/stock` — mention
  this before starting, not after something goes wrong.
- The patch is hashed against one exact firmware build. This repo ships
  a pre-hashed patch for firmware `3.27.3.0` for each device; a
  different firmware needs a re-hash (covered in Step 4).

If the user doesn't want this risk, stop here — the core feature above
doesn't need any of it.

## Step 4 — Install three-finger translate

Prerequisite: core rm-agent already verified working on this device
(Step 3) — translate reuses its Gemini key and screenshot login.

Work from the matching subfolder: `xovi-translate/` (rM2) or
`xovi-translate-paperpro/` (Paper Pro). File names below are relative to
that folder.

### 4a. Install XOVI (skip if `/home/root/xovi` already exists)

reMarkable 2:
```sh
curl -sL -o xovi-arm32.tar.gz "$(curl -sL https://api.github.com/repos/asivery/rm-xovi-extensions/releases/latest \
  | grep -o '"browser_download_url": *"[^"]*xovi-arm32[^"]*"' | head -1 | sed -E 's/.*"(https[^"]+)"/\1/')"
mkdir xovi && tar -xzf xovi-arm32.tar.gz -C xovi --strip-components=1
scp -r xovi root@<device-ip>:/home/root/xovi
ssh root@<device-ip> '
ln -sf /home/root/xovi/extensions.d /home/root/xovi/services/xochitl.service/extensions.d
ln -sf /home/root/xovi/exthome /home/root/xovi/services/xochitl.service/exthome
mv /home/root/xovi/inactive-extensions/qt-resource-rebuilder.so /home/root/xovi/extensions.d/ 2>/dev/null
mv /home/root/xovi/inactive-extensions/qt-command-executor.so /home/root/xovi/extensions.d/ 2>/dev/null
ls /home/root/xovi/extensions.d/
'
```

Paper Pro (aarch64 build, only `qt-command-executor` needed since
`qt-resource-rebuilder` ships active by default there):
```sh
curl -sL -o xovi-aarch64.tar.gz "$(curl -sL https://api.github.com/repos/asivery/rm-xovi-extensions/releases/latest \
  | grep -o '"browser_download_url": *"[^"]*xovi-aarch64[^"]*"' | head -1 | sed -E 's/.*"(https[^"]+)"/\1/')"
mkdir xovi && tar -xzf xovi-aarch64.tar.gz -C xovi --strip-components=1
scp -r xovi root@<device-ip>:/home/root/xovi
ssh root@<device-ip> '
ln -sf /home/root/xovi/extensions.d /home/root/xovi/services/xochitl.service/extensions.d
ln -sf /home/root/xovi/exthome /home/root/xovi/services/xochitl.service/exthome
mv /home/root/xovi/inactive-extensions/qt-command-executor.so /home/root/xovi/extensions.d/ 2>/dev/null
ls /home/root/xovi/extensions.d/
'
```

### 4b. Check firmware, get the right patch

```sh
ssh root@<device-ip> "grep REMARKABLE_RELEASE_VERSION /usr/share/remarkable/update.conf"   # rM2
ssh root@<device-ip> "cat /etc/version"                                                     # Paper Pro
```

If it's `3.27.3.0`, the pre-hashed `.qmd` in this folder already matches
— skip to 4c. **The two devices' pre-hashed files are not
interchangeable even when both report 3.27.3.0** — always use the file
from the matching folder.

Any other firmware — rebuild the hash table and re-hash the plain-text
source patch (requires a Rust toolchain locally):

```sh
ssh -t root@<device-ip> '/home/root/xovi/rebuild_hashtable'   # stops xochitl while it runs
scp root@<device-ip>:/home/root/xovi/exthome/qt-resource-rebuilder/hashtab ./hashtab
ssh root@<device-ip> 'systemctl start xochitl'   # bring it back immediately

git clone --depth 1 https://github.com/asivery/qmldiff.git
(cd qmldiff && cargo build --release)
cp three_finger_translate.source.qmd my-translate.qmd
./qmldiff/target/release/qmldiff hash-diffs ./hashtab my-translate.qmd
```

Use `my-translate.qmd` in place of the pre-hashed file in 4c.

### 4c. Install the patch, fonts, and daemon

```sh
ssh root@<device-ip> 'mkdir -p /home/root/xovi/exthome/translate'
scp three_finger_translate.<rm2-or-paperpro>-fw3.27.3.0.qmd \
    root@<device-ip>:/home/root/xovi/exthome/qt-resource-rebuilder/three_finger_translate.qmd
scp NotoSansSC.ttf NotoSansSC-Bold.ttf root@<device-ip>:/home/root/xovi/exthome/translate/

scp translate-daemon-v0.2.0-<armv7-unknown-linux-musleabihf-or-aarch64-unknown-linux-musl> \
    root@<device-ip>:/home/root/translate_daemon
ssh root@<device-ip> 'chmod +x /home/root/translate_daemon'
```

Service units — **rM2** goes to `/etc/systemd/system`:
```sh
scp xovi-start.service translate-daemon.service goMarkableStream.service rm-agent.service \
    root@<device-ip>:/etc/systemd/system/
ssh root@<device-ip> 'systemctl daemon-reload'
```

**Paper Pro** goes to `/lib/systemd/system` (same volatile-`/etc` reason
as the core install) and needs boot-enablement symlinks:
```sh
ssh root@<device-ip> 'mount -o remount,rw /'
scp xovi-start.service translate-daemon.service goMarkableStream.service rm-agent.service \
    root@<device-ip>:/lib/systemd/system/
ssh root@<device-ip> '
mkdir -p /lib/systemd/system/xochitl.service.wants
ln -sf /lib/systemd/system/xovi-start.service /lib/systemd/system/xochitl.service.wants/xovi-start.service
ln -sf /lib/systemd/system/translate-daemon.service /lib/systemd/system/xochitl.service.wants/translate-daemon.service
mount -o remount,ro /
systemctl daemon-reload
'
```

Note for both: the `goMarkableStream.service`/`rm-agent.service` here
**replace** the core-install ones — they're reordered to start only
after XOVI finishes patching xochitl (avoids goMarkableStream grabbing
xochitl's pre-patch process id and 500-ing every screenshot until
restarted).

### 4d. Mandatory safe check — `xovi/debug` before anything persists

```sh
ssh root@<device-ip> 'systemctl stop xochitl'
ssh root@<device-ip> '/home/root/xovi/debug'
```

Read the output carefully. If you see `Cannot assign to non-existent
property` or `Type ... unavailable`, the hash table doesn't match:
Ctrl-C, run `ssh root@<device-ip> '/home/root/xovi/stock'` to force
xochitl back to plain/unpatched, and **do not proceed to 4e** — go back
to 4b and get the firmware match right. If the UI looks normal, Ctrl-C
(stops the foreground xochitl this started) and continue.

### 4e. Go persistent

reMarkable 2:
```sh
ssh root@<device-ip> '
/home/root/xovi/start
systemctl enable xovi-start.service goMarkableStream.service rm-agent.service translate-daemon.service
systemctl restart goMarkableStream rm-agent translate-daemon
systemctl is-active xochitl goMarkableStream rm-agent translate-daemon xovi-start
'
```

Paper Pro:
```sh
ssh root@<device-ip> '
/home/root/xovi/start
systemctl restart goMarkableStream rm-agent translate-daemon
systemctl is-active xochitl goMarkableStream rm-agent translate-daemon xovi-start
'
```

All five must print `active` — report exactly what each one says. A
reboot test is worth doing here too, especially on Paper Pro (screen
capture goes through `/dev/dri/card0`, which isn't always ready the
instant goMarkableStream starts on boot — the bundled service already
waits for it, but a reboot test is the only way to actually confirm).

### Using it

Circle/underline/box something with the pen, *then* three-finger-tap
anywhere on the page (mark first — the tap triggers translation of
whatever was last marked). Popup appears within a few seconds; drag it,
tap elsewhere, or tap the **×** to dismiss.

## Troubleshooting

- **Tablet stuck "restarting" / xochitl won't come up**:
  `ssh root@<device-ip> '/home/root/xovi/stock'` reverts to plain
  xochitl immediately — always the first move, do this before
  investigating anything else.
- **Screenshots / translation fail with a 500 error or "no new
  content" forever**: `ssh root@<device-ip> 'systemctl restart
  goMarkableStream'`. On Paper Pro, if this recurs after every boot,
  confirm the `goMarkableStream.service` in use is the one from this
  repo (has the `dev-dri-card0.device` ordering), not a generic one.
- **Popup shows Chinese as blank boxes**: the fonts didn't land in
  `/home/root/xovi/exthome/translate/` — re-run the font `scp` from 4c.
- **Any `ssh`/`scp` step fails outright**: check device is reachable
  (`ping`) and the SSH BatchMode check from Step 1 still passes before
  retrying — don't retry blindly.

## Guardrails

- Never skip the `xovi/debug` foreground check (4d) — it's the only
  thing standing between a bad patch and a bricked-looking tablet.
- Never proceed past a failed `xovi/debug` check — always revert with
  `xovi/stock` first.
- Get explicit user confirmation before Step 4 (translate) specifically
  — it's real, understood risk, not a default extension of Step 2.
- Don't invent or reuse Gemini API keys — the user provides their own.
- Don't fabricate command output. If `ssh`/`scp` fails or times out,
  report that plainly and stop rather than assuming success.
- The `mount -o remount,rw /` steps on Paper Pro are expected and
  intentional (that's how the base install itself works) — not a sign
  something's wrong, but still worth telling the user is happening.

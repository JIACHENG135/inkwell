<p align="right"><a href="./README.zh-CN.md">简体中文</a></p>

# inkwell

[![Latest release](https://img.shields.io/github/v/release/jiachliu666/inkwell)](../../releases/latest)
[![Downloads](https://img.shields.io/github/downloads/jiachliu666/inkwell/total)](../../releases)
[![Platform](https://img.shields.io/badge/platform-reMarkable%202%20%7C%20Paper%20Pro-blue)](../../releases)
[![License](https://img.shields.io/github/license/jiachliu666/inkwell)](./LICENSE)

**Write a question on your reMarkable. Tap the corner. The answer is drawn
onto the page in ink.**

Not a popup you dismiss, not an image you import — real pen strokes, laid
down next to your own handwriting, on the page you were already using.
Works on the **reMarkable 2** and the **reMarkable Paper Pro**, entirely
on-device.

<p align="center">
  <img src="docs/assets/draw.gif" width="440" alt="Writing “Draw a Naruto, running!” on the page; the drawing appears stroke by stroke">
</p>

## Ask, and it writes back

Write anything on the page and tap the corner. The reply is drawn with the
tablet's own pen — so you can erase it, circle it, write on top of it. It
starts where you last put your pen down, instead of landing in the middle of
your notes.

<p align="center">
  <img src="docs/assets/hero.gif" width="440" alt="A definite integral written by hand; the curve and shaded area are drawn underneath it">
</p>

Ask for a picture and you get a picture. A curve, a shaded area, a diagram,
a running ninja — drawn, not described in three paragraphs of text.

## Look up a word without leaving the page

Reading in English and hit a word you don't know? Circle it, underline it,
or box it, then tap with three fingers. The meaning surfaces right on the
page, with an example sentence, and you keep reading.

<p align="center">
  <img src="docs/assets/translate.gif" width="370" alt="Circling “sulphate particles”, then a card with the Chinese meaning and an example sentence">
  <img src="docs/assets/retrieve.gif" width="370" alt="A review card for a previously looked-up word, with “know it” and “don't know it” buttons">
</p>

Circle a whole sentence or paragraph instead and you get the whole thing
translated — it works out what you meant to select.

Every word you look up is remembered. Tap the other corner and they come
back one card at a time, spaced along the forgetting curve — on the day
you're about to lose the word, not long after you already knew it.

## Ask about the whole page

Circle the part you don't follow and tap with five fingers. It reads the
entire page before answering, because a question usually points at the
diagram beside it or the derivation above it.

<p align="center">
  <img src="docs/assets/ask.gif" width="440" alt="A handwritten question about binary lifting; a card appears with the answer and a labelled tree diagram">
</p>

- **It repeats the question back first.** The top of the card is the
  question as it understood it. A wrong answer is obvious; an answer to a
  *different* question is not, unless you can see that line.
- **Formulas are typeset.** Superscripts sit high and small, fractions get a
  real bar, roots cover what's inside them.
- **It draws when words won't do.** Ask how something works and a diagram
  may come back with the answer — in colour on the Paper Pro.

## It's just there

- **No computer, no cable.** Everything runs on the tablet. No companion
  app, no import step, nothing to plug in.
- **On from boot.** Starts with the tablet, picks itself back up if it falls
  over, still knows you after a week left on.
- **Both tablets.** reMarkable 2 and Paper Pro. Diagrams are in colour on
  the colour screen and perfectly legible on the black-and-white one.

## Get it

Download the build for your device from the
[Releases](../../releases/latest) page, then follow the
[installation guide](./INSTALL.md) — an AI coding agent can run the whole
thing for you if you'd rather not copy-paste commands.

| Device | Binary |
| --- | --- |
| reMarkable 2 | `rm-agent-*-armv7-unknown-linux-musleabihf` |
| reMarkable Paper Pro | `rm-agent-*-aarch64-unknown-linux-musl` |

Three-finger translate is still experimental and comes with real caveats —
read its section in the [installation guide](./INSTALL.md) before turning it
on.

More at the [product page](https://jiacheng135.github.io/inkwell/). Reading
English on your reMarkable? See also
[rm-weread](https://jiacheng135.github.io/rm-weread/).

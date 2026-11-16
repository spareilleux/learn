# Nylon acoustic guitar samples

One recorded note per pitch used by a ```play block anywhere in the courses, served from
this site so that a network which blocks the CDN still plays them. `MarkdownContent.astro`
asks for a note here first and falls back to the CDN for any pitch not vendored below, so
adding a new pitch to a lesson needs no change here — it simply costs one CDN request
until the file is added.

## Source and licence

Generated from [FluidR3_GM.sf2](http://www.synthfont.com/SoundFonts/FluidR3_GM.sfArk) by
[gleitz/midi-js-soundfonts](https://github.com/gleitz/midi-js-soundfonts), released under the
[Creative Commons Attribution 3.0 licence](https://creativecommons.org/licenses/by/3.0/us/).
Copied byte for byte from the pinned commit `044fab8e1456bfafc5776e86dfd6bb8697149aef`,
folder `FluidR3_GM/acoustic_guitar_nylon-mp3`. Nothing is synthesised or re-encoded.

## Refreshing the set

The pitches come from every ```play block in `src/content/docs/`:

```bash
SF=https://cdn.jsdelivr.net/gh/gleitz/midi-js-soundfonts@044fab8e1456bfafc5776e86dfd6bb8697149aef/FluidR3_GM/acoustic_guitar_nylon-mp3
for n in A2 A3 A4 B2 B3 B4 Bb4 C3 C4 C5 D3 D4 E2 E3 E4 Eb4 F2 F3 F4 G2 G3 G4; do
  curl -sf -o "$n.mp3" "$SF/$n.mp3"
done
```

Note names follow the flat spelling `MarkdownContent.astro` uses, so `Bb4` and not `A#4`.

# ReadPp App Icon Source

The app icon must be generated from an isolated `RP` symbol/monogram, not from
the full ReadPp wordmark.

Required source file before final generation:

- `readpp_app_icon_source.png`
- 1024x1024 px minimum.
- Square PNG.
- No text wordmark.
- Use only the `RP` symbol/monogram.

Recommended visual routes:

- Burgundy deep background with a cream or blush `RP` monogram.
- Warm cream background with a Burgundy `RP` monogram.

Platform preparation:

- Android legacy launcher icon: generate mipmap PNGs from the same source.
- Android adaptive icon: generate foreground and background assets with enough
  safe padding for circular, rounded-square and squircle masks.
- iOS AppIcon: generate the full AppIcon.appiconset from the same source.
- Web/PWA: generate 192, 512 and maskable icons from the same source.

Do not use:

- Full `ReadPp` logo with text.
- Store screenshot artwork.
- Splash artwork.
- Low-resolution exports.

Current status:

- Final isolated `RP` source: pending.
- Platform icon generation: pending.

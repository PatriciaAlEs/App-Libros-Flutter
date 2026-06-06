# ReadPp Branding Assets

This folder is reserved for the ReadPp visual identity.

Final v1 brand direction:

- Public name: ReadPp.
- Style: premium editorial reading journal.
- Primary theme: Burgundy.
- Alternative theme: Forest.
- Brand/display typography: Space Grotesk.
- UI/body typography: Roboto.
- Recommended app icon: simple ReadPp/RP/dP monogram with a subtle open-book cue on a Burgundy background.
- Recommended splash: Burgundy or cream background with centered ReadPp mark.

Official source files:

- `logos/readpp_logo.png`: primary colored ReadPp logo.
- `logos/readpp_logo_transparent.png`: transparent ReadPp logo variant.
- `logos/readpp_logo.svg`: primary vector logo source.
- `logos/readpp_logo_transparent.svg`: transparent vector logo source.

App icon source requirement:

- Do not use the full ReadPp logo with text for the app icon.
- The final app icon must use the isolated `RP` symbol/monogram only.
- The full wordmark is not legible at launcher icon sizes.
- Export a dedicated source file before regenerating platform icons:
  - `app_icon/readpp_app_icon_source.png`
  - 1024x1024 or larger.
  - Burgundy deep background with a light monogram, or warm cream background with Burgundy monogram.
  - No wordmark text.
  - Keep generous safe padding for Android adaptive icon masks.

Recommended structure:

- `logos/`: primary logo, horizontal logo, monochrome variants.
- `app_icon/`: source app icon artwork before platform generation.
- `variants/`: seasonal, campaign or future theme-specific variants.

Current platform icon status:

- Official full-logo artwork is available under `logos/`.
- A dedicated isolated `RP` app icon source is still required before final icon generation.
- Do not regenerate Android, iOS or Web launcher icons from the full logo with text.
- Android adaptive icon foreground/background generation remains pending until the isolated `RP` source is exported.

Current splash status:

- Android and iOS use a simple Burgundy launch background.
- Final centered splash mark remains pending until native launch assets are exported at platform-ready sizes.

Keep asset paths stable so UI and native configuration can adopt the final artwork without changing feature code.

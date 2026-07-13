# Design QA - LibrerIA floating chat visual redesign

- Source visual truth:
  - `C:\Users\piruj\OneDrive\Pictures\Screenshots\Captura de pantalla 2026-07-11 113802.png`
  - `C:\Users\piruj\OneDrive\Pictures\Screenshots\Captura de pantalla 2026-07-11 114100.png`
  - `C:\Users\piruj\OneDrive\Pictures\Screenshots\Captura de pantalla 2026-07-11 120235.png`
- Intended comparison viewport: 420 px wide expanded panel, plus 320 px responsive validation.
- Intended state: expanded conversation panel and collapsed launcher.
- Implementation screenshot: unavailable.

## Full-view comparison evidence

The three source images were opened at original resolution. A browser-rendered
implementation capture could not be produced because the local Flutter web
process did not publish its configured port or return diagnostic output before
the execution timeout. A reliable side-by-side comparison is therefore blocked.

## Focused-region comparison evidence

Blocked for the same reason. The intended focused regions were the compact
header, assistant/user bubble pair, composer/footer, and collapsed launcher.

## Static implementation review

- Fonts and typography: existing ReadPp Roboto text-theme styles are reused;
  headings were reduced to panel-scale title styles.
- Spacing and layout rhythm: compact `AppSpacing` values are used for the
  header, message list, empty state, composer, and footer.
- Colors and visual tokens: the existing burgundy `primary`, pale
  `primaryContainer`, warm `scaffoldBackgroundColor`, `onPrimary`, outline
  variants, elevations, and `AppShadows.soft` are reused.
- Image and icon fidelity: the design contains no required raster content.
  Existing Material sparkle, chevron, send, stop, refresh, and menu icons are
  retained. The unrelated black question-mark overlay is intentionally absent.
- Copy: title, subtitle, composer placeholder, disclaimer, and the three
  existing suggestions match the requested product copy.

## Findings

- [P1] Rendered fidelity cannot be confirmed.
  - Location: complete floating chat.
  - Evidence: source references are available, but no implementation screenshot
    could be captured.
  - Impact: exact visual matching, text wrapping, and runtime layout at the
    target widths remain unverified.
  - Fix: start the Flutter web target in the normal development environment,
    capture the expanded and collapsed states at matching widths, and compare
    them side by side with the source references.

## Comparison history

- Initial pass: blocked before the first rendered comparison because the local
  web target did not become available within the execution window.
- No visual iteration was claimed without rendered evidence.

## Implementation checklist

- Capture the expanded panel at 420 px and 320 px.
- Capture the collapsed launcher.
- Verify Enter, Shift+Enter, stop, regenerate, menu, and collapse interactions.
- Check browser console for layout or input exceptions.
- Compare header, bubbles, composer, footer, shadows, radii, and typography
  against the supplied references.

final result: blocked

# Design QA — Progreso, Insights y Estadísticas

- Source visual truth:
  - `C:\Users\piruj\AppData\Local\Temp\codex-clipboard-5ce60ac7-95cc-4392-9ab5-9d4ff9714c02.png`
  - `C:\Users\piruj\AppData\Local\Temp\codex-clipboard-2b0797a5-5793-449f-ba5c-b10992249dbd.png`
  - `C:\Users\piruj\AppData\Local\Temp\codex-clipboard-c254d621-e998-465c-90e3-8078eba15b75.png`
- Implementation screenshot: unavailable.
- Intended viewport: 390 px mobile, with a responsive lower bound of 320 px.
- State: populated progress, insights and statistics dashboards.

## Full-view comparison evidence

The three source references were opened at original resolution. Their visual language was extended from Progress to Insights and Statistics. A rendered implementation could not be captured because the Flutter analyzer did not finish and the local web process could not be started: PowerShell `Start-Process` failed on an environment collision between `Path` and `PATH`.

## Focused-region comparison evidence

Blocked for the same reason. The source regions reviewed were the reader summary, annual goal, weekly activity, reader map, reading time and reading-status cards. No implementation pixels are available for a valid comparison.

## Findings

- [P1] Rendered fidelity is not verified.
  - Location: `ProgressScreen`, `InsightsScreen` and `StatsScreen` at 320 px and 390 px.
  - Evidence: source references are available, but no implementation capture exists.
  - Impact: overflow, wrapping, exact density and vertical rhythm cannot be judged from code alone.
  - Fix: start the Flutter web app in a working process environment, capture the three routes at 390 px and 320 px, and compare them against the supplied references.

## Implementation checklist

1. Resolve the `Path`/`PATH` process-launch collision.
2. Capture the populated Progreso, Insights and Estadísticas views at 390 px.
3. Capture the three responsive views at 320 px.
4. Check all existing actions: Editar, Buscar/Cambiar libro, Ver estadísticas, calendario and registrar sesión.
5. Compare spacing, card radii, color tokens, typography inheritance, icons and copy.

## Comparison history

- Initial pass: blocked before implementation capture; no pixel-level fixes can be justified without rendered evidence.

final result: blocked

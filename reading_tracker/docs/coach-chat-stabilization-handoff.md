# LibrerIA chat stabilization handoff

## Root causes

The composer `AnimatedSwitcher` alternated two direct `Semantics` children
without keys. The `send` and `stop` keys were attached to nested icon buttons,
so the switcher still saw two outgoing/incoming children with a null key. The
scroll-to-bottom switcher also had an unkeyed hidden branch.

The reported `_dependents.isEmpty` assertion is consistent with tearing down a
provider-dependent widget while animated/streaming work is still completing,
but no independent provider ownership bug was found. Screen callbacks already
check `mounted`; controller stream callbacks use both `mounted` and a generation
id, and controller disposal cancels the subscription, completion and debounce.
Regression coverage now removes the screen while a response is active.

## Changes

- Every `AnimatedSwitcher` state has an explicit stable non-null key.
- The composer uses the available row width, grows to four lines, then scrolls.
- Send is disabled for blank text and changes to Stop during generation.
- Removed the unexplained 92 px inner bottom padding that distorted the input.
- Replaced decorative book emoji with the app's Material icon treatment.
- Reused Theme/ColorScheme, AppSpacing, AppMotion and existing text styles so
  Burgundy and Forest remain automatic.
- Reader context now includes real genre, notes, publisher and ISBN fields and
  resolves session book ids to known titles.
- The prompt answers directly when context is sufficient, permits at most one
  essential clarification, explains profile signals and forbids fabricated
  bibliographic data.

## Verification limits

Coach has no live Google Books grounding in its repository interface. It must
not claim live verification. Recommendations outside the local library are
therefore restricted by prompt to high-confidence works, with uncertainty made
explicit. No external API or provider was added.

Per task restriction, `dart format`, `flutter analyze` and `flutter test` were
not run. Validate the real screen in both themes at mobile width and a narrow
web viewport, including send/wait/stream/complete/stop/error transitions and
back navigation during an active response.

# ReadPp v1.0 Release Checklist

## Build

- [x] Version set to `1.0.0+1` in `pubspec.yaml`.
- [x] Android app name set to `ReadPp`.
- [x] Android applicationId set to `com.readpp.app`.
- [x] Native splash background aligned with Burgundy branding.
- [x] Release candidate passes `flutter analyze`.
- [x] Release candidate passes `flutter test` with 34/34 tests.
- [ ] Configure release signing keystore.
- [ ] Build release AAB with production signing.

## Visual QA

- [x] Home reviewed for first-run empty state and primary CTA.
- [x] Biblioteca reviewed for collection focus and add-book access.
- [x] Book Detail reviewed for editorial hierarchy and secondary destructive action.
- [x] Progress reviewed as premium reading dashboard.
- [x] Insights reviewed as discovery/curiosity surface.
- [x] Perfil reviewed as preferences/settings, not a dashboard.
- [x] Onboarding reviewed for first-run clarity.
- [ ] Device QA on at least one small Android phone.
- [ ] Device QA on at least one large Android phone.

## Accessibility QA

- [x] Main tappable controls keep large touch targets.
- [x] Bottom navigation labels remain visible.
- [x] Icon-only actions use tooltips where appropriate.
- [ ] Manual screen reader smoke test.
- [ ] Manual high text-scale smoke test.

## Store Assets

- [x] Store listing draft prepared.
- [x] Screenshot guide prepared.
- [x] Privacy policy draft prepared.
- [ ] Final Play Store screenshots exported.
- [ ] Final app icon reviewed on device.
- [ ] Feature graphic prepared if required.

## Policy

- [x] No authentication in v1.
- [x] No backend in v1.
- [x] No remote sync in v1.
- [x] Local-only reading data documented in privacy draft.
- [ ] Privacy policy hosted at a public URL before Play Store submission.

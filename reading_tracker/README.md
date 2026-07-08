# ReadPp

ReadPp is a Flutter application for personal reading tracking.

## Current release state

- Phase closed: Milestone 9 - UX & Product.
- Web/PWA deployed on Vercel: `https://readpp-web-alpha.vercel.app`.
- APK artifact: `build/app/outputs/flutter-apk/app-release.apk`.
- Inspected APK: `versionName=1.0.0`, `versionCode=1`, package `com.readpp.app`.
- APK SHA1: `8a771c6ab44b69cba34ad009877a1e8e3ef4b3b1`.
- Validation recorded in Memory Bank: `flutter analyze` without issues and `flutter test` 178/178.

For an Android update over an installed APK with the same package, increment `versionCode` with `--build-number` or `pubspec.yaml`.

## Product integrations

- Supabase: progressive backend for Auth and cloud synchronization.
- Auth: Email login and Google login through Supabase Auth.
- Sync: offline-first synchronization for books, reading sessions, reader profile, and annual goal.
- PWA: Flutter Web build deployed through Vercel.
- Sentry: release error observability, configured through Dart defines.
- Analytics: PostHog product analytics through the internal analytics layer, configured through Dart defines.

## Development environment

Supabase is configured with compile-time Dart defines. Create a local
`dart_defines/dev.json` file from `dart_defines/example.json` and fill it with
the project values.

Do not commit `dart_defines/dev.json` or any `*.local.json` file.

Run on Android emulator:

```sh
flutter run -d emulator-5554 --dart-define-from-file=dart_defines/dev.json
```

Run on Chrome:

```sh
flutter run -d chrome --dart-define-from-file=dart_defines/dev.json
```

Build Web:

```sh
flutter build web --release --dart-define-from-file=dart_defines/dev.json
```

Deploy Web/PWA:

```sh
cd build/web
vercel --prod
```

Deploy only from `build/web`, never from the Flutter project root.

Build APK:

```sh
flutter build apk --release --dart-define-from-file=dart_defines/dev.json --build-number=2
```

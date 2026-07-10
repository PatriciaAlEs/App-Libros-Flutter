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

The Coach also reads `OPENAI_API_KEY`, `OPENAI_MODEL`, and
`OPENAI_BASE_URL` at compile time. `flutter run -d chrome` by itself does not
read shell environment variables or `.env` files. For local Chrome debugging,
put those values in the ignored `dart_defines/dev.json` and always launch with
`--dart-define-from-file` as shown below. If `OPENAI_API_KEY` is absent, the
Coach now fails before issuing HTTP and prints `phase=configuration` in the
development console.

Do not ship a production Web build with a provider secret in Dart defines:
compile-time values are visible in browser assets. Production Web must point
`OPENAI_BASE_URL` to a same-origin or CORS-enabled server-side proxy and keep
the real provider key on that server. A browser transport failure such as
`ClientException: Failed to fetch` at `phase=http.stream.send` indicates that
the configured endpoint is unreachable from the browser or rejected by CORS.

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

For production Auth, set `AUTH_REDIRECT_URL` to the public HTTPS origin (with
its trailing slash) in the Dart defines file. Add that exact URL to Supabase
Authentication > URL Configuration > Redirect URLs. Keep the Supabase project
Site URL on the production origin as a safe fallback. Google Cloud must only
use Supabase's callback URL as its authorized redirect URI:
`https://<project-ref>.supabase.co/auth/v1/callback`.

Email/password must be enabled in Supabase Authentication > Providers. If email
confirmation is enabled, confirmation links use `AUTH_REDIRECT_URL` as well.

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

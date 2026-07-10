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

The Coach selects its LLM implementation with `LLM_PROVIDER`. Supported values
are `openai` (the default) and `gemini`. Provider configuration is read at
compile time:

- OpenAI: `OPENAI_API_KEY`, `OPENAI_MODEL`, and optional `OPENAI_BASE_URL`.
- Gemini: `GEMINI_API_KEY`, `GEMINI_MODEL`, and optional `GEMINI_BASE_URL`.

Example Gemini configuration:

```json
{
  "LLM_PROVIDER": "gemini",
  "GEMINI_API_KEY": "your-local-development-key",
  "GEMINI_MODEL": "gemini-3.5-flash",
  "GEMINI_BASE_URL": "https://generativelanguage.googleapis.com/v1beta"
}
```

`flutter run -d chrome` by itself does not read shell environment variables or
`.env` files. Put the selected provider values in the ignored
`dart_defines/dev.json` and always launch with `--dart-define-from-file` as
shown below. Missing keys/models and unknown providers fail before HTTP with a
clear configuration error in the development console.

For Gemini, `GEMINI_BASE_URL` must be the API root
`https://generativelanguage.googleapis.com/v1beta`. Do not use the
OpenAI-compatible `/openai/chat/completions` URL: `GeminiLlmClient` appends the
native `/models/{model}:generateContent` or
`/models/{model}:streamGenerateContent?alt=sse` path itself and rejects a base
URL that already contains either path. The official Google Gen AI JavaScript
SDK supports `generateContentStream` in browsers, so direct native SSE can be
used for local Flutter Web development when the endpoint and key are valid.

Do not ship a production Web build with a provider secret in Dart defines:
compile-time values are visible in browser assets. Production Web must point
the provider base URL to a same-origin or CORS-enabled server-side proxy and
keep the real OpenAI or Gemini key on that server. A browser transport failure such as
`ClientException: Failed to fetch` at `phase=http.stream.send` indicates that
the configured endpoint is unreachable from the browser or rejected by CORS.
Direct browser streaming is therefore a development-only option, not the
production deployment architecture.

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

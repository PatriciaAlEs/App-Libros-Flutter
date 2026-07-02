# ReadPp

## Getting Started

ReadPp is a Flutter application.

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
flutter build web --dart-define-from-file=dart_defines/dev.json
```

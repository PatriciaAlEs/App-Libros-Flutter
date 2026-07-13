# ReadPp

ReadPp es una app Flutter mobile-first para seguimiento personal de lectura: libros, sesiones, calendario, progreso, estadisticas e insights.

## Estado de fase

Fase actual cerrada: Hito 9 - UX & Product.

- Web/PWA lista y desplegada en Vercel.
- Supabase integrado como backend progresivo para Auth y sincronizacion.
- Login con Email y Google disponible mediante Supabase Auth.
- Sincronizacion multi-dispositivo validada para biblioteca, sesiones, perfil lector y objetivo anual.
- Sentry documentado como observabilidad de errores de release.
- PostHog documentado como analytics de producto.
- Validacion de cierre registrada: `flutter analyze` sin issues y `flutter test` 178/178.

## Versiones registradas

- Web/PWA: desplegada en `https://readpp-web-alpha.vercel.app`.
- APK generada: `reading_tracker/build/app/outputs/flutter-apk/app-release.apk`.
- APK actual inspeccionada: `versionName=1.0.0`, `versionCode=1`, package `com.readpp.app`.
- SHA1 APK: `8a771c6ab44b69cba34ad009877a1e8e3ef4b3b1`.

Nota: para publicar una APK como actualizacion sobre otra instalacion Android con el mismo paquete, el siguiente build debe incrementar `versionCode` mediante `--build-number` o `pubspec.yaml`.

## Despliegue Web/PWA

El despliegue oficial se hace desde los artefactos generados por Flutter, nunca desde la raiz del proyecto:

```sh
cd reading_tracker
flutter build web --release --dart-define-from-file=dart_defines/dev.json \
  --dart-define=AUTH_REDIRECT_URL=https://readpp-web-alpha.vercel.app/
cd build/web
vercel --prod
```

Proyecto Vercel: `readpp-web-alpha`.

URL publica: `https://readpp-web-alpha.vercel.app`.

## Build APK

```sh
cd reading_tracker
flutter build apk --release --dart-define-from-file=dart_defines/dev.json --build-number=2
```

Salida esperada:

```text
reading_tracker/build/app/outputs/flutter-apk/app-release.apk
```

## Configuracion

La configuracion sensible se inyecta por `dart-define` / `dart-define-from-file`.

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `SENTRY_DSN`
- `SENTRY_ENVIRONMENT`
- `SENTRY_RELEASE`
- `ANALYTICS_ENABLED`
- `POSTHOG_API_KEY`
- `POSTHOG_HOST`
- `APP_ENV`

No commitear `dart_defines/dev.json`, claves reales, DSNs ni archivos `*.local.json`.

## Memory Bank

La fuente viva para agentes IA esta en:

- [memory-bank/projectbrief.md](memory-bank/projectbrief.md)
- [memory-bank/product-requirements.md](memory-bank/product-requirements.md)
- [memory-bank/architecture.md](memory-bank/architecture.md)
- [memory-bank/current-state.md](memory-bank/current-state.md)
- [memory-bank/active-context.md](memory-bank/active-context.md)
- [memory-bank/progress.md](memory-bank/progress.md)
- [memory-bank/decisions.md](memory-bank/decisions.md)

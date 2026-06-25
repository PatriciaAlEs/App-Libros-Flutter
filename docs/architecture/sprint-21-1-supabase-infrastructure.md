# Sprint 21.1 - Infraestructura Supabase

## Objetivo del sprint

Preparar la infraestructura inicial de Supabase para ReadPp sin modificar todavia la logica funcional de la aplicacion.

Este sprint define donde debe vivir la configuracion de Supabase, que dependencias seran necesarias, que variables se usaran y como deberia integrarse el cliente en la arquitectura Flutter existente.

Queda fuera de alcance:

- Implementar Auth.
- Crear tablas en Supabase.
- Modificar Drift.
- Modificar `pubspec.yaml`.
- Crear cliente Supabase en codigo.
- Crear pantallas de login.
- Cambiar la logica de biblioteca, progreso, estadisticas o insights.

## Estado actual relevante

ReadPp vive dentro del proyecto Flutter `reading_tracker`.

Estado tecnico actual:

- App Flutter con Riverpod.
- Persistencia local con Drift + SQLite.
- `reading_tracker/lib/core/database` contiene la infraestructura local de base de datos.
- `reading_tracker/lib/core/observability` contiene la integracion transversal de Sentry.
- `reading_tracker/lib/core/analytics` contiene la integracion transversal de PostHog.
- `reading_tracker/lib/features` contiene los dominios funcionales: books, reading_sessions, stats, insights, onboarding, settings, progress, home y navigation.
- `main.dart` inicializa Sentry antes de ejecutar `ProviderScope`.
- Los providers actuales se definen con Riverpod y se inyectan desde capas `core` o `features`.

Decision arquitectonica vigente:

- ReadPp sigue una arquitectura Offline First / Local First.
- Drift es la fuente de verdad durante el uso normal de la app.
- Supabase sera backend progresivo para autenticacion, sincronizacion y recuperacion entre dispositivos.
- Supabase no debe sustituir a Drift como fuente principal de ejecucion.

Referencia:

- `docs/adr/ADR-001-local-first.md`
- `docs/hito-7-supabase-architecture.md`

## Dependencias previstas

Dependencia principal prevista:

- `supabase_flutter`

Motivo:

- SDK oficial de Supabase para Flutter.
- Incluye cliente Supabase.
- Integra Supabase Auth.
- Soporta Web, Android e iOS.
- Encaja con el objetivo de usar Supabase para Auth y backend progresivo.

Dependencias que no se preve agregar en Sprint 21.1:

- SDKs externos de OAuth fuera de Supabase.
- Dependencias especificas de Google Sign-In hasta definir el flujo exacto de Auth v1.
- Librerias de sincronizacion automatica.
- Generadores de schema remoto.

La adicion de dependencias queda reservada para el siguiente sprint de implementacion.

## Variables necesarias

La configuracion debe entrar por `--dart-define`, sin hardcodear valores en repositorio.

Variables previstas:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

Reglas:

- Si falta alguna variable, la app debe seguir arrancando sin backend.
- En debug debe poder ejecutarse sin Supabase configurado.
- En release no debe fallar si Supabase no esta configurado, mientras Auth y sync no sean obligatorios.
- No se deben guardar claves reales en documentacion, Memory Bank ni codigo.

Ejemplo futuro de ejecucion:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://example.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=example-anon-key
```

## Ubicacion propuesta para inicializacion de Supabase

Ubicacion propuesta:

- `reading_tracker/lib/core/backend/readpp_supabase.dart`

Responsabilidad:

- Leer `SUPABASE_URL` y `SUPABASE_ANON_KEY` desde `String.fromEnvironment`.
- Exponer si Supabase esta configurado.
- Inicializar Supabase una sola vez.
- Permitir que la app arranque aunque Supabase no este configurado.
- Mantener la inicializacion fuera de widgets y pantallas.

Patron esperado:

- Similar en espiritu a `ReadPpSentry`.
- Transversal y ubicado bajo `core`.
- Sin dependencia de features concretas.
- Sin acoplar UI directamente al SDK.

Punto de entrada previsto:

- `reading_tracker/lib/main.dart`

Orden previsto:

1. `WidgetsFlutterBinding.ensureInitialized()`.
2. Inicializacion de Sentry.
3. Inicializacion de Supabase si esta configurado.
4. `runApp(const ProviderScope(child: App()))`.

Detalle a decidir en implementacion:

- Si `ReadPpSentry.init` sigue envolviendo todo el `appRunner`.
- Si se crea un bootstrap propio para ordenar inicializaciones transversales.
- Si Supabase se inicializa dentro del `appRunner` o antes de invocar Sentry.

La regla principal es que un fallo o ausencia de configuracion de Supabase no debe impedir el arranque local de ReadPp.

## Ubicacion propuesta para providers y repositorios futuros

### Infraestructura transversal

Ubicacion propuesta:

- `reading_tracker/lib/core/backend`

Responsabilidades futuras:

- Cliente Supabase.
- Estado de disponibilidad/configuracion de backend.
- Providers transversales del cliente.
- Helpers de configuracion por entorno.

Archivos futuros posibles:

- `readpp_supabase.dart`
- `supabase_client_provider.dart`

### Autenticacion

Ubicacion propuesta:

- `reading_tracker/lib/features/auth`

Estructura futura sugerida:

- `features/auth/data`
- `features/auth/domain`
- `features/auth/presentation`

Responsabilidades futuras:

- Sesion del usuario.
- Login con Google.
- Login con correo y contrasena.
- Logout.
- Recuperacion de sesion.
- Estado autenticado/no autenticado.

### Sincronizacion

Ubicacion propuesta:

- `reading_tracker/lib/core/sync`

Responsabilidades futuras:

- Orquestacion de sync.
- Mapeo `local_id` <-> `remote_id`.
- Estados de sincronizacion.
- Politica de conflicto.
- Soft delete.

La sincronizacion se propone como capa transversal porque afectara a varios dominios: libros, sesiones, preferencias y reto lector.

### Repositorios de dominio

Los repositorios existentes deben seguir priorizando Drift como fuente de verdad.

Cuando se incorpore sync, los repositorios de dominio no deberian leer directamente de Supabase para alimentar la UI principal. En su lugar, deberian:

- Escribir y leer en Drift.
- Delegar sincronizacion a una capa de sync.
- Mantener la experiencia offline intacta.

## Riesgos tecnicos

- Inicializar Supabase como dependencia obligatoria y romper el arranque sin backend.
- Introducir llamadas directas a Supabase desde pantallas.
- Saltarse Drift y romper la decision Local First.
- Mezclar Auth, sync y schema remoto en un unico sprint.
- Guardar claves reales en codigo o documentacion.
- Tratar `SUPABASE_ANON_KEY` como secreto de servidor. Es publica para cliente, pero no debe hardcodearse.
- Acoplar demasiado pronto los repositorios actuales a modelos remotos.
- Crear rutas de login antes de definir el estado de sesion y el comportamiento offline.
- Romper Web/PWA si la inicializacion no contempla Flutter Web.

## Pasos de implementacion previstos para el siguiente sprint

Propuesta para Sprint 21.2:

1. Anadir dependencia `supabase_flutter`.
2. Crear `reading_tracker/lib/core/backend/readpp_supabase.dart`.
3. Leer `SUPABASE_URL` y `SUPABASE_ANON_KEY` mediante `String.fromEnvironment`.
4. Crear inicializacion segura y opcional de Supabase.
5. Crear provider Riverpod para exponer el cliente solo cuando este configurado.
6. Integrar la inicializacion en el arranque sin modificar flujos funcionales.
7. Validar arranque sin variables Supabase.
8. Validar arranque con variables Supabase.
9. Mantener Drift, biblioteca, progreso, estadisticas e insights sin cambios funcionales.

No deberian incluirse todavia:

- Pantallas de login.
- Flujo de Google.
- Flujo de correo/contrasena.
- Tablas remotas.
- Sincronizacion.
- Migraciones Drift.

## Criterios de validacion

Para considerar valida la infraestructura inicial cuando se implemente:

- `flutter analyze` OK.
- `flutter test` OK.
- La app sigue funcionando sin backend configurado.
- La app arranca con `SUPABASE_URL` y `SUPABASE_ANON_KEY`.
- No se rompe Drift.
- No se altera la experiencia offline.
- No se modifica la logica de biblioteca, progreso, estadisticas ni insights.
- No hay claves reales hardcodeadas.
- Web/PWA sigue compilando cuando corresponda.

## Resultado esperado de Sprint 21.1

Este sprint no implementa Supabase en codigo. Su resultado es una propuesta tecnica clara para integrar Supabase respetando la arquitectura Offline First / Local First de ReadPp.

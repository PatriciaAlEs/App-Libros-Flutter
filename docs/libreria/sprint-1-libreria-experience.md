# Sprint 1 — LibrerIA Experience

> Estado: COMPLETADO  
> Fecha de cierre: 9 de julio de 2026  
> Alcance: exclusivamente Sprint 1

## Objetivo

Introducir la feature LibrerIA, su entrada de navegación, una experiencia visual base honesta y el esqueleto del Engine, sin implementar contexto, herramientas, proveedor de IA ni conversación funcional.

## Alcance entregado

### Feature LibrerIA

- Nueva feature organizada en `domain` y `presentation`.
- Modelos de request, response, ruta del Engine y estado de presentación.
- Provider raíz de Engine y estado de UI.
- Feature flag por compilación:

```sh
--dart-define=LIBRERIA_ENABLED=true
```

Para ocultar la entrada:

```sh
--dart-define=LIBRERIA_ENABLED=false
```

El valor por defecto es `true`.

### Navegación

- Nueva ruta `/libreria`.
- Soporte de apertura directa mediante el shell principal.
- Argumentos contextuales tipados:
  - pantalla de origen;
  - `bookId` opcional;
  - periodo opcional.
- Retorno seguro a la pantalla anterior.
- Entrada principal desde Inicio, detrás del feature flag.
- La barra inferior se conserva al abrir LibrerIA desde el shell.

### UI base

- Pantalla `LibreriaScreen` alineada con los temas Burgundy y Forest.
- Propósito especializado visible.
- Contenedor honesto para futuros insights, sin consultar ni inventar datos.
- Preguntas sugeridas limitadas a intents del MVP.
- Campo de mensaje deshabilitado: no simula una conversación aún inexistente.
- Estados base:
  - inicial;
  - carga;
  - respuesta;
  - error;
  - no disponible.
- Componentes base:
  - entrada de LibrerIA;
  - tarjeta de métrica;
  - tarjeta de libro;
  - tarjeta de límite/error.
- Semantics, tooltips, foco estándar y prueba con texto ampliado.

### Engine Skeleton

- Contrato `LibreriaEngine`.
- `LibreriaRequest` y `LibreriaResponse` independientes de Flutter UI.
- Rutas declaradas:
  - `localDeterministic`;
  - `llmAssisted`;
  - `clarification`;
  - `unsupported`;
  - `actionConfirmation`.
- Implementación temporal `SkeletonLibreriaEngine`.
- Mensaje vacío produce aclaración.
- Petición claramente ajena a lectura se rechaza como `unsupported`.
- Petición lectora reconocida no se ejecuta y comunica que la capacidad aún no está disponible.

## Límites respetados

No se ha implementado ninguna tarea de Sprint 2:

- no existe ContextBuilder;
- no existe Tool Manager;
- no existen Tool Contracts;
- no existe `AiProvider` ni fake;
- no se consultan repositorios de libros, sesiones o estadísticas desde LibrerIA;
- no hay memoria de conversación;
- no hay llamadas de red;
- no hay acciones ni mutaciones.

Drift y Supabase no han sido modificados.

## Archivos principales

```text
reading_tracker/lib/features/libreria/
  libreria_feature_flags.dart
  domain/
    entities/
    enums/
    services/
  presentation/
    models/
    providers/
    screens/
    widgets/
```

Integraciones acotadas:

- `reading_tracker/lib/app.dart`
- `reading_tracker/lib/features/navigation/presentation/screens/main_navigation_screen.dart`
- `reading_tracker/lib/features/home/presentation/screens/home_screen.dart`
- `reading_tracker/lib/core/design_system/icons/app_icons.dart`

Tests:

- `reading_tracker/test/libreria_engine_test.dart`
- `reading_tracker/test/libreria_screen_test.dart`

## Criterios de aceptación

- [x] Feature flag permite mostrar u ocultar la entrada.
- [x] LibrerIA abre dentro del shell principal.
- [x] Los argumentos de navegación son tipados.
- [x] La pantalla comunica un propósito exclusivamente lector.
- [x] Los controles todavía no disponibles aparecen deshabilitados.
- [x] Estados inicial, error y no disponible están cubiertos.
- [x] La UI soporta texto ampliado sin excepciones.
- [x] El Engine no depende de UI, base de datos, red ni proveedor.
- [x] Las peticiones fuera de dominio se rechazan.
- [x] No hay tareas de Sprint 2 implementadas.

## Validación

### Tests focales

```text
flutter test --no-pub test/libreria_engine_test.dart test/libreria_screen_test.dart
9/9 tests OK
```

### Suite completa

```text
flutter test --no-pub
190/190 tests OK
```

### Análisis estático

```text
flutter analyze --no-pub
No issues found
```

### Targets

```text
flutter build web --debug --no-pub --dart-define=LIBRERIA_ENABLED=true
OK: build/web

flutter build apk --debug --no-pub --dart-define=LIBRERIA_ENABLED=true
OK: build/app/outputs/flutter-apk/app-debug.apk
```

La compilación Web informa una advertencia preexistente del dry run Wasm por `ua_client_hints` y `dart:html`; no bloquea el build Web estándar.

## Definition of Done

- [x] Alcance de Sprint 1 implementado.
- [x] Código formateado.
- [x] Tests focales y suite completa en verde.
- [x] Análisis estático limpio.
- [x] Build Web debug correcto.
- [x] Build Android debug correcto.
- [x] Estados y accesibilidad base cubiertos por widget tests.
- [x] Sin secretos, SDKs de IA ni telemetría de contenido.
- [x] Documentación y backlog actualizados.

## Siguiente gate

Sprint 1 queda cerrado. No se debe comenzar Sprint 2 hasta que el usuario lo autorice explícitamente.

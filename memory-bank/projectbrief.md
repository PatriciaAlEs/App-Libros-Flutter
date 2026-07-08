# Project Brief

## Producto

`reading_tracker` es una app Flutter para seguimiento personal de lectura. La app permite guardar libros, cambiar su estado, registrar sesiones de lectura, consultar actividad en calendario, ver estadisticas e insights de lectura.

## Estado real del MVP

El proyecto ya contiene una app funcional en `reading_tracker/` con:

- Flutter y Dart.
- Riverpod para estado e inyeccion.
- Drift + SQLite para persistencia local.
- Busqueda de libros usando Open Library.
- Calendario mensual/semanal y detalle de dia.
- Stats implementado con datos reales.
- Reading Insights Sprint 1 implementado: libro mas leido, autor mas leido y genero favorito.
- Reading Insights Sprint 2 implementado: ritmo de lectura, prediccion simple de fin de libro y forecast anual.
- Reading Insights Sprint 3 implementado: Top Lecturas del Año y Ranking Personal.
- Reading Insights Sprint 4 implementado: perfil lector premium con mejores lecturas y curiosidades.
- Hito 5 Sprint 1 implementado: navegacion principal con tabs Inicio, Biblioteca, Progreso, Insights y Ajustes.
- Hito 5 Sprint 2 implementado: Design System base con temas Burgundy/Forest, tokens visuales y componentes reutilizables.
- Hito 5 Sprint 2.5 implementado: Branding & Visual Identity para ReadPp.
- Hito 5 Sprint 3 implementado: Home Premium Redesign como biblioteca personal moderna.
- Hito 6 Sprint 18.x implementado: Alpha Testing & Polish con Android QA, shared header/card, calendario/diario refinados, reto lector pulido, busqueda multi-fuente, deduplicacion, alta manual, escaneo ISBN y portada local.
- Busqueda de libros actual: `BookSearchRepository` coordina Open Library como proveedor primario, Google Books como fallback y alta manual como ultima opcion.
- Persistencia actual de libros incluye identificadores externos `externalSource` y `externalId` para deduplicacion entre proveedores.
- Estado actual: Hito 9 UX & Product completado, Web/PWA lista en Vercel, APK de cierre generada y base preparada para Beta publica.
- Validacion vigente de cierre: `flutter analyze` sin issues y `flutter test` 178/178.
- Web/PWA vigente: `https://readpp-web-alpha.vercel.app`.
- APK registrada: package `com.readpp.app`, `versionName=1.0.0`, `versionCode=1`, SHA1 `8a771c6ab44b69cba34ad009877a1e8e3ef4b3b1`.
- Supabase integrado como backend progresivo para Auth y sincronizacion, manteniendo Drift/SQLite como fuente de verdad local.
- Auth completado con Login Email y Login Google.
- Sync completada para Books, Reading Sessions, Reader Profile y Annual Goal, con sincronizacion automatica, descarga remota, upload local y estado visible.
- Observabilidad completada con Sentry por `dart-define`.
- Analytics completado con PostHog mediante `ReadPpAnalytics` y configuracion por `dart-define`.
- Roadmap: Beta publica, AI Assistant, automatizaciones y mejoras de producto.

## Principios de documentacion

- Documentar solo lo que existe en el repositorio.
- Marcar como parcial cualquier feature incompleta.
- Evitar planes especulativos sobre backend, autenticacion, pagos o servicios no presentes.
- Mantener la memoria util para agentes IA sin convertirla en documentacion corporativa.

## Objetivo de la memoria

Ayudar a agentes como Cursor, Codex o Claude a entender rapidamente el producto, la arquitectura real, el estado actual y las tareas pendientes sin inventar funcionalidades futuras.

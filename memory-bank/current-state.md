# Current State

## Estado actual

`reading_tracker` ya tiene una base funcional con Flutter, Riverpod y Drift. La app vive dentro de `reading_tracker/`; la raiz del repo contiene contexto y documentacion operativa.

## Implementado

- Entrada en `reading_tracker/lib/main.dart` y rutas en `reading_tracker/lib/app.dart`.
- Feature `books` con busqueda/alta desde Open Library, listado, detalle, cambio de estado y eliminacion.
- Feature `reading_sessions` con entidad, repositorio, DAO, calendario, detalle de dia y formulario de sesion.
- Feature `stats` parcialmente implementada: existen calculadora, provider, pantalla, widget y tests, pero no esta cerrada funcionalmente como seccion final del MVP.
- Drift con tablas `books` y `reading_sessions`, `schemaVersion = 2`.
- Seed data de debug en `core/database/database_seed.dart`.

## Trabajo reciente

- Vista mensual del calendario optimizada para mobile.
- Vista semanal convertida en agenda vertical por dia.
- Detalle de dia conectado desde celdas del calendario.
- Formulario de sesion conectado a Drift y filtrado hacia libros en lectura.

## Pendientes visibles

- Pulir consistencia de textos en espanol sin mojibake.
- Editar/eliminar sesiones desde el detalle del dia.
- Ampliar tests de sesiones, repositorios/DAO y calendario si aplica.
- Cerrar funcionalmente `stats` con datos reales y UX validada.
- Revisar experiencia responsive en pantallas muy estrechas.

## Nota de entorno

En el sandbox, `flutter analyze` puede quedarse bloqueado por permisos de AppData. Como alternativa comprobada, redirigir `APPDATA`/`LOCALAPPDATA` al workspace y ejecutar `dart analyze` desde `reading_tracker`.

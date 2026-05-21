# Progress

## Completado

- App Flutter ubicada en `reading_tracker/`.
- Rutas principales definidas en `lib/app.dart`.
- Arquitectura por features: `books`, `reading_sessions`, `stats`.
- Persistencia local con Drift para `books` y `reading_sessions`.
- Conexion IO con SQLite en archivo local.
- Conexion web con IndexedDB usando Drift `WebDatabase`.
- Busqueda de libros contra Open Library.
- Listado, detalle, cambio de estado y eliminacion de libros.
- Registro de sesiones de lectura.
- Calendario mensual, calendario semanal y detalle de dia.
- Seed data de debug si la base esta vacia.
- Tests existentes para calculos de Stats y pantalla inicial de libros.
- Memory bank y reglas Cursor iniciales.

## Parcial

- `stats`: hay calculadora, provider, pantalla, widgets y test de calculo; falta cerrar UX/textos y validar que la seccion cumple el MVP.
- Textos de UI: hay mezcla de ingles/espanol y mojibake visible en algunas pantallas.

## Pendiente

- Editar/eliminar sesiones desde detalle de dia.
- Validar persistencia manual tras refresh.
- Ampliar tests de sesiones/repositorios/DAO si se estabiliza la feature.
- Decidir fuente principal de contexto: `CONTEXT.md` legacy vs `memory-bank/*`.

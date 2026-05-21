# Architecture

## Resumen real

La app usa una arquitectura Flutter simple por features. No hay backend, autenticacion ni servicios remotos propios. La persistencia es local con Drift + SQLite/IndexedDB y el estado se gestiona con Riverpod.

## Estructura

```text
reading_tracker/lib/
  core/
    database/
    theme/
    utils/
  features/
    books/
      data/
      domain/
      presentation/
    reading_sessions/
      data/
      domain/
      presentation/
    stats/
      domain/
      presentation/
```

## Core

- `core/database`: Drift, tablas, DAOs, conexion por plataforma y seed data.
- `core/theme`: tema Material compartido.
- `core/utils`: utilidades de fecha e IDs.

## Features

- `books`: busqueda Open Library, repositorio, entidad `Book`, estado de libro y UI de listado/detalle/formulario.
- `reading_sessions`: entidad `ReadingSession`, repositorio, calendario, detalle de dia y formulario de sesion.
- `stats`: calculos, provider y pantalla. Estado parcial.

## Persistencia

- `AppDatabase` tiene `schemaVersion = 2`.
- Tablas: `books`, `reading_sessions`.
- IO: `NativeDatabase` sobre `reading_tracker.sqlite`.
- Web: `WebDatabase` con IndexedDB (`reading_tracker`).
- Seed debug en `DatabaseSeeder`, solo si la base esta vacia.

## Estado

- Riverpod se usa para providers de repositorios, base de datos, libros, sesiones y stats.
- `booksProvider` usa `AsyncNotifier`.
- Sesiones por rango usan `StreamProvider.family`.
- Sesiones por dia usan `FutureProvider.family`.
- `statsProvider` calcula con libros y sesiones reales desde repositorios/DAO.

## Integraciones reales

- Open Library Search API: `https://openlibrary.org/search.json`.
- Open Library Covers: `https://covers.openlibrary.org/b/id/{coverId}-M.jpg`.
- No hay Firebase, Stripe, backend propio, login ni sincronizacion remota.

## Herramientas externas relevantes

- Flutter SDK / Dart SDK.
- Riverpod.
- Drift, `drift_dev` y `build_runner`.
- SQLite local y IndexedDB en web via Drift.
- Cursor rules en `.cursor/rules`.
- Memory bank en `memory-bank/`.

## Decisiones arquitectonicas registradas

### Arquitectura por features

- Decision: organizar la app en `features/books`, `features/reading_sessions` y `features/stats`, con `core` para infraestructura compartida.
- Motivo observado: separar funcionalidades de producto y mantener infraestructura comun fuera de pantallas concretas.
- Evidencia: estructura bajo `reading_tracker/lib/features/` y `reading_tracker/lib/core/`.

### Capas `domain`, `data` y `presentation`

- Decision: separar entidades/contratos, repositorios/mappers y UI/providers.
- Motivo observado: las entidades de dominio no importan Drift ni Flutter UI, mientras los mappers y repositorios concretos viven en `data`.
- Evidencia: `features/books/domain/entities/book.dart`, `features/reading_sessions/domain/entities/reading_session.dart`, `features/books/data/mappers/book_mapper.dart`, `features/reading_sessions/data/mappers/reading_session_mapper.dart`.

### Riverpod para estado e inyeccion

- Decision: usar Riverpod para providers de base de datos, repositorios y estado de UI.
- Motivo observado: centralizar acceso a dependencias y exponer datos async/stream a pantallas.
- Evidencia: `databaseProvider`, `bookRepositoryProvider`, `booksProvider`, `readingSessionsForRangeProvider`, `statsProvider`.

### Drift para persistencia local

- Decision: usar Drift con tablas y DAOs para libros y sesiones.
- Motivo observado: persistir datos reales localmente y consultar sesiones por rango/dia.
- Evidencia: `AppDatabase`, `BooksTable`, `ReadingSessionsTable`, `BookDao`, `ReadingSessionDao`.

### Persistencia por plataforma

- Decision: usar SQLite nativo en IO y IndexedDB en web mediante Drift.
- Motivo observado: mantener persistencia local en distintas plataformas Flutter.
- Evidencia: `database_connection_io.dart` usa `NativeDatabase`; `database_connection_web.dart` usa `WebDatabase.withStorage(DriftWebStorage.indexedDb('reading_tracker'))`.

### Navegacion centralizada con rutas nombradas

- Decision: definir rutas en `MaterialApp.onGenerateRoute`.
- Motivo observado: centralizar navegacion entre listado, detalle de libro, calendario, detalle de dia, alta de sesion y stats.
- Evidencia: `reading_tracker/lib/app.dart` contiene rutas `/`, `/book/add`, `/book/detail`, `/calendar`, `/calendar/day`, `/session/add`, `/stats`.

### Seed data solo en debug

- Decision: poblar datos de prueba solo en debug y si la base esta vacia.
- Motivo observado: facilitar desarrollo sin mezclar seed con pantallas ni duplicar datos.
- Evidencia: `DatabaseSeeder.seedIfNeeded()` usa `kDebugMode`, consulta libros existentes e inserta libros/sesiones iniciales.

## Mantenimiento continuo

Al actualizar esta documentacion:

- Conservar informacion valida existente.
- Evitar sobrescribir decisiones previas confirmadas.
- Anadir solo cambios detectados en codigo o documentos del repo.
- Marcar como parcial cualquier funcionalidad incompleta.
- Mantener archivos cortos, accionables y sin especulacion sobre integraciones futuras.

## Reglas para agentes IA

- No introducir capas nuevas si una feature local basta.
- No documentar integraciones futuras como existentes.
- Mantener `domain` libre de Drift.
- Si cambian tablas/DAOs, ejecutar build_runner y revisar migracion.

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
      data/
      domain/
      presentation/
    insights/
      data/
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
- `stats`: calculos, provider y pantalla.
- `insights`: perfil lector calculado desde libros y sesiones, con preferencias, mejores lecturas y curiosidades.

## Persistencia

- `AppDatabase` tiene `schemaVersion = 4`.
- Tablas: `books`, `reading_sessions`.
- Tabla manual adicional: `app_settings` para configuracion simple como `annualReadingGoal`.
- IO: `NativeDatabase` sobre `reading_tracker.sqlite`.
- Web: `WebDatabase` con IndexedDB (`reading_tracker`).
- Seed debug en `DatabaseSeeder`, solo si la base esta vacia.

## Estado

- Riverpod se usa para providers de repositorios, base de datos, libros, sesiones y stats.
- `booksProvider` usa `AsyncNotifier`.
- Sesiones por rango usan `StreamProvider.family`.
- Sesiones por dia usan `FutureProvider.family`.
- `statsProvider` calcula con libros y sesiones reales desde repositorios/DAO.
- `statisticsSummaryProvider` expone la base nueva de Estadisticas MVP calculada desde libros y sesiones cuando aplica.
- `readingInsightsSummaryProvider` expone insights calculados desde libros y sesiones reales.

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

### Reading sessions como base de Hito 3

- Decision: reutilizar `ReadingSession` y la funcionalidad existente de "ratos de lectura" como base de Reading Sessions & Activity Tracking.
- Motivo observado: ya existe entidad de dominio, tabla Drift, DAO, repositorio, providers por dia/rango y UI de calendario/formulario.
- Deuda observada: falta `pagesRead` estructurado, `updatedAt` y consulta por libro; Home guarda paginas en la nota al crear sesiones desde avance rapido.
- Evidencia: `features/reading_sessions/domain/entities/reading_session.dart`, `core/database/tables/reading_sessions_table.dart`, `features/reading_sessions/presentation/providers/reading_sessions_provider.dart`.

### Consolidacion minima de ReadingSession

- Decision: ampliar `ReadingSession` existente con `pagesRead` y `updatedAt`, sin crear una entidad nueva.
- Persistencia: `reading_sessions.pages_read` usa default `0`; `reading_sessions.updated_at` es nullable para mantener compatibilidad con datos anteriores.
- Migracion: `schemaVersion = 4`, con `addColumn` para ambas columnas.
- Caso de uso: `RegisterReadingSession` centraliza alta de sesion y actualizacion de progreso del libro.
- Consulta nueva: `ReadingSessionRepository.getSessionsForBook(bookId)` devuelve sesiones por libro ordenadas por fecha descendente y `createdAt` descendente.
- Finalizacion inteligente: la decision de completar tras alcanzar `totalPages` vive en presentacion y exige confirmacion del usuario antes de cambiar `Book.status`; reutiliza `CompletionReviewSheet`.

### Reading streaks

- Decision: calcular rachas desde `ReadingSession` sin tablas, migraciones ni entidades nuevas.
- `StatisticsSummary` expone `currentStreakDays` y `bestStreakDays`.
- `StatisticsCalculator` agrupa sesiones por fecha normalizada y mantiene la logica fuera de widgets.
- `BookStatisticsRepository` combina libros, objetivo anual y sesiones existentes para construir el resumen de `/stats`.
- Las metricas avanzadas de actividad tambien viven en `StatisticsCalculator` y reutilizan sesiones existentes: semana actual, mes actual, promedios por dia activo y dia mas activo.

### Calendario por intensidad

- Decision: enriquecer el calendario con un modelo local de presentacion (`ReadingDayActivity`) calculado desde sesiones existentes.
- La intensidad diaria se basa primero en paginas leidas: 1-20 baja, 21-50 media, 51+ alta; si no hay paginas pero si minutos, baja.
- No requiere tablas, migraciones, paquetes ni entidades de persistencia nuevas.

### Reading Insights Sprint 1

- Decision: crear una feature propia `features/insights` respetando Clean Architecture y Repository Pattern.
- `ReadingInsightsSummary` vive en dominio y no depende de Drift ni Flutter.
- `InsightsRepository` define el contrato y `InsightsRepositoryImpl` combina `BookRepository` con `ReadingSessionRepository`.
- El calculo usa `ReadingSession.pagesRead` como fuente de paginas leidas, sin migraciones ni campos nuevos.
- Libro mas leido: libro con mayor numero de paginas leidas acumuladas en sesiones.
- Autor mas leido: autor con mas paginas leidas acumuladas entre sus libros.
- Genero favorito: genero con mas paginas leidas acumuladas usando `Book.genre`.
- Si `Book.genre` no existe en un libro o esta vacio, se ignora para el insight de genero y la UI muestra fallback cuando no hay datos.
- La ruta `/insights` muestra `InsightsScreen` con tres cards simples.
- En Sprint 1 no se implementaron predicciones, IA ni Sprint 2.

### Reading Insights Sprint 2

- Decision: extender la feature `features/insights` existente sin crear tablas nuevas ni servicios externos.
- `ReadingInsightsSummary` incorpora metricas de ritmo, prediccion de fin de libro y forecast anual.
- Paginas por sesion: promedio de `ReadingSession.pagesRead` en sesiones con paginas leidas.
- Minutos por sesion: promedio de `ReadingSession.minutes` en sesiones con minutos registrados.
- Paginas por dia: paginas leidas acumuladas divididas entre dias activos con paginas.
- Prediccion de fin de libro: usa el libro `reading` mas reciente con `totalPages` y `currentPage`, calcula paginas restantes y divide por el ritmo reciente de paginas por dia activo del propio libro.
- Forecast anual: cuenta libros `completed` con `finishedAt/completedDate` del ano actual y proyecta linealmente al final del ano.
- La UI de `/insights` mantiene cards simples y agrega secciones `Reading Pace`, `Finish Prediction` y `Annual Forecast`.
- No se implementaron rankings ni dashboard premium.

### Reading Insights Sprint 3

- Decision: extender la feature `features/insights` existente sin crear tablas nuevas, dependencias externas ni IA.
- `ReadingInsightsSummary` incorpora Top Lecturas del Año y Ranking Personal.
- Top Lecturas del Año usa libros y sesiones del año actual cuando hay fecha disponible.
- Mejor valorado: libro `completed` del año actual con mayor `rating`.
- Mas largo: libro `completed` del año actual con mayor `totalPages`.
- Mas tiempo invertido: libro con mas minutos acumulados en `ReadingSession` durante el año actual.
- Mas sesiones: libro con mas sesiones registradas durante el año actual.
- Ranking Personal: Top 3 autores, generos y libros por paginas leidas acumuladas desde `ReadingSession.pagesRead`.
- Mejor racha: se reutiliza `StatisticsCalculator` para no duplicar la logica existente de rachas.
- La UI de `/insights` mantiene cards simples y agrega secciones `Top Lecturas del Año` y `Ranking Personal`.
- No se implemento dashboard premium.

### Reading Insights Sprint 4

- Decision: reorganizar `/insights` como perfil lector premium, no como segunda pantalla de estadisticas.
- La UI elimina `Finish Prediction`, `Annual Forecast`, `Ranking Personal` y `Mejor racha`.
- La UI queda organizada en `Tu perfil lector`, `Tus mejores lecturas` y `Curiosidades`.
- `Tu perfil lector`: autor favorito y genero favorito por paginas acumuladas, mas libro con mas minutos acumulados durante el año actual.
- `Tus mejores lecturas`: Top 3 libros completados del año actual ordenados por `rating` descendente y titulo como desempate.
- `Curiosidades`: libro completado mas largo del año actual, mes con mas actividad, franja horaria habitual y dia mas activo.
- Mes y dia mas activos se calculan desde `ReadingSession.pagesRead` y usan minutos como desempate/fallback.
- La franja habitual usa `ReadingSession.createdAt` porque la fecha de sesion se normaliza a dia y no conserva hora de lectura real.
- No se agregan tablas, migraciones, servicios externos ni dependencias.
- Se conservan campos legacy del resumen para mantener compatibilidad de tests y calculos existentes, aunque la UI ya no los muestra.

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

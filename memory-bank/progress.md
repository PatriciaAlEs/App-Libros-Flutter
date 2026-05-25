# Progress

## Completado

- Base Flutter creada para `reading_tracker`.
- Arquitectura por features con dominio, data y presentation.
- Riverpod configurado para estado e inyeccion.
- Persistencia Drift + SQLite.
- Modelos principales de libros y sesiones.
- Pantalla de libros / Biblioteca.
- Detalle de libro.
- Formulario de alta/edicion de libro.
- Registro de sesiones de lectura.
- Calendario de lectura.
- Estadisticas basicas iniciales.
- Base desacoplada para Estadisticas MVP creada sobre `Book`.
- Modelo `StatisticsSummary` creado.
- Calculador puro `StatisticsCalculator` creado fuera de widgets.
- Contrato `StatisticsRepository` e implementacion `BookStatisticsRepository` creados.
- Caso de uso `GetStatisticsSummary` creado.
- Provider `statisticsSummaryProvider` creado como punto unico de consumo futuro.
- Estadisticas MVP base calculan libros totales, completados, leyendo, pausados, abandonados, pendientes, paginas leidas, rating medio y lecturas actuales.
- Pantalla `/stats` conectada a `statisticsSummaryProvider`.
- UI basica de Estadisticas MVP creada con tarjetas simples.
- Estados loading, error, empty y datos disponibles cubiertos en Stats.
- Mutaciones de libros invalidan `statisticsSummaryProvider` para refrescar la UI basica de Stats.
- Objetivo anual de libros persistido como `annualReadingGoal`.
- Progreso anual calculado desde libros completados en el ano actual.
- Seccion "Objetivo anual" integrada en `/stats`.
- Dialogo simple para definir/editar meta anual.
- Busqueda con Open Library.
- Open Library autorrellena `totalPages` con `number_of_pages` o `number_of_pages_median` cuando estan disponibles.
- `totalPages` permanece editable manualmente.
- Estados de libro ampliados con `paused` y `abandoned`.
- Fechas de lectura `startedAt` y `finishedAt` editables manualmente desde detalle.
- Fechas de lectura de libros limitadas a hoy o pasado en alta y detalle.
- Formulario de alta muestra fechas cuando el estado inicial lo requiere.
- Biblioteca muestra estado, progreso en libros en lectura y rating en completados valorados.
- Home convertida en dashboard principal.
- CTA/card "Anadir nuevo libro" en Home.
- Eliminado FAB/boton redundante de anadir libro.
- Lectura actual muestra multiples libros en estado `Leyendo`.
- Registro rapido desde Home en dialogo centrado.
- Registro rapido crea sesiones cuando hay paginas o minutos.
- Actividad reciente muestra acciones registradas desde Home.
- Actividad reciente de Home limitada al dia actual.
- Actividad reciente ordenada por `createdAt` descendente.
- Actividad reciente contenida con scroll interno.
- Soporte para introducir `totalPages` al crear libro.
- Edicion de paginas desde detalle.
- Accion "Anadir total de paginas" desde Home cuando falta `totalPages`.
- Progreso visible como porcentaje y "Pagina X de Y" cuando hay datos suficientes.
- Valoracion final con decimales en pasos de `0.25`.
- Valoracion final al completar libro reutilizada en alta directa y cambio de estado.
- Resena opcional de completado soportada con `notes`.
- Biblioteca con icono de libros.
- Biblioteca ordena primero libros en estado `Leyendo` en la vista general.
- Tests ajustados para el formulario con multiples campos de texto.
- Test de estado inicial ajustado para hacer visible "Guardar libro" antes de tocarlo.
- Auditoria inicial de Hito 3 completada: "ratos de lectura" existentes se consolidan como base de `ReadingSession`.
- Consolidacion minima de `ReadingSession` implementada con `pagesRead`, `updatedAt`, consulta por libro y caso de uso central para registrar sesion + actualizar progreso.
- Finalizacion inteligente desde sesiones implementada: al alcanzar `totalPages`, se ofrece completar y valorar sin hacerlo automaticamente.
- Reading Streaks implementado en Estadisticas: racha actual y mejor racha basadas en dias con `ReadingSession`.
- Registro de sesiones pasadas habilitado desde formulario general y registro rapido de Home, bloqueando fechas futuras.
- Calendario enriquecido por intensidad implementado con resumen de actividad y leyenda visual.
- Estadisticas avanzadas de lectura implementadas desde `ReadingSession`: paginas/minutos por semana y mes, promedios por dia activo, dias activos y dia mas activo.

## Parcial / en seguimiento

- Validacion final del Sprint UX Home pendiente en terminal del usuario.
- Validacion final del segundo sprint de Estadisticas MVP pendiente en terminal del usuario.
- Revisión de textos y consistencia visual fina pendiente para el sprint visual/UI.
- Stats MVP queda como siguiente bloque funcional despues de cerrar Home.
- Open Library puede mejorar resultados en espanol, pero queda para una fase posterior.

## Pendiente inmediato

El usuario debe ejecutar:

```bash
dart format lib/features/stats/domain/entities/statistics_summary.dart lib/features/stats/domain/services/statistics_calculator.dart lib/features/stats/domain/repositories/statistics_repository.dart lib/features/stats/domain/usecases/get_statistics_summary.dart lib/features/stats/data/repositories/book_statistics_repository.dart lib/features/stats/data/repositories/statistics_repository_provider.dart lib/features/stats/presentation/providers/statistics_summary_provider.dart lib/features/stats/presentation/screens/stats_screen.dart lib/features/books/presentation/screens/book_form_screen.dart lib/features/books/presentation/screens/book_detail_screen.dart lib/features/home/presentation/screens/home_screen.dart
flutter test
flutter analyze
```

## Pendiente futuro

- Cerrar segundo sprint de Estadisticas MVP tras validacion.
- Definir siguiente iteracion de Stats sin introducir complejidad visual prematura.
- Investigar Open Library para mejorar resultados en espanol.
- Hacer sprint visual/UI: paleta, estilo, referencias y design system.
- Ampliar tests de flujos criticos si el alcance del siguiente sprint lo requiere.
- Hito 3 siguientes sprints: actividad avanzada, visualizaciones o metricas de sesiones sin introducir gamificacion prematura.

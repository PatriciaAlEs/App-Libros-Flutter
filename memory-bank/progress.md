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
- Hito 4 - Reading Insights iniciado.
- Sprint 1 de Reading Insights completado con nueva feature `insights`.
- `ReadingInsightsSummary` creado como entidad de dominio.
- Contrato `InsightsRepository` y caso de uso `GetReadingInsightsSummary` creados.
- `InsightsRepositoryImpl` calcula insights desde `BookRepository` y `ReadingSessionRepository`.
- Provider Riverpod `readingInsightsSummaryProvider` creado.
- Pantalla `InsightsScreen` creada y ruta `/insights` conectada.
- Insights Sprint 1 muestra libro mas leido, autor mas leido y genero favorito.
- El calculo usa paginas leidas acumuladas desde `ReadingSession.pagesRead`.
- Genero favorito usa `Book.genre` cuando existe; si no hay genero registrado, muestra fallback vacio.
- Mutaciones relevantes de libros y sesiones invalidan el provider de Insights.
- Tests focalizados de Reading Insights agregados.
- Validacion confirmada por el usuario: `flutter analyze` OK y `flutter test` OK.
- Hito 4 Sprint 2 de Reading Insights completado.
- Reading Insights ahora incluye paginas por sesion, minutos por sesion y paginas por dia.
- Reading Insights ahora incluye prediccion simple de fin de libro para libros en estado `reading`.
- Reading Insights ahora incluye forecast anual simple de libros completados.
- Sprint 2 usa solo datos reales existentes de `Book` y `ReadingSession`; no crea tablas nuevas ni usa IA.
- Validacion Sprint 2 confirmada por el usuario: `dart format` OK, `flutter analyze` OK y `flutter test` OK (30 tests).
- Hito 4 Sprint 3 de Reading Insights completado.
- Reading Insights ahora incluye "Top Lecturas del Año".
- Top Lecturas del Año muestra mejor valorado, mas largo, mas tiempo invertido y mas sesiones.
- Reading Insights ahora incluye "Ranking Personal".
- Ranking Personal muestra Top 3 autores, generos y libros por paginas leidas acumuladas.
- Ranking Personal reutiliza la mejor racha calculada por `StatisticsCalculator`.
- Sprint 3 usa solo datos reales existentes de `Book` y `ReadingSession`; no crea tablas nuevas, dependencias externas ni IA.
- Dashboard premium queda fuera de Sprint 3.
- Validacion Sprint 3 confirmada por el usuario: `dart format` OK, `flutter analyze` OK y `flutter test` OK (33 tests).

## Parcial / en seguimiento

- Revisión de textos y consistencia visual fina pendiente para el sprint visual/UI.
- Open Library puede mejorar resultados en espanol, pero queda para una fase posterior.

## Pendiente inmediato

- Definir el siguiente bloque funcional cuando el usuario lo pida.
- Mantener fuera dashboard premium hasta peticion explicita.

## Pendiente futuro

- Definir siguiente iteracion de Stats o Insights sin introducir complejidad visual prematura.
- Investigar Open Library para mejorar resultados en espanol.
- Hacer sprint visual/UI: paleta, estilo, referencias y design system.
- Ampliar tests de flujos criticos si el alcance del siguiente sprint lo requiere.

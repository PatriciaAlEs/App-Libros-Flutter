# Current State

## Producto

`reading_tracker` es una app Flutter mobile-first para registrar libros, sesiones de lectura, progreso, calendario, estadisticas basicas e insights de lectura.

La Home ya funciona como dashboard principal. Actualmente ofrece:

- Card/CTA "Anadir nuevo libro".
- Seccion "Lectura actual" con todos los libros en estado `Leyendo`.
- Registro rapido de avance desde cada lectura actual.
- Resumen rapido de lectura.
- Actividad reciente del dia actual.
- Sugerencias de pendientes cuando no hay lecturas activas.

## UX Home

Estado actual implementado:

- Si existen varios libros en estado `Leyendo`, Home muestra una card por libro.
- Si no hay libros en estado `Leyendo`, Home muestra sugerencias de libros pendientes.
- Las sugerencias de pendientes priorizan libros mas antiguos usando la fecha disponible de alta/creacion.
- La card de lectura actual muestra progreso cuando hay `currentPage` y `totalPages`.
- Si falta `totalPages`, se muestra una accion clara: "Anadir total de paginas".
- El registro rapido desde Home usa un dialogo centrado, no bottom sheet.
- El dialogo mantiene campos de pagina actual, paginas leidas y minutos.
- El dialogo permite guardar cambios o ir al detalle completo del libro.
- El contenido del dialogo es scrollable para evitar overflow en movil.
- La card "Anadir nuevo libro" es la entrada principal para anadir libros desde Home.
- El FAB/boton redundante de anadir libro fue eliminado.

## Actividad reciente

Estado actual implementado:

- El registro rapido desde Home crea una `ReadingSession` cuando `pagesRead > 0` o `minutes > 0`.
- Se reutiliza el repositorio/provider existente de sesiones.
- Tras guardar, se refresca el provider usado por la actividad reciente.
- Home muestra solo actividad del dia actual.
- Las sesiones se ordenan por `createdAt` descendente.
- Si hay varias sesiones hoy, aparecen dentro de un contenedor con altura maxima y scroll interno.
- Empty state actual: "Aun no hay actividad hoy. Registra una sesion para ver tu ritmo de lectura."

## Hito 3 - Reading Sessions & Activity Tracking

Auditoria inicial realizada:

- Ya existe una entidad de dominio `ReadingSession`.
- Ya existe tabla Drift `reading_sessions`.
- Ya existe `ReadingSessionDao`.
- Ya existe contrato `ReadingSessionRepository` e implementacion `ReadingSessionRepositoryImpl`.
- Ya existen providers para sesiones por dia y por rango.
- Ya existen pantallas para calendario, detalle de dia y formulario de rato de lectura.
- La funcionalidad actual de "ratos de lectura" equivale conceptualmente a la base de `ReadingSession`; no se debe crear una segunda entidad paralela.
- Las sesiones ya se asocian a un libro mediante `bookId`.
- Las sesiones ya se persisten localmente.
- Las sesiones ya pueden consultarse por dia y por rango.
- Home ya crea sesiones desde el registro rapido cuando hay paginas o minutos.
- El calendario ya consume sesiones por rango/dia.

Consolidacion minima implementada:

- `ReadingSession` ahora soporta `pagesRead` como dato estructurado.
- `ReadingSession` ahora soporta `updatedAt`.
- La tabla Drift `reading_sessions` incluye `pages_read` con default `0` y `updated_at` nullable.
- `AppDatabase` sube a `schemaVersion = 4`.
- La migracion `from < 4` anade las columnas nuevas sin borrar datos previos.
- El repositorio permite consultar sesiones por `bookId`.
- Existe el caso de uso `RegisterReadingSession` para crear sesion y actualizar progreso del libro.
- Home usa `RegisterReadingSession` y ya no guarda paginas dentro de `note`.
- El formulario general de ratos permite registrar paginas leidas, minutos y nota opcional.
- El formulario general permite seleccionar una fecha pasada o la fecha actual; no permite crear sesiones futuras.
- El registro rapido desde Home preselecciona hoy pero permite cambiar a una fecha pasada antes de guardar.
- La actividad reciente, detalle de dia y calendario muestran paginas/minutos cuando existen.
- El calendario muestra intensidad diaria por `ReadingSession` con niveles sin actividad, baja, media y alta.
- El calendario muestra resumen del periodo visible con paginas leidas, minutos leidos y dias activos.
- Cuando una sesion nueva con paginas leidas hace que el progreso alcance `totalPages`, la app ofrece completar el libro y abrir valoracion/resena opcional, sin completar automaticamente.
- Las rachas de lectura se calculan desde dias con al menos una `ReadingSession`, agrupando por fecha sin hora.
- La racha actual cuenta hasta hoy si hay sesion hoy, o hasta ayer si ayer tuvo sesion y hoy aun no.
- La mejor racha historica recorre todos los dias con sesiones y conserva la secuencia maxima de dias consecutivos.

Deuda detectada para consolidar Hito 3:

- La edicion de una sesion existente actualiza los datos de la sesion, pero no recalcula el progreso historico del libro.

## Libros y progreso

Estado actual implementado:

- Al crear libro se puede introducir `totalPages`.
- Al seleccionar un resultado de Open Library, `totalPages` se autorrellena si llega `number_of_pages` o `number_of_pages_median`.
- El campo `totalPages` sigue siendo editable manualmente aunque venga de Open Library.
- En alta de libros, la busqueda Open Library muestra estado de carga y limita resultados iniciales para mantener accesible el guardado.
- En detalle se pueden editar paginas.
- Desde Home se puede anadir `totalPages` cuando falta.
- `Book` ya tenia campos compatibles para `totalPages`, `currentPage` y `rating`; no fue necesario cambiar el modelo.
- La valoracion final al completar lectura permite decimales con pasos de `0.25`.

## Ciclo de vida del libro

Estado actual implementado:

- Estados soportados: `pending`, `reading`, `completed`, `paused` y `abandoned`.
- Etiquetas visibles: Pendiente, Leyendo, Completado, Pausado y Abandonado.
- `addedAt` representa cuando se anadio el libro a la app.
- `startedAt` y `finishedAt` se exponen como fechas de lectura editables.
- Persistencia reutiliza los campos existentes `createdAt`, `startDate` y `completedDate`.
- En el formulario de alta aparecen fechas cuando el estado inicial lo requiere.
- En detalle se pueden editar manualmente fecha de inicio y fecha de finalizacion.
- Al editar fecha de finalizacion, el selector usa fecha de inicio como referencia/minimo si existe.
- Los selectores de fechas de lectura de libros permiten hoy o pasado, nunca futuro.
- Si la fecha de inicio cambia y queda despues de la fecha de finalizacion, se limpia la finalizacion para evitar rangos invalidos.
- Si un libro entra en estado `completed`, se ofrece valorar con estrellas y resena opcional.
- La valoracion de completado se reutiliza en alta directa como completado y en cambio de estado desde detalle.
- La resena usa el campo persistido existente `notes`.

## Biblioteca y navegacion

Estado actual implementado:

- Biblioteca usa un icono de libros.
- La vista general de Biblioteca muestra primero libros en estado `Leyendo`.
- Despues se muestran el resto de estados.
- Se mantienen filtros/tabs existentes y la opcion de ver todos.
- Cada card muestra estado visual del libro.
- Los libros en lectura muestran progreso si tienen `currentPage` y `totalPages`.
- Los libros completados muestran rating si estan valorados.

## Reading Insights

Estado actual implementado:

- Hito 4 - Reading Insights iniciado.
- Sprint 1 completado y validado.
- Existe la feature `features/insights` con capas `domain`, `data` y `presentation`.
- `ReadingInsightsSummary` centraliza preferencias, ritmo de lectura, prediccion de fin y forecast anual.
- `InsightsRepository` define el contrato de acceso.
- `InsightsRepositoryImpl` calcula insights usando `BookRepository` y `ReadingSessionRepository`.
- `GetReadingInsightsSummary` encapsula el caso de uso.
- `readingInsightsSummaryProvider` expone el resumen a la UI.
- La pantalla `InsightsScreen` muestra tres cards: libro mas leido, autor mas leido y genero favorito.
- La ruta `/insights` esta conectada.
- El calculo se basa en paginas leidas acumuladas desde `ReadingSession.pagesRead`.
- El libro mas leido es el libro con mas paginas leidas registradas en sesiones.
- El autor mas leido acumula paginas entre sus libros.
- El genero favorito acumula paginas por `Book.genre`.
- Si `Book.genre` esta vacio o no disponible, el insight de genero queda en fallback sin inventar campos.
- La pantalla maneja loading, error y empty state.
- Las mutaciones de libros y sesiones invalidan `readingInsightsSummaryProvider` cuando corresponde.
- Hay tests focalizados para el calculo de insights.
- Hito 4 Sprint 2 completado y validado.
- `ReadingInsightsSummary` tambien expone paginas por sesion, minutos por sesion y paginas por dia.
- La prediccion de fin de libro estima paginas restantes, ritmo reciente, dias restantes y fecha aproximada para un libro en estado `reading`.
- El forecast anual proyecta libros completados para final de ano usando el ritmo actual de completados.
- Los calculos de Sprint 2 usan solo `Book` y `ReadingSession`; no hay tablas nuevas, servicios externos ni IA.
- La pantalla `InsightsScreen` muestra secciones para Preferencias, Reading Pace, Finish Prediction y Annual Forecast.
- Los estados vacios cubren falta de sesiones, falta de libro en lectura o datos insuficientes.

## Validacion

Estado confirmado por el usuario:

- `flutter analyze` OK.
- `flutter test` OK (30 tests).
- `dart format` OK.
- El usuario ejecuta `dart format`, `flutter analyze` y `flutter test` desde VS Code.

## Estadisticas MVP

Estado actual implementado:

- Existe una capa nueva desacoplada para estadisticas basada en `Book` y, para rachas/actividad avanzada, en `ReadingSession`.
- `StatisticsSummary` centraliza metricas base: total, completados, leyendo, pausados, abandonados, pendientes, paginas leidas, rating medio, lecturas actuales, racha actual, mejor racha y ritmo de lectura.
- `StatisticsCalculator` contiene la logica pura de calculo fuera de widgets y pantallas.
- `StatisticsRepository` define el contrato de acceso a estadisticas.
- `BookStatisticsRepository` calcula estadisticas usando `BookRepository` y sesiones existentes desde `ReadingSessionRepository`.
- `GetStatisticsSummary` encapsula el caso de uso.
- `statisticsSummaryProvider` es el punto unico preparado para que la UI consuma estas metricas en futuros sprints.
- La pantalla `/stats` ya consume `statisticsSummaryProvider`.
- La UI basica muestra tarjetas para total, completados, leyendo, pausados, abandonados, pendientes, paginas leidas, rating medio, lecturas actuales, rachas y ritmo de lectura.
- La pantalla maneja loading, error, empty state y datos disponibles.
- Los flujos de alta, detalle y Home invalidan `statisticsSummaryProvider` tras mutaciones de libros.
- El objetivo anual de lectura se persiste como `annualReadingGoal` en `app_settings`.
- `StatisticsSummary` expone objetivo anual, completados del ano actual, porcentaje, restantes y meta alcanzada.
- La seccion "Objetivo anual" aparece en `/stats`.
- El usuario puede definir o editar la meta anual desde un dialogo simple en `/stats`.
- La seccion "Rachas" aparece en `/stats` con racha actual y mejor racha.
- La seccion "Ritmo de lectura" aparece en `/stats` con paginas/minutos por semana y mes, promedios por dia activo, dias activos del mes y dia mas activo.
- Quedan preparados futuros bloques de sesiones avanzadas y graficas, sin implementarlos todavia.

## Siguiente paso recomendado

1. Definir el siguiente bloque funcional cuando el usuario lo pida.
2. Mantener fuera rankings y dashboard premium hasta peticion explicita.
3. Continuar con el siguiente bloque que priorice el usuario.

# Current State

## Producto

`reading_tracker` es una app Flutter mobile-first para registrar libros, sesiones de lectura, progreso, calendario y estadisticas basicas.

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

## Validacion

Validaciones pendientes de ejecutar por el usuario:

```bash
dart format lib/features/stats/domain/entities/statistics_summary.dart lib/features/stats/domain/services/statistics_calculator.dart lib/features/stats/domain/repositories/statistics_repository.dart lib/features/stats/domain/usecases/get_statistics_summary.dart lib/features/stats/data/repositories/book_statistics_repository.dart lib/features/stats/data/repositories/statistics_repository_provider.dart lib/features/stats/presentation/providers/statistics_summary_provider.dart lib/features/stats/presentation/screens/stats_screen.dart lib/features/books/presentation/screens/book_form_screen.dart lib/features/books/presentation/screens/book_detail_screen.dart lib/features/home/presentation/screens/home_screen.dart
flutter test
flutter analyze
```

## Estadisticas MVP

Estado actual implementado:

- Existe una capa nueva desacoplada para estadisticas basada solo en `Book`.
- `StatisticsSummary` centraliza metricas base: total, completados, leyendo, pausados, abandonados, pendientes, paginas leidas, rating medio y lecturas actuales.
- `StatisticsCalculator` contiene la logica pura de calculo fuera de widgets y pantallas.
- `StatisticsRepository` define el contrato de acceso a estadisticas.
- `BookStatisticsRepository` calcula estadisticas usando `BookRepository`.
- `GetStatisticsSummary` encapsula el caso de uso.
- `statisticsSummaryProvider` es el punto unico preparado para que la UI consuma estas metricas en futuros sprints.
- La pantalla `/stats` ya consume `statisticsSummaryProvider`.
- La UI basica muestra tarjetas para total, completados, leyendo, pausados, abandonados, pendientes, paginas leidas, rating medio y lecturas actuales.
- La pantalla maneja loading, error, empty state y datos disponibles.
- Los flujos de alta, detalle y Home invalidan `statisticsSummaryProvider` tras mutaciones de libros.
- El objetivo anual de lectura se persiste como `annualReadingGoal` en `app_settings`.
- `StatisticsSummary` expone objetivo anual, completados del ano actual, porcentaje, restantes y meta alcanzada.
- La seccion "Objetivo anual" aparece en `/stats`.
- El usuario puede definir o editar la meta anual desde un dialogo simple en `/stats`.
- No se usan `ReadingSession` todavia en esta base nueva.
- Quedan preparados futuros bloques de objetivos anuales, rachas, sesiones y graficas, sin implementarlos todavia.

## Siguiente paso recomendado

1. Usuario ejecuta formato, tests y analisis.
2. Revisar cualquier fallo que aparezca.
3. Si todo esta correcto, cerrar el segundo sprint de UI basica Estadisticas MVP.
4. Continuar con el siguiente bloque que priorice el usuario.

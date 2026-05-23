# Active Context

## Foco actual

Hito 2: Estadisticas MVP.

Segundo sprint: UI basica de Estadisticas MVP consumiendo `statisticsSummaryProvider`.

La Home ya funciona como dashboard principal y concentra:

- Lectura actual.
- CTA integrado para anadir libro.
- Resumen rapido.
- Actividad reciente.
- Acciones rapidas de progreso.

Graficas, objetivos, rachas y sesiones quedan fuera de este sprint.

## Estado reciente

- Se creo una base nueva de estadisticas desacoplada de widgets/pantallas.
- Se agrego `StatisticsSummary` como modelo de resumen centralizado.
- Se agrego `StatisticsCalculator` para calcular metricas puras desde `List<Book>`.
- Se agrego `StatisticsRepository` y una implementacion basada en `BookRepository`.
- Se agrego el caso de uso `GetStatisticsSummary`.
- Se agrego `statisticsSummaryProvider` como punto unico de consumo futuro para la UI.
- La pantalla `/stats` ahora consume unicamente `statisticsSummaryProvider`.
- La UI basica de Stats muestra tarjetas simples para las metricas de `StatisticsSummary`.
- La pantalla maneja loading, error, empty state y datos disponibles.
- Los flujos de mutacion de libros invalidan tambien `statisticsSummaryProvider` para evitar datos cacheados.
- No se agregaron graficas, objetivos, rachas, `ReadingSession` ni librerias externas.
- El calculo actual usa solo datos de `Book`: `status`, `currentPage`, `totalPages`, `rating`, `startedAt` y `finishedAt` cuando apliquen en futuras metricas.
- No se introdujo `ReadingSession` en la nueva base MVP.
- Se inicio un sprint de refinamiento del ciclo de vida del libro antes de Estadisticas MVP.
- Open Library ahora puede autorrellenar `totalPages` desde `number_of_pages` o `number_of_pages_median`.
- El campo `totalPages` sigue siendo editable manualmente por el usuario.
- Se ampliaron los estados de libro con `paused` / Pausado y `abandoned` / Abandonado.
- Se diferencian `addedAt`, `startedAt` y `finishedAt` a nivel de dominio/UX usando los campos persistidos existentes.
- Las fechas de inicio y finalizacion se pueden editar manualmente desde el detalle.
- El formulario de alta muestra fechas cuando el estado inicial lo requiere.
- Biblioteca muestra estado visual, progreso en libros en lectura y rating en completados valorados.
- Se ajusto el test del formulario para hacer visible "Guardar libro" antes de tocarlo.
- Se trabajo principalmente en UX de Home.
- Se anadio la card/CTA "Anadir nuevo libro" integrada en el dashboard.
- Se elimino la duplicidad del FAB/boton de anadir libro, priorizando la card.
- La seccion "Lectura actual" muestra todos los libros en estado `Leyendo`.
- Cada card de lectura actual abre el flujo de registro rapido para ese libro.
- El registro rapido desde Home paso de bottom sheet a dialogo centrado.
- El registro rapido actualiza paginas, minutos y resumen rapido.
- El registro rapido crea una `ReadingSession` cuando hay paginas o minutos, por lo que "Actividad reciente" se actualiza sin reiniciar la app.
- "Actividad reciente" muestra solo sesiones del dia actual, ordenadas por `createdAt` descendente, dentro de un contenedor con scroll interno.
- Se anadio soporte para introducir `totalPages` al crear libro.
- Se anadio opcion para editar paginas desde detalle.
- Se anadio accion "Anadir total de paginas" desde Home cuando falta `totalPages`.
- `Book` ya tenia `totalPages`, `currentPage` y `rating` como tipos compatibles; no fue necesario cambiar el modelo.
- La valoracion final permite decimales en pasos de `0.25`.
- En navegacion, Biblioteca usa un icono de libros.
- En Biblioteca, la vista general prioriza libros en estado `Leyendo` y despues el resto.
- Se corrigieron tests que fallaban porque el formulario de libro ahora tiene mas de un `TextField`.

## Archivos tocados recientemente

- `reading_tracker/lib/features/stats/domain/entities/statistics_summary.dart`
- `reading_tracker/lib/features/stats/domain/services/statistics_calculator.dart`
- `reading_tracker/lib/features/stats/domain/repositories/statistics_repository.dart`
- `reading_tracker/lib/features/stats/domain/usecases/get_statistics_summary.dart`
- `reading_tracker/lib/features/stats/data/repositories/book_statistics_repository.dart`
- `reading_tracker/lib/features/stats/data/repositories/statistics_repository_provider.dart`
- `reading_tracker/lib/features/stats/presentation/providers/statistics_summary_provider.dart`
- `reading_tracker/lib/features/stats/presentation/screens/stats_screen.dart`
- `reading_tracker/lib/features/books/presentation/screens/book_form_screen.dart`
- `reading_tracker/lib/features/books/presentation/screens/book_detail_screen.dart`
- `reading_tracker/lib/features/home/presentation/screens/home_screen.dart`
- `reading_tracker/lib/features/books/data/datasources/book_api_datasource.dart`
- `reading_tracker/lib/features/books/domain/entities/book.dart`
- `reading_tracker/lib/features/books/domain/entities/book_search_result.dart`
- `reading_tracker/lib/features/books/domain/enums/book_status.dart`
- `reading_tracker/lib/features/books/presentation/screens/book_form_screen.dart`
- `reading_tracker/lib/features/books/presentation/screens/book_detail_screen.dart`
- `reading_tracker/lib/features/books/presentation/screens/books_list_screen.dart`
- `reading_tracker/lib/features/books/presentation/widgets/book_card.dart`
- `reading_tracker/lib/features/home/presentation/screens/home_screen.dart`
- `reading_tracker/test/widget_test.dart`

## Validaciones pendientes

El usuario ejecuta las validaciones en su terminal de VS Code. No ejecutarlas desde Codex salvo que lo pida explicitamente.

Comandos pendientes sugeridos:

```bash
dart format lib/features/stats/domain/entities/statistics_summary.dart lib/features/stats/domain/services/statistics_calculator.dart lib/features/stats/domain/repositories/statistics_repository.dart lib/features/stats/domain/usecases/get_statistics_summary.dart lib/features/stats/data/repositories/book_statistics_repository.dart lib/features/stats/data/repositories/statistics_repository_provider.dart lib/features/stats/presentation/providers/statistics_summary_provider.dart lib/features/stats/presentation/screens/stats_screen.dart lib/features/books/presentation/screens/book_form_screen.dart lib/features/books/presentation/screens/book_detail_screen.dart lib/features/home/presentation/screens/home_screen.dart
flutter test
flutter analyze
```

## Pendientes reales

1. Validar la UI basica de Estadisticas MVP con `dart format`, `flutter test` y `flutter analyze`.
2. Corregir cualquier fallo de test/analyze que reporte el usuario.
3. Cerrar el segundo sprint de Estadisticas MVP si las validaciones pasan.
4. Preparar metricas visuales mas avanzadas solo despues de estabilizar esta UI basica.
5. Mas adelante investigar Open Library para mejorar resultados en espanol.
6. Dejar el sprint visual/UI para despues: paleta, estilo, referencias y design system.

## Riesgos / notas

- El usuario prefiere ejecutar validaciones localmente; indicarle comandos, no correrlos aqui.
- No revisar `git status` ni `git diff` salvo que el usuario lo pida explicitamente.
- Codex/VS Code puede quedarse bloqueado en "Enviando cambios"; verificar con `git status` y `git diff`.
- Mantener cambios pequenos y acotados por problema.
- No tocar Open Library, modelos o persistencia salvo requisito explicito.
- No hacer commit ni push automaticamente.

# Active Context

## Foco actual

Hito 5: UX/UI Premium Redesign.

Sprint 2.5 iniciado e implementado: Branding & Visual Identity global para ReadPp.

La Home ya funciona como pantalla editorial de biblioteca personal y concentra:

- Lectura actual.
- Progreso lector.
- Objetivo anual.
- Actividad reciente.
- FAB para anadir libro.

Insights ya no funciona como segunda pantalla de estadisticas: la UI se organiza como perfil lector.

La navegacion principal ahora expone directamente:

- Inicio.
- Biblioteca.
- Progreso.
- Insights.
- Ajustes.

El sistema visual base ahora incluye:

- Tema Burgundy por defecto.
- Tema Forest seleccionable desde Ajustes.
- Tokens de spacing, radios, elevaciones y sombras suaves.
- Componentes base `MetricCard`, `InsightCard`, `ProgressCard`, `SectionHeader` y `EmptyStateCard`.
- Persistencia local de preferencia de tema con `shared_preferences`.
- Branding base de ReadPp con estructura de assets, constantes de marca y wordmark reutilizable.
- Tipografia global preparada con Playfair Display para titulos e Inter para contenido.
- Adaptador `AppIcons` para centralizar iconografia y facilitar una futura migracion a Lucide.
- Motion tokens y widgets reutilizables para transiciones suaves.

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
- Se agrego persistencia para `annualReadingGoal` en `app_settings`.
- `StatisticsSummary` incluye objetivo anual, completados del ano, progreso, restantes y estado de meta alcanzada.
- El calculo del objetivo anual usa solo libros `completed` con `finishedAt/completedDate` del ano actual.
- La pantalla `/stats` muestra una seccion destacada "Objetivo anual".
- La meta anual se puede crear/editar desde un dialogo simple en `/stats`.
- Regla de ciclo de vida: cuando un libro entra en `completed`, la app ofrece valorar con estrellas y resena opcional.
- La resena ya se soporta con el campo existente `notes`; no se requiere migracion.
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
- Se inicio Hito 4 - Reading Insights.
- Se creo `features/insights` con capas `domain`, `data` y `presentation`.
- Se agrego `ReadingInsightsSummary`.
- Se agrego el contrato `InsightsRepository`.
- Se agrego el caso de uso `GetReadingInsightsSummary`.
- Se agrego `InsightsRepositoryImpl`, que calcula desde `BookRepository` y `ReadingSessionRepository`.
- Se agrego `readingInsightsSummaryProvider`.
- Se agrego `InsightsScreen`.
- Se conecto la ruta `/insights`.
- Home tiene acceso a Insights desde la barra superior.
- Sprint 1 muestra libro mas leido, autor mas leido y genero favorito.
- Los calculos usan paginas leidas acumuladas desde `ReadingSession.pagesRead`.
- El insight de genero usa `Book.genre` si existe; si no hay datos fiables, muestra fallback.
- En Sprint 1 no se agregaron migraciones, tablas, predicciones ni IA.
- Se agregaron tests focalizados para Reading Insights.
- Validacion confirmada: `flutter analyze` OK y `flutter test` OK.
- Se completo Hito 4 Sprint 2.
- `ReadingInsightsSummary` se extendio con ritmo de lectura, prediccion de fin y forecast anual.
- `InsightsRepositoryImpl` calcula paginas por sesion, minutos por sesion y paginas por dia desde `ReadingSession`.
- La prediccion de fin usa paginas restantes y ritmo reciente del libro en lectura.
- El forecast anual usa libros completados del ano actual y una proyeccion lineal hasta fin de ano.
- `InsightsScreen` suma secciones `Reading Pace`, `Finish Prediction` y `Annual Forecast`.
- Se agregaron tests para paginas por sesion, minutos por sesion, prediccion de finalizacion, forecast anual y estados vacios.
- Validacion Sprint 2 confirmada: `dart format` OK, `flutter analyze` OK y `flutter test` OK (30 tests).
- Se completo Hito 4 Sprint 3.
- `ReadingInsightsSummary` se extendio con Top Lecturas del Año y Ranking Personal.
- `InsightsRepositoryImpl` calcula mejor valorado, libro mas largo, mas tiempo invertido y mas sesiones.
- `InsightsRepositoryImpl` calcula Top 3 autores, generos y libros por paginas leidas acumuladas.
- La mejor racha de Ranking Personal reutiliza `StatisticsCalculator`.
- `InsightsScreen` suma secciones `Top Lecturas del Año` y `Ranking Personal`.
- Se agregaron tests para mejor valorado, libro mas largo, libro con mas sesiones, libro con mas tiempo invertido, rankings y estados vacios.
- Validacion Sprint 3 confirmada: `dart format` OK, `flutter analyze` OK y `flutter test` OK (33 tests).
- Se implemento Hito 4 Sprint 4 como reorganizacion premium de Insights.
- La UI de `/insights` ahora muestra `Tu perfil lector`, `Tus mejores lecturas` y `Curiosidades`.
- Se retiraron de la UI `Finish Prediction`, `Annual Forecast`, `Ranking Personal` y `Mejor racha`.
- `Tu perfil lector` muestra autor favorito, genero favorito y libro al que mas tiempo se dedico.
- `Tus mejores lecturas` muestra Top 3 lecturas del año por rating.
- `Curiosidades` muestra libro mas largo, mes con mas lectura, franja horaria habitual y dia mas activo.
- Sprint 4 reutiliza `Book` y `ReadingSession`; no agrega tablas, servicios externos ni metricas complejas.
- Los campos legacy de prediccion, forecast, rankings y racha se conservan en dominio para compatibilidad de tests existentes, pero ya no se muestran en la UI de Insights.
- Se inicio Hito 5 - UX/UI Premium Redesign.
- Se agrego `MainNavigationScreen` como entrada principal en `/`.
- La navegacion usa `NavigationBar` de Material 3 con tabs Inicio, Biblioteca, Progreso, Insights y Ajustes.
- Se agrego `ProgressScreen` como hub de progreso.
- `ProgressScreen` da acceso a Estadisticas, Reading Challenge, Activity Tracking/calendario y registro de sesion.
- Se agrego `SettingsScreen` para Ajustes; en Sprint 2 se extendio con selector de tema.
- Las rutas existentes se mantienen: `/home`, `/books`, `/stats`, `/progress`, `/calendar`, `/insights`, `/settings` y flujos internos.
- No se tocaron Drift, modelos de datos, autenticacion ni servicios externos.
- Correccion UX de Sprint 1: la Home ya no duplica accesos principales en el AppBar.
- Correccion UX de Sprint 1: se elimino el CTA `Ver biblioteca` de `Lectura actual`.
- Correccion UX de Sprint 1: el resumen rapido de Home se compacto con cards mas densas.
- Se implemento Hito 5 Sprint 2 - Design System.
- `AppTheme` ahora soporta los temas Burgundy y Forest con Material 3.
- Se agrego `AppThemeController` con Riverpod para cargar y guardar el tema seleccionado localmente.
- Se agregaron tokens reutilizables de spacing, radios, elevaciones y sombras.
- Se agregaron componentes base de design system sin redisenar pantallas existentes.
- `SettingsScreen` dejo de ser solo placeholder y ahora incluye selector de tema; sigue sin perfil real ni login.
- Se implemento Hito 5 Sprint 3 - Home Premium Redesign.
- La Home ahora muestra header `READPP •`, subtitulo `Tu biblioteca personal` y saludo contextual.
- La lectura actual se muestra como hero card con portada protagonista, titulo, autor, porcentaje, paginas y barra de progreso.
- Si no hay libro en lectura, la Home muestra un empty state elegante o sugerencias de pendientes.
- Las metricas rapidas se redujeron a racha actual, libros completados este ano y paginas leidas.
- El objetivo lector anual se muestra como card independiente usando datos de `StatisticsSummary`.
- La actividad reciente muestra maximo 3 sesiones y agrega accion secundaria `Ver actividad`.
- El bloque grande de anadir libro se elimino y se reemplazo por FAB.
- Se implemento Hito 5 Sprint 2.5 - Branding & Visual Identity.
- Se creo estructura de assets para logo principal, icono app y variantes futuras.
- Se agrego `AppBrand` y `BrandWordmark` con fallback textual.
- `ThemeData` global ahora usa Playfair Display para display/headline/title e Inter para body/label.
- Se agrego `AppTypography` como contrato tipografico.
- Se agrego `AppIcons` como adaptador de iconografia moderna sobre Material Icons, preparando migracion futura a Lucide.
- Se agrego `AppMotion`, `AppFadeSlideTransition` y `AppPressable` para motion reutilizable.
- Se refinaron sombras, elevaciones, spacing y jerarquia de color del Design System.
- No se redisenaron Biblioteca, Estadisticas, Insights ni Detalle Libro.

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
- `reading_tracker/lib/features/books/presentation/widgets/completion_review_sheet.dart`
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
- `reading_tracker/lib/features/insights/domain/entities/reading_insights_summary.dart`
- `reading_tracker/lib/features/insights/domain/repositories/insights_repository.dart`
- `reading_tracker/lib/features/insights/domain/usecases/get_reading_insights_summary.dart`
- `reading_tracker/lib/features/insights/data/repositories/insights_repository_impl.dart`
- `reading_tracker/lib/features/insights/data/repositories/insights_repository_provider.dart`
- `reading_tracker/lib/features/insights/presentation/providers/reading_insights_summary_provider.dart`
- `reading_tracker/lib/features/insights/presentation/screens/insights_screen.dart`
- `reading_tracker/lib/app.dart`
- `reading_tracker/lib/core/theme/app_theme.dart`
- `reading_tracker/lib/core/theme/app_theme_controller.dart`
- `reading_tracker/lib/core/theme/app_theme_tokens.dart`
- `reading_tracker/lib/core/theme/app_typography.dart`
- `reading_tracker/lib/core/branding/app_brand.dart`
- `reading_tracker/lib/core/branding/branding.dart`
- `reading_tracker/lib/core/branding/widgets/brand_wordmark.dart`
- `reading_tracker/lib/core/design_system/design_system.dart`
- `reading_tracker/lib/core/design_system/icons/app_icons.dart`
- `reading_tracker/lib/core/design_system/motion/app_motion.dart`
- `reading_tracker/lib/core/design_system/motion/app_pressable.dart`
- `reading_tracker/lib/core/design_system/components/metric_card.dart`
- `reading_tracker/lib/core/design_system/components/insight_card.dart`
- `reading_tracker/lib/core/design_system/components/progress_card.dart`
- `reading_tracker/lib/core/design_system/components/section_header.dart`
- `reading_tracker/lib/core/design_system/components/empty_state_card.dart`
- `reading_tracker/lib/features/settings/presentation/screens/settings_screen.dart`
- `reading_tracker/lib/features/home/presentation/screens/home_screen.dart`
- `reading_tracker/lib/features/navigation/presentation/screens/main_navigation_screen.dart`
- `reading_tracker/assets/branding/README.md`
- `reading_tracker/assets/fonts/README.md`
- `reading_tracker/pubspec.yaml`
- `reading_tracker/lib/features/reading_sessions/presentation/screens/session_form_screen.dart`
- `reading_tracker/lib/features/reading_sessions/presentation/screens/day_detail_screen.dart`
- `reading_tracker/lib/features/reading_sessions/presentation/utils/session_completion_flow.dart`
- `reading_tracker/test/reading_insights_summary_test.dart`

## Validaciones

El usuario ejecuta las validaciones en su terminal de VS Code. No ejecutarlas desde Codex salvo que lo pida explicitamente.

Estado confirmado para Hito 4 Sprint 3:

- `dart format` OK.
- `flutter analyze` OK.
- `flutter test` OK (33 tests).

## Pendientes reales

1. Ejecutar `flutter pub get` antes de validar Sprint 2/Sprint 2.5/Sprint 3, por la nueva dependencia `shared_preferences` y nuevos assets declarados.
2. Validar Hito 5 Sprint 1/Sprint 2/Sprint 2.5/Sprint 3 desde la terminal del usuario cuando corresponda.
3. Definir siguiente sprint visual/UI cuando el usuario lo pida.
3. Mas adelante investigar Open Library para mejorar resultados en espanol.
4. Dejar el sprint visual/UI para despues: paleta, estilo, referencias y design system.

## Riesgos / notas

- El usuario prefiere ejecutar validaciones localmente; indicarle comandos, no correrlos aqui.
- No revisar `git status` ni `git diff` salvo que el usuario lo pida explicitamente.
- Codex/VS Code puede quedarse bloqueado en "Enviando cambios"; verificar con `git status` y `git diff`.
- Mantener cambios pequenos y acotados por problema.
- No tocar Open Library, modelos o persistencia salvo requisito explicito.
- No hacer commit ni push automaticamente.

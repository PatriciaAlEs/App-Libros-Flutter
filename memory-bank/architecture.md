# Architecture

## Resumen real

La app usa una arquitectura Flutter por features. La persistencia de producto sigue siendo local con Drift + SQLite/IndexedDB y el estado se gestiona con Riverpod. Supabase existe como backend progresivo opcional para Auth y sincronizacion remota, pero no sustituye a Drift ni bloquea el modo local.

## Estructura

```text
reading_tracker/lib/
  core/
    backend/
    branding/
    database/
    design_system/
    theme/
    utils/
  features/
    auth/
      data/
      domain/
      presentation/
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
    sync/
      data/
      domain/
```

## Core

- `core/backend`: configuracion, inicializacion y provider opcional de Supabase.
- `core/database`: Drift, tablas, DAOs, conexion por plataforma y seed data.
- `core/branding`: constantes de marca, rutas de assets y widgets de wordmark.
- `core/theme`: tema Material compartido, tokens visuales y controlador de tema.
- `core/design_system`: componentes visuales reutilizables.
- `core/utils`: utilidades de fecha e IDs.

## Features

- `auth`: usuario de dominio, contrato de autenticacion, implementacion Supabase Auth, controlador Riverpod y pantallas de Cuenta/Auth.
- `books`: busqueda Open Library, repositorio, entidad `Book`, estado de libro y UI de listado/detalle/formulario.
- `reading_sessions`: entidad `ReadingSession`, repositorio, calendario, detalle de dia y formulario de sesion.
- `stats`: calculos, provider y pantalla.
- `insights`: perfil lector calculado desde libros y sesiones, con preferencias, mejores lecturas y curiosidades.
- `sync`: modelo remoto Supabase, metadata local de sincronizacion, tracking local, orquestacion manual, upload local -> Supabase, descarga Supabase -> local, deteccion de conflictos, sincronizacion automatica y estado observable de UI para Books, Reading Sessions, Reader Profile y Annual Goal.

## Persistencia

- `AppDatabase` tiene `schemaVersion = 6`.
- Tablas: `books`, `reading_sessions`, `sync_metadata`.
- Tabla manual adicional: `app_settings` para configuracion simple como `annualReadingGoal`.
- `sync_metadata` guarda estado operativo de sincronizacion por `entity_type + local_id`, separado de los datos de producto.
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
- Supabase Auth opcional para cuenta/login cuando `SUPABASE_URL` y `SUPABASE_ANON_KEY` estan configurados.
- Supabase Database schema preparado en SQL para sincronizacion remota, pendiente de aplicar y validar en proyecto real cuando existan credenciales/proyecto enlazado.
- No hay Firebase, Stripe ni backend propio. Existe sincronizacion local -> Supabase, descarga Supabase -> local, sincronizacion automatica y UI de estado para Books, Reading Sessions, Reader Profile y Annual Goal.

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
- Motivo observado: centralizar navegacion entre shell principal, listado, detalle de libro, calendario, detalle de dia, alta de sesion, stats e insights.
- Evidencia: `reading_tracker/lib/app.dart` contiene rutas `/`, `/home`, `/books`, `/book/add`, `/book/detail`, `/calendar`, `/calendar/day`, `/session/add`, `/stats`, `/progress`, `/insights` y `/settings`.

### Navegacion principal Hito 5 Sprint 1

- Decision: usar una `NavigationBar` Material 3 en `MainNavigationScreen` como entrada principal de la app.
- Tabs principales: Inicio, Biblioteca, Progreso, Insights y Ajustes.
- `/` abre `MainNavigationScreen`.
- `/home` conserva acceso directo a `HomeScreen` para no romper navegacion interna o pruebas futuras.
- `Progreso` funciona como hub y no reemplaza las pantallas existentes.
- `ProgressScreen` enlaza a `/stats`, `/calendar` y `/session/add`; Reading Challenge usa `/stats` porque el objetivo anual ya vive ahi.
- `Insights` abre directamente la pantalla existente `InsightsScreen` dentro del tab.
- `Ajustes` incluye selector de tema; no hay perfil real, autenticacion, Firebase ni persistencia de negocio nueva.
- Las rutas internas existentes siguen disponibles para push desde cards, detalle, formularios y calendario.

### Design System Hito 5 Sprint 2

- Decision: centralizar temas, tokens y componentes visuales base antes de redisenar pantallas completas.
- Temas disponibles: Burgundy por defecto y Forest seleccionable.
- `ReadingTrackerTheme` define los valores de color y permite anadir futuros temas con un nuevo enum value.
- `AppTheme.light(theme)` genera `ThemeData` Material 3 desde el tema activo.
- `AppThemeController` usa Riverpod y `shared_preferences` para persistir la preferencia local de tema sin tocar Drift ni repositorios.
- `appThemeControllerProvider` es consumido por `App`, que reconstruye `MaterialApp` con el tema elegido.
- `core/theme/app_theme_tokens.dart` define spacing, radios, elevaciones y sombras suaves reutilizables.
- `core/design_system` expone `MetricCard`, `InsightCard`, `ProgressCard`, `SectionHeader` y `EmptyStateCard`.
- `SettingsScreen` incluye selector de tema y mantiene fuera de alcance login, perfil real y servicios externos.

### Branding & Visual Identity Hito 5 Sprint 2.5

- Decision: definir identidad visual global antes de continuar redisenando pantallas.
- `assets/branding` reserva estructura para logo principal, app icon y variantes futuras.
- `assets/fonts` reserva los archivos de Playfair Display e Inter; no se versionan fuentes definitivas aun.
- `AppBrand` centraliza nombre, wordmark, tagline y rutas previstas de assets.
- `BrandWordmark` permite usar asset de logo cuando exista y fallback textual mientras tanto.
- `AppTypography` centraliza Playfair Display para titulos e Inter para contenido.
- `ThemeData` global aplica la tipografia y conserva Burgundy/Forest como paletas oficiales.
- `AppIcons` centraliza iconografia usando Material Icons redondeados como puente hacia una futura migracion a Lucide o equivalente.
- `AppMotion`, `AppFadeSlideTransition` y `AppPressable` preparan motion reutilizable para cards, FAB, cambios de tema y transiciones basicas.
- La navegacion principal y Home ya consumen `AppIcons`; no se redisenan Biblioteca, Estadisticas, Insights ni Detalle Libro.

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

### Shared UI components Hito 6 Sprint 18.x

- `ReadPpPageHeader` / header compartido centraliza la composicion visual superior basada en Biblioteca.
- El header compartido soporta logo ReadPp, perfil opcional, titulo/saludo, subtitulo opcional, acciones principales, SafeArea, padding y spacing comunes.
- Home y Biblioteca son las primeras pantallas alineadas al header compartido.
- `CurrentReadingCard` / card destacada de lectura actual se usa como implementacion visual unica para lectura actual destacada.
- La card compartida evita CTA interno y expone la navegacion desde la card completa.
- La card compartida debe tolerar titulo largo con maximo 3 lineas y ellipsis, autor con ellipsis, portada remota/local o placeholder, una o varias lecturas activas y Android/Web/Desktop.
- El carrusel de lecturas activas vive fuera del concepto de seleccion principal: PageView/swipe permite revisar lecturas y la accion de cambiar principal actualiza explicitamente la preferencia.

### Calendar y Reading Journal sync Hito 6 Sprint 18.x

- `CalendarScreen`, `ReadingJournalScreen`, `ReadingSessionRepository` y providers de fecha seleccionada deben compartir una unica fuente coherente de sesiones por dia.
- Crear, editar o borrar una sesion debe invalidar/refrescar los providers necesarios para que calendario y diario reflejen cambios sin reiniciar.
- El diario mantiene estado local de sesion/libro seleccionado para el dia activo.
- Las cards pequenas de sesion modifican la seleccion local; la card principal concentra la navegacion al detalle.
- La UI del calendario no debe codificar detalle textual dentro de la celda; usa portadas pequenas y contador `+N` como representacion compacta.

### Book Search multi-source Hito 6 Sprint 18.15-18.17

- `BookSearchRepository` es la fachada unica de busqueda remota para la presentacion.
- La presentacion no debe conocer si el resultado viene de Open Library, Google Books u otro proveedor futuro.
- Open Library se mantiene como datasource primario.
- `GoogleBooksDatasource` se incorpora como datasource secundario.
- Estrategia de fallback: Open Library con resultados detiene la busqueda; Open Library sin resultados/error/timeout activa Google Books; Google Books sin resultados/error activa alta manual.
- Los resultados de proveedores se normalizan al mismo modelo de dominio usado por el formulario de alta: titulo, autor, portada, ISBN, paginas, `externalSource` y `externalId`.
- `externalSource` usa valores explicitos como `open_library` y `google_books`.
- `externalId` debe guardarse normalizado, sin acoplar la UI a claves crudas de proveedor.
- Los errores de busqueda se clasifican para UX: sin conexion, timeout, API no disponible, respuesta invalida y sin resultados.
- Los detalles tecnicos y nombres de proveedores se registran solo en debug.

### Book deduplication Hito 6 Sprint 18.15-18.17

- `BookDuplicateMatcher` centraliza la deteccion de duplicados antes de guardar libros de API o manuales.
- Orden de comparacion: ISBN normalizado, `externalSource + externalId`, titulo+autor normalizados.
- La normalizacion de titulo/autor elimina diferencias de casing, espacios duplicados, diacriticos y puntuacion basica.
- La deduplicacion entre proveedores permite evitar casos como Open Library y Google Books devolviendo variantes del mismo libro.
- La deduplicacion tambien prepara el enriquecimiento futuro de libros manuales con datos remotos sin crear duplicados.
- La UX ante duplicado no persiste un nuevo libro y ofrece ver libro, cambiar estado o cancelar.

### Drift schema Hito 6 Sprint 18.15b

- La tabla de libros incorpora columnas nullable `externalSource` y `externalId`.
- La migracion de Drift es segura para usuarios existentes: libros previos mantienen datos aunque esos campos queden null.
- La version de esquema vigente tras este cambio queda documentada como schemaVersion 5.
- Los mappers de libro deben conservar `externalSource` y `externalId` entre entidad, companion y filas Drift.
- Libros creados desde Open Library deben persistir `externalSource = open_library`.
- Libros creados desde Google Books deben persistir `externalSource = google_books`.

### Manual book entry, ISBN scanner y local cover Hito 6 Sprint 18.16

- El alta manual es un fallback posterior a busqueda remota fallida o sin resultados.
- Campos manuales: titulo obligatorio, autor recomendado, total de paginas opcional, ISBN opcional, estado inicial y portada opcional.
- El escaneo ISBN se implementa como ayuda opcional mediante camara; si se rechaza permiso o falla el escaneo, el flujo manual continua.
- Tras escanear ISBN, se intenta completar datos mediante `BookSearchRepository`; si no hay resultado, se permite guardar manualmente con ISBN rellenado.
- La portada local se obtiene desde camara/galeria cuando sea viable, se copia a documentos de la app y se persiste como ruta local.
- Las portadas locales no se suben a backend.
- `BookCoverImage` debe soportar `file://`, URLs remotas y placeholder editorial ReadPp.
- Datos de usuario como estado, progreso, sesiones, rating y review tienen prioridad y no deben perderse en futuros enriquecimientos.

### Roadmap backend y sincronizacion

- La arquitectura vigente sigue local-first con Drift/SQLite.
- Supabase ya esta integrado como backend progresivo para Auth, backend cloud y sincronizacion multi-dispositivo.
- La sincronizacion implementada cubre biblioteca, sesiones, perfil lector y objetivo anual; estadisticas se derivan localmente desde esos datos.
- La persistencia local debe mantenerse incluso cuando exista backend para funcionamiento sin conexion o con conectividad limitada.

### Preparacion futura de relecturas Hito 7 Sprint 19.5

- Sprint 19.5 no activa relecturas ni modifica el modelo `Book`.
- Una relectura futura no debe duplicar el libro ni sobrescribir el historial de la lectura anterior.
- La evolucion recomendada es introducir una entidad separada `ReadingCycle` o `BookReading` relacionada con `Book`.
- Cada ciclo podria almacenar inicio, fin, estado, pagina actual y numero de relectura.
- `ReadingSession` podria incorporar en una migracion futura un `readingCycleId` nullable para asociar sesiones a un ciclo concreto.
- La biblioteca, metadata, portada, ISBN, rating y review general seguirian perteneciendo a `Book`; progreso y sesiones por intento pertenecerian al ciclo.
- La migracion futura debe asignar las sesiones existentes a un primer ciclo sin perder datos ni cambiar el comportamiento actual.
- No crear columnas o tablas de relectura hasta que exista un sprint funcional especifico y casos de uso definidos.

### Accessibility y navegacion principal Hito 7 Sprint 19.7

- `MainNavigationScreen` es el shell de todas las tabs principales y recibe `initialIndex` para deep links/rutas internas.
- Las rutas principales no deben construir directamente Home, Biblioteca, Insights o Settings fuera de ese shell.
- Componentes visuales compartidos deben exponer semantica opcional en su propia API cuando conocen el contexto, como `BookCoverImage.semanticLabel`.
- Responsive debe resolverse en presentacion mediante `LayoutBuilder`, `Wrap`, constraints y `MediaQuery.textScalerOf`, sin contaminar dominio o persistencia.
- La informacion comunicada por color debe tener equivalente textual o semantico.

### Observabilidad Hito 6 Sprint 20.1

- `core/observability/readpp_sentry.dart` centraliza la integracion con Sentry.
- La app inicializa Sentry desde `main.dart` mediante `ReadPpSentry.init`.
- Sentry se habilita solo en release y con `SENTRY_DSN` definido via `dart-define`.
- `SENTRY_ENVIRONMENT` y `SENTRY_RELEASE` controlan el entorno y la version reportados sin hardcodear secretos.
- Los observers de navegacion se obtienen desde `ReadPpSentry.navigatorObservers()` para evitar acoplar pantallas a Sentry.
- Open Library agrega breadcrumbs y captura excepciones desde helpers especificos de `ReadPpSentry`.
- Los eventos de busqueda incluyen contexto diagnostico, tags y metadata, pero la UX mantiene mensajes genericos y accionables para usuario final.
- La infraestructura temporal de validacion manual se retiro tras Sprint 20.1; no debe quedar ruta oculta, flag de validacion ni metodo manual de captura en builds normales.
- Validacion real confirmada en Web Release: evento recibido en Sentry con environment `alpha` y release `0.2.0-alpha`.

### Analytics Hito 6 Sprint 20.2

- `core/analytics/readpp_analytics.dart` centraliza analytics de producto, separado de Sentry.
- Sentry responde a errores; Analytics responde a comportamiento de usuario.
- `ReadPpAnalytics` expone metodos semanticos como `trackBookAdded`, `trackSearchStarted` y `trackAnnualGoalUpdated`.
- PostHog queda detras de la capa propia; widgets y pantallas no deben llamar directamente a PostHog.
- La configuracion se inyecta por `dart-define` con `ANALYTICS_ENABLED`, `POSTHOG_API_KEY`, `POSTHOG_HOST` y `APP_ENV`.
- Las claves no se hardcodean, no se guardan en repositorio y no se guardan en Memory Bank.
- Sin configuracion valida, la capa funciona como no-op y no altera flujos de producto.
- El envio actual usa HTTP al endpoint PostHog `/i/v0/e/`, con `distinct_id` anonimo persistido en `SharedPreferences`.
- Los eventos se envian con `$process_person_profile=false`.
- La privacidad se aplica en origen: no enviar titulos, autores, notas, resenas, nombre de usuario ni query exacta; usar buckets, booleanos, longitudes y contadores.
- Los puntos de instrumentacion preferidos son use cases/providers/datasources donde ocurre la mutacion o evento real, no widgets puramente visuales.
- Validacion real completada en PostHog: eventos visibles en `Activity` y `Trends`.

### Backend Supabase Hito 7 Sprint 21.1-21.9

- La decision base esta registrada en `docs/adr/ADR-001-local-first.md`: ReadPp mantiene arquitectura Offline First / Local First.
- Drift sigue siendo la fuente de verdad durante el uso normal de la app.
- Supabase no sustituye a Drift; se usa como backend progresivo para Auth, recuperacion y sincronizacion remota.
- La estrategia de autenticacion esta registrada en `docs/adr/ADR-002-authentication-strategy.md`.
- Auth v1 queda limitado a Google OAuth y email/contrasena.
- `supabase_flutter: ^2.15.0` queda agregado como dependencia oficial.
- `core/backend` centraliza la infraestructura transversal de Supabase:
  - `supabase_config.dart`
  - `supabase_initializer.dart`
  - `supabase_client_provider.dart`
- La configuracion se lee por `String.fromEnvironment` usando `SUPABASE_URL` y `SUPABASE_ANON_KEY`.
- Si faltan variables, Supabase queda deshabilitado y la app sigue arrancando en modo local.
- `features/auth` queda creado por capas:
  - `domain/app_user.dart`
  - `domain/auth_repository.dart`
  - `data/auth_repository_impl.dart`
  - `presentation/controllers/auth_controller.dart`
  - `presentation/screens/auth_screen.dart`
  - `presentation/screens/account_screen.dart`
  - `presentation/screens/account_transition_screen.dart`
- `AppUser` contiene solo datos seguros y necesarios: `id`, `email`, `displayName` y `avatarUrl`.
- `AuthRepository` prepara usuario actual, stream de sesion, email/password, registro, Google OAuth y logout.
- `AuthController` expone estado de sesion, loading, error y acciones preparadas mediante Riverpod.
- `AccountScreen` es la entrada de producto para Cuenta: muestra `Modo local` sin sesion y `Sesion iniciada` con email/logout cuando hay usuario.
- `AccountTransitionScreen` explica la transicion desde almacenamiento local hacia cuenta cloud antes de registro/login.
- `AuthScreen` esta integrada en el flujo `/account/auth` y puede abrir en modo registro o inicio de sesion.
- La navegacion integra `/account`, `/account/transition` y `/account/auth` dentro de `MainNavigationScreen`, conservando el shell y la bottom navigation.
- Perfil/Ajustes (`SettingsScreen`) muestra una card visible `Cuenta` con resumen del estado de autenticacion.
- Sprint 21.5 agrega preparacion de migracion local a cuenta:
  - `domain/entities/account_migration_preparation.dart`
  - `domain/usecases/prepare_account_migration.dart`
  - `presentation/controllers/account_migration_controller.dart`
- `PrepareAccountMigration` consulta unicamente repositorios locales existentes para construir un resumen de datos preparado para futura sync.
- `AccountMigrationController` orquesta esta preparacion desde presentacion y mantiene `AuthController` centrado en autenticacion.
- La pantalla de Cuenta puede mostrar el resultado de preparacion local cuando hay usuario autenticado.
- Auth no debe bloquear el uso local: sin Supabase configurado el estado es no autenticado y el error aparece solo si el usuario intenta iniciar sesion.
- No existe sincronizacion todavia.
- Existe migracion Drift de Hito 7 para `sync_metadata`.
- Existe migracion SQL de tablas Supabase y RLS en repositorio, pero no aplicada ni validada contra Supabase real desde esta ejecucion.
- Existe metadata local preparada para asociar datos locales con futuros IDs remotos; no hay transferencia real de datos al `user.id` todavia.
- Decision Sprint 21.4: preparar UX de cuenta y transicion cloud sin tocar biblioteca, progreso, sesiones, estadisticas, preferencias ni persistencia local.
- Decision Sprint 21.5: preparar un resultado en memoria para asociacion futura a `user.id`, sin escribir en Drift ni llamar a Supabase.
- ADR relacionado: `ADR-003-account-migration-preparation.md`.

### Modelo remoto Supabase y RLS Sprint 21.6

- La estructura remota queda definida en `supabase/migrations/202606270001_remote_data_model.sql`.
- Tablas remotas iniciales:
  - `profiles`
  - `books`
  - `reading_sessions`
  - `annual_goals`
- Todas las tablas remotas incluyen `created_at`, `updated_at` y `deleted_at`.
- `deleted_at` queda reservado para soft delete e incremental sync futura; la app no lo usa todavia.
- Las entidades sincronizables usan UUID remoto propio como `id`.
- Los identificadores locales se conservan en columnas separadas como `local_book_id`, `local_session_id` y `local_goal_id`.
- `profiles.id` se corresponde con `auth.users.id`.
- RLS queda habilitado en SQL para todas las tablas.
- Politicas minimas definidas: `SELECT`, `INSERT`, `UPDATE` y `DELETE`.
- Regla general de propiedad: `auth.uid() = user_id`.
- Regla de `profiles`: `auth.uid() = id`.
- `features/sync` contiene entidades remotas desacopladas de Drift, DTOs remotos serializables, mappers DTO <-> entidad, contratos de repositorios remotos, contrato abstracto de datasource remoto y constantes de tablas remotas.
- No hay repositorios concretos de Supabase en este sprint.
- No hay llamadas desde UI.
- No hay sync local -> nube ni nube -> local.
- ADR relacionado: `ADR-004-remote-data-model-and-rls.md`.

### Validacion Supabase real Sprint 21.8

- La migracion SQL remota fue revisada antes de aplicarse en un entorno real.
- Se agrego `public.set_updated_at()` y triggers por tabla para mantener `updated_at` en operaciones `UPDATE`.
- La validacion real de RLS queda documentada en `docs/architecture/sprint-21-8-supabase-rls-validation.md`.
- La guia usa dos usuarios reales de Auth para verificar aislamiento de `SELECT`, `INSERT`, `UPDATE` y `DELETE`.
- Desde esta ejecucion no se aplico la migracion al proyecto real porque no hay CLI Supabase/psql ni conexion autenticada disponible.
- No cambia la decision arquitectonica de ADR-004; por eso no se crea ADR nuevo.

### Metadata local de sincronizacion Sprint 21.7

- Drift incorpora `sync_metadata` como tabla local unica para estado de sincronizacion.
- `sync_metadata` usa `id` como clave primaria y una restriccion unica sobre `entity_type + local_id`.
- Campos de asociacion: `entity_type`, `local_id` y `remote_id`.
- Campos de estado: `sync_status`, `pending_operation`, `last_synced_at`, `last_local_update`, `last_remote_update`, `error_message` y `retry_count`.
- Campos de auditoria local: `created_at` y `updated_at`.
- Los tipos se exponen en dominio mediante enums: `SyncEntityType`, `SyncStatus` y `PendingSyncOperation`.
- `SyncMetadataRepository` define el contrato de dominio para crear, consultar pendientes, asociar remoto, marcar synced/pending y registrar fallos.
- `LocalSyncMetadataRepository` y `SyncMetadataDao` encapsulan Drift y evitan que los futuros use cases dependan de tablas.
- `syncMetadataRepositoryProvider` queda preparado para inyeccion Riverpod.
- No hay llamadas Supabase, no hay UI y no hay mutaciones automaticas de metadata desde los repositorios de producto en este sprint.
- ADR relacionado: `ADR-005-local-sync-metadata.md`.

### Tracking local de mutaciones Sprint 21.9

- `LocalSyncTracker` es la capa coordinadora para registrar metadata de sync desde mutaciones locales.
- El tracker traduce operaciones de producto a estados de sync:
  - create -> `pendingUpload` / `create`;
  - update -> `pendingUpdate` / `update`;
  - delete -> `pendingDelete` / `delete`.
- `BookRepositoryImpl` y `ReadingSessionRepositoryImpl` invocan el tracker solo despues de persistir correctamente en Drift.
- `SaveAnnualReadingGoal` invoca el tracker despues de guardar el objetivo anual en `app_settings`.
- `ReaderProfileController` invoca el tracker despues de persistir cambios del perfil lector en `SharedPreferences`.
- Entidades singleton usan IDs locales estables: `annualReadingGoal` y `reader_profile`.
- La app no consume Supabase desde estas mutaciones y no cambia comportamiento visual.
- Riesgo tecnico aceptado: `core/preferences` conoce `features/sync` para marcar perfil lector; si el perfil crece, conviene moverlo a feature propia o extraer un contrato de tracking/preferencias.

### Sincronizacion manual Books Sprint 22.0

- Sprint 22.0 implementa la primera sincronizacion manual local -> Supabase, limitada a Books.
- El caso de uso manual recibe `userId` como parametro explicito para mantener testabilidad y evitar acoplar dominio a Auth/UI.
- El flujo consume `SyncMetadataRepository.getPendingSync()`, filtra `SyncEntityType.book` y procesa `PendingSyncOperation.create`, `update` y `delete`.
- Para `create` y `update`, el flujo carga el libro local con `BookDao.getBookById`, construye `RemoteBook` con el modelo remoto parcial existente y llama a `RemoteBooksRepository.upsertBooks`.
- Tras upsert correcto, la metadata se marca como `synced`, conserva/guarda `remoteId` y actualiza timestamps de sync/remoto cuando estan disponibles.
- Para `delete`, si existe `remoteId`, se llama a borrado remoto; si no existe `remoteId`, se marca como `synced` sin llamada remota porque no hay registro remoto que borrar.
- No se sincronizan Reading Sessions, perfil lector ni objetivo anual en Sprint 22.0.
- No hay recuperacion nube -> local.
- No hay sincronizacion automatica ni worker/background sync.
- La UI queda intacta; el use case queda disponible para ejecucion manual desde provider o futuros flujos.
- En Supabase Books, el upsert remoto usa `id` como conflict target porque el indice `user_id + local_book_id` del schema es parcial con `WHERE deleted_at IS NULL`.
- `local_book_id` sigue viajando en la fila como identidad local, pero no se usa como conflict target directo en este sprint.
- Esta decision puede afectar proximos sprints de reconciliacion por `local_book_id`, borrado logico y sync nube -> local.
- Validacion Sprint 22.0: `flutter analyze` OK y `flutter test` OK con 94/94 tests.

### Hito 8 - Sincronizacion de datos Sprint 22.0-22.8

- Estado: COMPLETADO.
- Sprint 22.0 cerrado: Upload Books.
- Sprint 22.1 cerrado: `SyncOrchestrator`.
- Sprint 22.2 cerrado: Upload Reading Sessions.
- Sprint 22.3 cerrado: Upload Reader Profile.
- Sprint 22.4 cerrado: Upload Annual Goal.
- Sprint 22.5 cerrado: Cloud Download.
- Sprint 22.6 cerrado: Conflict Detection.
- Sprint 22.7 cerrado: Automatic Synchronization.
- Sprint 22.8 cerrado: Sync Status UI.
- ReadPp mantiene arquitectura offline-first: Drift es la fuente de verdad local y Supabase actua como backend remoto.
- `sync_metadata` coordina el estado por `entity_type + local_id`.
- `LocalSyncTracker` registra cambios locales despues de persistir correctamente en Drift, SharedPreferences o `app_settings`.
- `SyncOrchestrator` es el punto unico de sincronizacion.
- `AutoSyncCoordinator` ejecuta la sincronizacion automatica sin cambiar el comportamiento de los flujos manuales.
- `SyncStatusController` es la capa observable que alimenta la UI de estado.
- El orquestador separa dos flujos independientes: `runManualSync()` para Local -> Supabase y `runManualDownload()` para Supabase -> Local.
- Flujos existentes: `runManualSync()`, `runManualDownload()`, `AutoSyncCoordinator` y `SyncStatusController`.
- El orden de ejecucion es Books, Reading Sessions, Reader Profile y Annual Goal.
- La subida local -> Supabase consume `sync_metadata`, procesa `create`, `update` y `delete`, sube cada entidad soportada, guarda `remoteId` y marca synced si la operacion remota finaliza correctamente.
- La descarga Supabase -> local es conservadora: solo aplica registros remotos cuando el equivalente local no tiene `pendingOperation != none`.
- La descarga usa `includeDeleted = false` y no procesa borrados remotos en este tramo.
- La resolucion de conflictos de Sprint 22.6 solo detecta y registra: si existe cambio local pendiente y `remote.updatedAt` es posterior a `lastRemoteUpdate`, se marca `syncStatus = conflict`.
- `markConflict` conserva `pendingOperation`, guarda `remoteId`, `lastRemoteUpdate` y `errorMessage`, y no marca synced.
- El upload local mantiene prioridad para preservar datos locales.
- No existe todavia resolucion automatica ni merge campo a campo.
- La UI de estado existe en Cuenta/Perfil mediante `SyncStatusCard`.
- El modelo observable usa `SyncStatusState`, `LastSyncResult` y estados `idle`, `syncing`, `synced`, `pendingChanges`, `conflict` y `failed`.
- Validacion Sprint 22.8: `flutter analyze` OK y `flutter test` OK con 164/164 tests.

### Hallazgos arquitectonicos revision Sprint 19

- `MainNavigationScreen` debe ser un shell unico por flujo principal; navegar entre tabs requiere coordinacion de indice, no apilar nuevas instancias del shell.
- `CurrentReadingCard` contiene una accion de apertura de card y otra accion interna de cambio de principal; su arbol semantico debe conservar ambas acciones como nodos distinguibles.
- Charts dibujados con `CustomPainter` necesitan un wrapper `Semantics` o resumen accesible con total, categorias y valores.
- Los calculos de series temporales deben exponer copy derivado de la misma serie/unidad para evitar divergencias entre grafica y subtitulo.

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

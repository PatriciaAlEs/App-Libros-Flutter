# Current State

## Producto

`reading_tracker` es una app Flutter mobile-first para registrar libros, sesiones de lectura, progreso, calendario, estadisticas basicas e insights de lectura.

Estado tras Hito 5 Sprint 13: ReadPp v1.0 RC esta completo y listo para Store Preparation.

Validacion vigente:

- `flutter analyze` OK.
- `flutter test` OK.

Sprint 13 completo:

- Auditoria visual general.
- Auditoria de navegacion.
- Auditoria tipografica.
- Revision basica de accesibilidad.
- Revision de store readiness.
- Limpieza de codigo.
- Estabilizacion de Release Candidate.

La Home ya funciona como biblioteca personal moderna. Actualmente ofrece:

- Header editorial `READPP •` con `Tu biblioteca personal` y saludo contextual.
- Hero de lectura actual con portada protagonista para el libro en estado `Leyendo` mas reciente.
- Registro rapido de avance desde el hero de lectura actual.
- Metricas compactas de racha actual, completados del ano y paginas leidas.
- Objetivo lector anual en card independiente.
- Actividad reciente compacta.
- FAB para anadir libro.
- Sugerencias de pendientes cuando no hay lecturas activas.
- Empty state de primer uso orientado a anadir el primer libro.

## Onboarding / First Run Experience

Estado actual implementado:

- Onboarding funcional de primera apertura.
- El flujo tiene 3 pantallas:
  - `Tu viaje lector, en un solo lugar`.
  - `Registra tus lecturas`.
  - `Descubre tu perfil lector`.
- Incluye acciones `Omitir`, `Siguiente` y `Empezar`.
- Incluye indicador visual de progreso.
- El estado completado se persiste localmente con `SharedPreferences`.
- La flag usada es `onboarding_completed`.
- El onboarding se muestra solo si la flag no existe o esta en `false`.
- Al completar u omitir, la app entra en el flujo normal.
- Los usuarios recurrentes no ven onboarding automaticamente.
- No se introdujo login, backend, sincronizacion ni nueva arquitectura.
- El estilo visual mantiene Burgundy/Forest y la estrategia tipografica Roboto + Space Grotesk.

## UX Home

Estado actual implementado:

- Si existen varios libros en estado `Leyendo`, Home prioriza como hero el actualizado/iniciado mas recientemente.
- Si no hay libros en estado `Leyendo`, Home muestra sugerencias de libros pendientes.
- Las sugerencias de pendientes priorizan libros mas antiguos usando la fecha disponible de alta/creacion.
- El hero de lectura actual muestra portada, titulo, autor, porcentaje, pagina actual/total y barra de progreso.
- Si falta `totalPages`, se mantiene CTA para registrar avance y completar datos.
- El registro rapido desde Home usa un dialogo centrado, no bottom sheet.
- El dialogo mantiene campos de pagina actual, paginas leidas y minutos.
- El dialogo permite guardar cambios o ir al detalle completo del libro.
- El contenido del dialogo es scrollable para evitar overflow en movil.
- El bloque grande "Anadir nuevo libro" fue eliminado.
- El FAB es la entrada principal para anadir libros desde Home.

## Actividad reciente

Estado actual implementado:

- El registro rapido desde Home crea una `ReadingSession` cuando `pagesRead > 0` o `minutes > 0`.
- Se reutiliza el repositorio/provider existente de sesiones.
- Tras guardar, se refresca el provider usado por la actividad reciente.
- Home muestra actividad reciente de los ultimos 30 dias.
- Las sesiones se ordenan por `createdAt` descendente.
- Se muestran como maximo 3 sesiones para mantener densidad compacta.
- La accion secundaria `Ver actividad` abre el calendario.
- Empty state actual: "Cuando registres una sesion, aparecera aqui."

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

- La app entra por una navegacion principal inferior personalizada/editorial.
- Tabs principales: Inicio, Biblioteca, Progreso, Insights y Ajustes.
- La navegacion principal vive exclusivamente en la barra inferior; Home no duplica accesos principales en el AppBar.
- Inicio muestra la Home/dashboard actual.
- Biblioteca abre una pantalla editorial premium centrada en portadas.
- Progreso abre un dashboard editorial premium de avance lector.
- Insights abre directamente la pantalla Insights existente.
- Ajustes incluye selector de tema Burgundy/Forest con preferencia persistida localmente; no implementa perfil real ni login.
- Las rutas existentes se mantienen para navegacion interna y compatibilidad.
- Home mantiene su dashboard editorial, con metricas rapidas horizontales y actividad reciente como reading journal.
- Biblioteca usa un icono de libros.
- La vista general de Biblioteca muestra featured reading arriba si hay libro en estado `Leyendo`.
- El grid prioriza portadas y reduce metadata tecnica.
- Se mantienen filtros por estado con segmented control compacto: Todos, Pendientes, Leyendo, Completados, Pausados y Aband.
- El conteo de libros aparece junto a `Coleccion` y refleja el filtro activo.
- La marca `dP + ReadPp` en Biblioteca navega a Home.
- Cada card prioriza portada, titulo, autor y progreso opcional.
- Los libros en lectura muestran progreso si tienen `currentPage` y `totalPages`.
- Los libros completados muestran rating si estan valorados.
- Los empty states de Biblioteca son editoriales y no generan scroll excesivo.
- La bottom nav mantiene `Insights` como label y usa rosa/accent muted en iconos no seleccionados.

## Progreso

Estado actual implementado:

- `ProgressScreen` ya no es una lista simple de accesos.
- Header editorial con marca `dP + ReadPp`, saludo contextual, titulo `Tu Progreso` y subtitulo humano.
- La marca navega a Home (`/`).
- Card protagonista Burgundy/Forest con racha actual, libros completados este ano, paginas leidas y lectura activa real si existe.
- Card de reto lector anual usando `StatisticsSummary`: objetivo, completados, porcentaje y barra visual.
- CTA del reto lleva a `/stats`, donde ya existe la configuracion/edicion del objetivo anual.
- Card de actividad lectora con accesos a calendario y registrar sesion.
- Actividad lectora muestra sesiones recientes reales desde `readingSessionsForRangeProvider`; no inventa datos.
- Accesos rapidos a Estadisticas, Calendario y Registrar sesion se muestran como cards premium con icono, titulo y descripcion.
- No se tocaron Drift, repositorios, modelos ni logica de negocio para este redisenio.

## Book Detail

Estado actual implementado:

- Book Detail funciona como ficha editorial premium, no como formulario CRUD.
- Hero superior inmersiva con portada protagonista, fondo Burgundy/Forest, titulo, autor, badge de estado y progreso.
- Progress card muestra porcentaje, pagina actual/total, paginas restantes cuando aplica y CTA `Actualizar progreso`.
- Acciones rapidas que no tienen funcionalidad real se muestran como `Proximamente` o secundarias.
- La accion de fechas conserva la funcionalidad existente de editar fechas de lectura.
- Informacion editorial se muestra en pills/cards: genero, paginas, publicacion y rating.
- Sinopsis/notas tienen spacing editorial y mejor jerarquia visual.
- Sesiones recientes se muestran como timeline con fechas humanas.
- Eliminar libro queda accesible pero visualmente secundario.

## Reading Insights

Estado actual implementado:

- Hito 4 - Reading Insights iniciado.
- Sprint 1 completado y validado.
- Existe la feature `features/insights` con capas `domain`, `data` y `presentation`.
- `ReadingInsightsSummary` centraliza datos de perfil lector, mejores lecturas y curiosidades, manteniendo campos legacy de sprints anteriores.
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
- El empty state actual guia hacia anadir el primer libro cuando no hay datos suficientes para generar insights.
- Las mutaciones de libros y sesiones invalidan `readingInsightsSummaryProvider` cuando corresponde.
- Hay tests focalizados para el calculo de insights.
- Hito 4 Sprint 2 completado y validado.
- `ReadingInsightsSummary` tambien expone paginas por sesion, minutos por sesion y paginas por dia.
- La prediccion de fin de libro estima paginas restantes, ritmo reciente, dias restantes y fecha aproximada para un libro en estado `reading`.
- El forecast anual proyecta libros completados para final de ano usando el ritmo actual de completados.
- Los calculos de Sprint 2 usan solo `Book` y `ReadingSession`; no hay tablas nuevas, servicios externos ni IA.
- La pantalla `InsightsScreen` muestra secciones para Preferencias, Reading Pace, Finish Prediction y Annual Forecast.
- Los estados vacios cubren falta de sesiones, falta de libro en lectura o datos insuficientes.
- Hito 4 Sprint 3 completado y validado.
- `ReadingInsightsSummary` tambien expone Top Lecturas del Año y Ranking Personal.
- Top Lecturas del Año incluye mejor valorado, mas largo, mas tiempo invertido y mas sesiones.
- Ranking Personal incluye Top 3 autores, generos y libros por paginas leidas acumuladas.
- Ranking Personal reutiliza la mejor racha existente calculada por `StatisticsCalculator`.
- La pantalla `InsightsScreen` suma secciones para Top Lecturas del Año y Ranking Personal.
- Hito 4 Sprint 4 implementado como perfil lector premium.
- La pantalla `InsightsScreen` ya no muestra Finish Prediction, Annual Forecast, Ranking Personal ni Mejor racha.
- La pantalla se reorganiza en `Tu perfil lector`, `Tus mejores lecturas` y `Curiosidades`.
- `Tu perfil lector` muestra autor favorito, genero favorito y libro al que mas tiempo se dedico.
- `Tus mejores lecturas` muestra Top 3 lecturas del año por rating.
- `Curiosidades` muestra libro mas largo, mes con mas lectura, franja horaria habitual y dia mas activo.
- Sprint 4 reutiliza datos existentes de `Book` y `ReadingSession`; no hay tablas nuevas, servicios externos ni IA.

## Validacion

Estado confirmado por el usuario:

- `flutter analyze` OK.
- `flutter test` OK (34/34 tests).
- `dart format` OK.
- El usuario ejecuta `dart format`, `flutter analyze` y `flutter test` desde VS Code.
- Actualizacion Sprint 12: las validaciones vigentes son `flutter analyze` OK y `flutter test` OK (34/34 tests). Las notas historicas de sprints anteriores se conservan como historial.
- Sprint 4 esta pendiente de validacion local por el usuario.
- Hito 5 Sprint 1 esta pendiente de validacion local por el usuario.
- Hito 5 Sprint 2 - Design System esta implementado y pendiente de validacion local por el usuario.
- Sprint 2 agrega temas Burgundy/Forest, tokens visuales y componentes reutilizables sin redisenar Home, Biblioteca, Estadisticas ni Insights.
- Hito 5 Sprint 2.5 - Branding & Visual Identity esta implementado y pendiente de validacion local por el usuario.
- Sprint 2.5 agrega estructura de branding, contrato de marca, tipografia Playfair/Inter, adaptador de iconos y motion reutilizable.
- Hito 5 Sprint 3 - Home Premium Redesign esta implementado y pendiente de validacion local por el usuario.
- Sprint 3 redisenia solo Home como biblioteca personal moderna: header READPP, hero de lectura actual, metricas compactas, objetivo lector y actividad reciente.
- Hito 5 Sprint 4 - Biblioteca Premium Redesign esta implementado y pendiente de validacion local por el usuario.
- Hito 5 Sprint 5 - Book Detail Premium Redesign esta implementado y pendiente de validacion local por el usuario.
- Hito 5 Sprint 5.1 - Home Visual Refinement esta implementado y pendiente de validacion local por el usuario.
- Hito 5 Sprint 6 - Biblioteca Visual Refinement esta implementado y pendiente de validacion local por el usuario.
- Hito 5 Sprint 7 - Book Detail Visual Refinement esta implementado y pendiente de validacion local por el usuario.
- Hito 5 Sprint 8 - Progress Premium Redesign esta implementado y pendiente de validacion local por el usuario.
- Hito 5 Sprint 9 - Library Premium Redesign esta implementado; Biblioteca conserva foco en libros, portadas, busqueda, filtros y anadir libros.
- Hito 5 Sprint 10 - Empty States & UX Polish esta implementado.
- Hito 5 Sprint 11 - Reading Sessions Premium esta implementado; calendario, detalle de dia y formulario de sesiones quedaron alineados al estilo premium.
- Hito 5 Sprint 11A/11B - UX Review Corrections estan implementados.
- Estado UX actual: Biblioteca no debe mostrar cards estadisticas superiores; conserva solo total textual de libros, busqueda, filtros, grid, boton `Anadir` y FAB.
- Estado UX actual: Perfil es pantalla de ajustes/preferencias, no dashboard. No muestra metricas lectoras, reto lector ni estadisticas globales; conserva selector de tema y seccion `Proximamente`.
- Estado UX actual: Insights es pantalla principal de descubrimientos/curiosidades con hero, panel de insight principal, metricas destacadas y cards editoriales.
- Estado UX actual: Add Book es pantalla premium para incorporar libros con buscador Open Library protagonista y formulario agrupado visualmente.
- Separacion conceptual actual: Home resumen general; Biblioteca coleccion; Progress seguimiento; Stats metricas; Insights descubrimientos; Perfil preferencias.
- Hito 5 Sprint 12 - Onboarding + First Run Experience completado y validado.
- Estado actual: ReadPp es feature-complete para v1; quedan tareas de release readiness.
- Hito 5 Sprint 13 - Release Candidate & Store Readiness completado y validado.
- Estado actual: ReadPp v1.0 RC Complete; Ready for Store Preparation.

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

1. Store Preparation para publicar ReadPp v1.0.
2. Preparar assets finales de Play Store: icono final, capturas, feature graphic si aplica.
3. Configurar firma de release y generar AAB firmado.
4. Publicar/hostear politica de privacidad y completar ficha de Play Store.

# Current State

## Producto

`reading_tracker` es una app Flutter mobile-first para registrar libros, sesiones de lectura, progreso, calendario, estadisticas basicas e insights de lectura.

Estado vigente: ReadPp esta en Alpha Testing & Polish con Observabilidad/Sentry, Analytics/PostHog, Supabase Auth, Hito 8 de sincronizacion y Hito 9 UX & Product completados y validados. El siguiente bloque es la Beta publica y futuras funcionalidades inteligentes: AI Assistant, automatizaciones y mejoras de producto.

Hito 9 - UX & Product completado:

- UX-003 implementado.
- UX-004 implementado.
- Onboarding actualizado a 4 pantallas.
- Coach Mark de sincronizacion implementado.
- Flujo de migracion para usuarios existentes implementado.
- Persistencia mediante `SharedPreferences` para onboarding, avisos, coach marks y preferencias ligeras.
- Integracion completa con Supabase Auth.
- Login con Email implementado y validado.
- Login con Google implementado y validado.
- Sincronizacion validada entre dispositivos.
- QA funcional completado en Android y Web.
- Validacion final: `flutter analyze` sin issues.
- Validacion final: `flutter test` 178/178.

## Cierre de fase actual - APK/Web

Estado registrado el 2026-07-08:

- Web/PWA: lista y desplegada en Vercel.
- URL publica: `https://readpp-web-alpha.vercel.app`.
- Procedimiento Web/PWA: build manual de Flutter Web y deploy desde `build/web`, nunca desde la raiz del proyecto.
- Comando Web/PWA validado: `flutter build web --release --dart-define-from-file=dart_defines/dev.json`.
- Proyecto Vercel: `readpp-web-alpha`.
- APK generada: `reading_tracker/build/app/outputs/flutter-apk/app-release.apk`.
- APK inspeccionada con `aapt`: package `com.readpp.app`, `versionName=1.0.0`, `versionCode=1`, `minSdkVersion=24`, `targetSdkVersion=36`.
- SHA1 APK: `8a771c6ab44b69cba34ad009877a1e8e3ef4b3b1`.
- Nota de versionado Android: una futura APK de actualizacion debe subir `versionCode` por encima de 1.

Integraciones documentadas:

- Supabase: backend progresivo para Auth y sincronizacion.
- Auth: Login con Email y Login con Google mediante Supabase Auth.
- Sync: sincronizacion offline-first para libros, sesiones, perfil lector y objetivo anual.
- PWA: Flutter Web desplegado en Vercel.
- Sentry: observabilidad de errores de release mediante `dart-define`.
- Analytics: PostHog mediante `ReadPpAnalytics` y configuracion por `dart-define`.

Sprint 18.x Alpha QA implementado:

- Home soporta multiples libros en estado `reading` con indicador `1 / N`, swipe completo y seleccion de lectura principal persistida.
- La card de lectura actual se unifico como card editorial burgundy: portada protagonista, titulo grande, autor, badge `LECTURA ACTUAL`, indicador `1 / N`, progreso y card completa clicable.
- `ReadPpPageHeader` / header compartido queda basado en Biblioteca como referencia visual, no en Home.
- Biblioteca es la pantalla fuente de verdad visual para headers, fondo, spacing y jerarquia.
- Calendario usa celdas blancas con intensidad por bordes/sombras/acento, portadas pequenas y selector Mes/Semana alineado a botones premium.
- Diario cambia a `Diario de lectura`, con titulo externo, card principal del dia con portada y seleccion local de sesion; las cards pequenas seleccionan sesion y no navegan al libro.
- Reading Challenge cambia el CTA a `Buscar libro`; la portada por defecto puede venir del ultimo libro completado y se mantiene opcion manual.
- Insights usa `Tu perfil lector`, `Mejores lecturas` y `Curiosidades`; autor favorito muestra libros/portadas.
- Open Library se robustecio con timeout, retry, errores tipados y logs debug.
- `BookSearchRepository` es el punto unico de entrada para busqueda de libros.
- `GoogleBooksDatasource` se agrega como proveedor secundario: Open Library -> Google Books -> alta manual.
- `BookDuplicateMatcher` centraliza deduplicacion por ISBN, `externalSource + externalId` y titulo+autor normalizados.
- `externalSource` y `externalId` se persisten en Drift con migracion segura de schemaVersion 5.
- Alta manual permite titulo obligatorio, autor recomendado, ISBN opcional, paginas opcionales, estado inicial y portada opcional.
- Escaneo ISBN se incorpora como ayuda mediante `mobile_scanner`; si falla o se rechaza camara, el flujo manual continua.
- Portada local usa `image_picker`, se copia a documentos de la app y se guarda como `file://` en `coverUrl`.
- `BookCoverImage` renderiza portadas remotas y locales, con placeholder editorial ReadPp cuando no hay portada.

Validacion vigente Sprint 18.17:

- `dart format` aplicado.
- `flutter analyze` OK.
- `flutter test` OK, 55/55 tests passed.
- Android Emulator compilo/arranco en validaciones recientes usando `JAVA_HOME=C:\Program Files\Android\Android Studio\jbr`.

Limitaciones conocidas:

- Escaneo ISBN y seleccion de portada local necesitan validacion manual en dispositivo/emulador con camara/galeria reales.
- Google Books se usa sin API key y como fallback publico; no hay backend ni cache remoto.
- La sincronizacion cloud manual ya existe para las entidades principales; ReadPp sigue offline-first con Drift/SQLite como fuente de verdad local.
- Logs de proveedor/fallback se limitan a debug.

Estado de roadmap:

- Hito 6 continua con Alpha QA, polish y Beta readiness.
- Hito 7 ya inicio con Premium Experience: Motion & Delight y Premium Statistics aplicados.
- Sprint 20.1 Observabilidad esta completado y validado.
- Sprint 20.2 Analytics esta completado y validado.
- Siguiente bloque: Beta publica.
- Proximo paso tecnico mayor post-Alpha: estabilizacion previa a beta con Auth, Google OAuth, sincronizacion multi-dispositivo y UX de migracion ya completadas.
- Hito 7: Premium Experience (motion, skeleton loaders, microinteracciones, empty states, estadisticas visuales premium).
- Hito 8 completado: Sincronizacion de datos offline-first sobre Supabase, con upload/download, sincronizacion automatica, deteccion de conflictos y estado visible en UI.
- QA post-Hito 8 completado: Auth email validado, restore remoto validado, upload local validado, bugs de `profiles.created_at` y refresco UI post-sync resueltos, y polish UX de sync/Home/alta de libro aplicado.
- Validacion automatizada vigente post-Hito 9: `flutter analyze` sin issues y `flutter test` OK con 178/178 tests.

## Hito 8 - Sincronizacion de datos

Estado: COMPLETADO.

Sprints completados:

- Completado: Sprint 22.0 Upload Books.
- Completado: Sprint 22.1 SyncOrchestrator.
- Completado: Sprint 22.2 Upload Reading Sessions.
- Completado: Sprint 22.3 Upload Reader Profile.
- Completado: Sprint 22.4 Upload Annual Goal.
- Completado: Sprint 22.5 Cloud Download.
- Completado: Sprint 22.6 Conflict Detection.
- Completado: Sprint 22.7 Automatic Synchronization.
- Completado: Sprint 22.8 Sync Status UI.

Arquitectura final:

- ReadPp implementa una arquitectura offline-first: Drift es la fuente de verdad local y Supabase es el backend remoto.
- `sync_metadata` coordina el estado de sincronizacion por entidad/local id.
- `LocalSyncTracker` registra cambios locales tras persistir correctamente en local.
- `SyncOrchestrator` es el punto unico de sincronizacion.
- `AutoSyncCoordinator` coordina la sincronizacion automatica.
- `SyncStatusController` expone el estado observable para la UI.
- Flujos existentes: `runManualSync()`, `runManualDownload()`, `AutoSyncCoordinator` y `SyncStatusController`.
- El orden fijo es Books, Reading Sessions, Reader Profile y Annual Goal.

Conflictos:

- La descarga nunca sobrescribe registros locales con `pendingOperation != none`.
- Si durante descarga existe cambio local pendiente y `remote.updatedAt` es posterior a `lastRemoteUpdate`, se marca `syncStatus = conflict`.
- `pendingOperation` se conserva y el upload local mantiene prioridad.
- `markConflict` persiste `remoteId`, `lastRemoteUpdate` y `errorMessage`.
- No existe todavia resolucion automatica ni merge campo a campo.

Estado de UI:

- Existe `SyncStatusCard` en Cuenta/Perfil.
- Existe `SyncStatusState` como modelo inmutable observable.
- Existe `LastSyncResult` ligero para diagnostico del ultimo intento.
- Estados observables: `idle`, `syncing`, `synced`, `pendingChanges`, `conflict` y `failed`.

Validacion vigente Hito 8:

- `flutter analyze` OK.
- `flutter test` OK.
- 173/173 tests tras QA post-Hito 8 y UX polish.

QA post-Hito 8:

- Auth por email funciona en entorno real Supabase: crear cuenta, login, logout y recuperacion de sesion tras limpiar datos locales.
- Google OAuth queda validado tras completar la configuracion externa del provider en Supabase y plataformas objetivo.
- La sincronizacion manual y automatica cubre subida local y descarga remota para entidades principales.
- Restore remoto tras reinstalacion/limpieza local recupera biblioteca y progreso.
- Tras merge remoto, Home/Biblioteca refrescan sin pull-to-refresh manual.
- Sync manual exitosa ofrece cierre UX con mensaje de exito y CTA hacia Inicio.
- `Otras lecturas` en Home cambia lectura principal; registrar avance queda reservado para la card principal.
- Alta de libro prioriza busqueda/resultados y confirma guardado en bottom sheet.

Bugs resueltos en QA post-Hito 8:

- `profiles.created_at` null en upsert remoto.
- Error generico de sync sin diagnostico suficiente.
- Providers de UI sin invalidacion tras descarga remota.
- Success flow ausente tras sync manual.
- Tap de `Otras lecturas` abriendo registro de avance en vez de cambiar lectura principal.
- Alta de libro con formulario demasiado alto antes de resultados.
- Overlay de microcelebracion con `Positioned` anidado incorrectamente.

## Hito 9 - UX & Product

Estado: COMPLETADO.

Alcance cerrado:

- UX-003 implementado.
- UX-004 implementado.
- Onboarding actualizado a 4 pantallas.
- Coach Mark de sincronizacion implementado.
- Flujo de migracion para usuarios existentes implementado.
- Persistencia ligera mediante `SharedPreferences`.
- Integracion completa con Supabase Auth.
- Login con Email implementado.
- Login con Google implementado.
- Sincronizacion validada entre dispositivos.
- QA funcional completado en Android y Web.

Decisiones de producto vigentes:

- ReadPp sigue siendo local-first: login y sync mejoran continuidad, pero no bloquean el uso local.
- La migracion de usuarios existentes debe explicar que los datos locales se conservan y que la cuenta habilita backup/sync multi-dispositivo.
- El Coach Mark de sincronizacion debe aparecer como ayuda contextual, no como intersticial obligatorio.
- Google OAuth queda activo solo con configuracion externa correcta de Supabase/proveedor y redirect/deep links validados.
- `SharedPreferences` es suficiente para flags de onboarding, coach marks, avisos y preferencias ligeras; Drift se reserva para datos de producto.

Validacion vigente Hito 9:

- `flutter analyze` sin issues.
- `flutter test` OK.
- 178/178 tests.

## LibrerIA Sprint 1

Estado: COMPLETADO.

Sprint 1 queda cerrado funcional y tecnicamente el 2026-07-09.

Alcance cerrado:

- Feature `libreria` creada.
- Acceso desde Home.
- Ruta `/libreria` disponible.
- UI base de LibrerIA como placeholder honesto.
- Placeholder sin chat y sin IA.
- `LibrerIAEngine` creado como esqueleto central.
- Estado inicial del engine en `preparing`.
- Provider de vista derivando desde el engine.

Limites cerrados del sprint:

- Sin OpenAI.
- Sin IA.
- Sin `ContextBuilder` real.
- Sin `ToolManager` real.
- Sin recomendaciones.
- Sin acciones.

Validacion final:

- `flutter analyze`: OK.
- `flutter test`: 198/198.

Gate vigente:

- No abrir Sprint 2 todavia.

Sprint 19.x implementado:

- Sprint 19.1 agrega motion premium calmado: confeti breve al completar libro, transiciones suaves, microinteracciones, skeletons y empty states animados.
- Sprint 19.2 transforma Estadisticas con visualizaciones editoriales: progress ring para reto lector, donut de estados, distribucion de generos, tiempo semanal y paginas por mes.
- Sprint 19.3 mejora first run y estados vacios con `ReadPpEmptyState` compartido en Biblioteca, Calendario/Diario, Estadisticas, Insights y Reto lector.
- Las visualizaciones de Sprint 19.2 usan `StatisticsSummary`, `Book` y `ReadingSession` existentes, sin nuevas tablas ni dependencias.
- Distribucion de formatos queda como estado preparado porque aun no existe metadata de formato en el modelo de libro.
- Validacion vigente Sprint 19.3: `dart format lib test`, `flutter analyze` OK y `flutter test` OK, 55/55 tests passed.

Estado historico tras Hito 5 Sprint 13, Branding Final, Sprint 14 Demo Polish y Sprint 15 Stats Premium Redesign: ReadPp v1.0 RC esta completo.

Actualizacion Sprint 17.x: perfil lector local, branding real, headers consistentes y Home visual polish estan implementados.

Estado actual: Release Candidate Ready; Publication Preparation In Progress.

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

Branding Final completo:

- Nombre publico oficial estandarizado como ReadPp.
- Branding Web actualizado.
- Branding iOS actualizado.
- Branding Android verificado.
- Splash basico Burgundy alineado con marca.
- Assets oficiales agregados y centralizados bajo `assets/branding`.
- Logo oficial integrado en assets del proyecto.
- Iconos placeholder de Flutter reemplazados.
- Iconos Android generados.
- Iconos iOS generados.
- Iconos Web/PWA generados.
- Documentacion interna de branding creada/actualizada.

Sprint 14 Demo Polish implementado:

- Correccion visual de Home: la barra del reto anual convierte `annualGoalProgress` de porcentaje `0-100` a progreso visual `0-1`.
- Nombre por defecto en headers unificado como `Lectora`.
- Simbolo de marca centralizado como `AppBrand.symbol = 'dP'`.
- Home reutiliza el mismo simbolo `dP` que Biblioteca, Progreso, Insights y Onboarding.
- Correcciones puntuales de copy/tildes aplicadas en textos visibles.
- No se introdujo perfil real, persistencia nueva, providers nuevos, arquitectura nueva ni logica de negocio.
- Validacion Sprint 14 pendiente: el usuario ejecuta `dart format`, `flutter analyze` y `flutter test` desde VS Code.

Hito 5 Sprint 15 completed:

- Statistics screen redesigned.
- Editorial header added.
- Hero metrics section added.
- `MetricCard` adopted.
- `SectionHeader` adopted.
- Annual goal redesigned.
- Duplicate metrics removed.
- Visual consistency aligned with Home, Progress and Insights.
- Sprint 15 mantuvo providers, repositorios y logica de calculo sin cambios.
- Validacion Sprint 15 pendiente: el usuario ejecuta `dart format`, `flutter analyze` y `flutter test` desde VS Code.

Sprint 16/17.x implementado:

- Ajustes incluye perfil lector local con nombre, saludo Lectora/Lector/Lectore/Personalizado, saludo personalizado y resumen visual.
- El perfil lector se guarda localmente con `SharedPreferences`, sin backend ni Supabase.
- El saludo dinamico se aplica en Home, Biblioteca, Progreso, Estadisticas, Insights y Ajustes cuando usan header.
- El saludo personalizado se usa como fallback si no hay nombre configurado.
- Home permite elegir el libro principal cuando hay varios libros en estado `Leyendo`; la seleccion se guarda localmente.
- Home usa fallback inicial por mayor progreso solo si no existe seleccion manual valida.
- El logo real de ReadPp se integra desde `img-logo/transparent-logo (1).png` mediante `AppBrandHeader`.
- `pubspec.yaml` registra `img-logo/` como carpeta de assets.
- Home alinea el header como fila de logo/perfil y saludo debajo, manteniendo el saludo sin truncar.
- Biblioteca y Progreso eliminan los titulos grandes `Tu Biblioteca` y `Tu Progreso`.
- Home usa gradiente de fondo alineado al lenguaje visual de Progreso/Biblioteca.
- Cards resumen y reto anual en Home tienen profundidad visual suave con bordes rosados y sombras burdeos ligeras.
- Calendario queda rotulado como `Book Journal` y usa fondo degradado rosa alineado con Home/Progreso/Biblioteca.
- Calendario muestra resumen con emoji arriba, numero y label debajo.
- Celdas de calendario y tarjetas semanales tienen bordes mas visibles para diferenciarse del fondo.
- Selector Mes/Semana se alinea visualmente con botones premium de ReadPp.
- Formulario de libro evita keys duplicadas en resultados Open Library cuando existen titulos repetidos.
- Onboarding usa logo real ReadPp y nuevas imagenes desde `assets/images/onboarding/`.
- Onboarding actualizado: ya no usa screenshots/phone mockups como contenido de slides; usa ilustraciones nativas flotantes sobre el fondo, con Cormorant en titulos y Roboto en descripciones.
- Calendario actualizado: `Book Journal` mantiene calendario arriba y mueve resumen de paginas/minutos/dias abajo; fondo suavizado y dias con borde visible.
- Botones: tema global de botones reforzado en `AppTheme`; se eliminaron overrides locales repetidos en formularios, detalle, onboarding, insights y biblioteca para heredar un estilo unico.
- Home Premium Polish toma referencia editorial premium: saludo grande, botones pill, hero compacto, resumen de hoy, lecturas en curso, mini calendario semanal y reto anual ilustrado.
- Home adopta composicion editorial propia para esta referencia visual; otras pantallas principales mantienen `AppBrandHeader`.
- Asset de reto anual: `assets/images/home/annual_goal_illustration.png`.
- Home convierte `Lecturas en curso` en carrusel horizontal con swipe, snap por libro, preview lateral y page indicators.
- Al hacer swipe en `Lecturas en curso`, el libro visible pasa a ser la lectura principal usando `readerProfileControllerProvider.updateCurrentReadingBookId`, la misma persistencia local existente.
- Pase de consistencia visual aplicado desde Home hacia Biblioteca, Progreso, Estadisticas, Insights y Ajustes: tipografia editorial selectiva, cards premium, bordes suaves, sombras editoriales, `MetricCard`, `SectionHeader` y `AppBrandHeader` alineados.
- No se modificaron providers de libros, repositorios, Supabase/backend ni navegacion inferior.

Identidad visual vigente:

- Tema principal: Burgundy.
- Tema secundario: Forest.
- Tipografia de marca/titulos principales: Space Grotesk.
- Tipografia UI/body: Roboto.
- Estilo: reading journal editorial premium.

La Home ya funciona como biblioteca personal moderna. Actualmente ofrece:

- Header editorial `READPP •` con `Tu biblioteca personal` y saludo contextual.
- Hero de lectura actual con portada protagonista para el libro en estado `Leyendo` mas reciente.
- Registro rapido de avance desde el hero de lectura actual.
- Metricas compactas de racha actual, completados del ano y paginas leidas.
- Objetivo lector anual en card independiente.
- La barra del objetivo anual normaliza correctamente porcentajes `0-100` a valores `0-1`.
- Actividad reciente compacta.
- FAB para anadir libro.
- Sugerencias de pendientes cuando no hay lecturas activas.
- Empty state de primer uso orientado a anadir el primer libro.

## Onboarding / First Run Experience

Estado actual implementado:

- Onboarding funcional de primera apertura.
- El flujo tiene 4 pantallas:
  - `Tu biblioteca personal`.
  - `Convierte la lectura en un habito`.
  - `Descubre tu perfil lector`.
  - Pantalla de cuenta/sincronizacion para explicar backup, continuidad entre dispositivos y modo local.
- Incluye acciones `Omitir`, `Siguiente` y `Empezar`.
- Incluye indicador visual de progreso.
- Usa logo real ReadPp en lugar del branding manual antiguo.
- Las ilustraciones se cargan desde assets: `assets/images/onboarding/slide_1.png`, `slide_2.png` y `slide_3.png`.
- El estado completado se persiste localmente con `SharedPreferences`.
- La flag usada es `onboarding_completed`.
- El onboarding se muestra solo si la flag no existe o esta en `false`.
- Al completar u omitir, la app entra en el flujo normal.
- Los usuarios recurrentes no ven onboarding automaticamente.
- El onboarding convive con Supabase Auth y sincronizacion: educa sobre cuenta/sync, pero no obliga a iniciar sesion.
- Usuarios existentes cuentan con flujo de migracion/aviso separado para activar sincronizacion sin repetir el onboarding completo.
- El estilo visual mantiene Burgundy/Forest y la estrategia tipografica Roboto + Space Grotesk.

## UX Home

Estado actual implementado:

- Home usa header con logo real ReadPp, acceso a Perfil y saludo dinamico del perfil lector.
- Home mantiene CTAs superiores `Libro` y `Calendario`.
- Home actual se ajusta a una referencia editorial premium: saludo protagonista en dos lineas, perfil a la derecha y botones superiores en pills blancos.
- Home incluye seccion `Resumen de hoy` con paginas leidas, tiempo de lectura y sesiones.
- Home incluye mini calendario semanal que abre el calendario completo.
- Home incluye `Lecturas en curso` cuando hay varios libros en estado `Leyendo`.
- `Lecturas en curso` se muestra como carrusel horizontal con `PageView`, swipe izquierda/derecha, snap nativo, preview de cards adyacentes e indicadores inferiores.
- La card visible del carrusel se guarda como lectura principal reutilizando el mecanismo local existente de perfil lector.
- El reto anual de Home usa la ilustracion editorial `assets/images/home/annual_goal_illustration.png`.
- Si existen varios libros en estado `Leyendo`, Home permite elegir cual aparece como principal.
- La seleccion de lectura principal se persiste localmente y no cambia sola mientras el libro siga en estado `Leyendo`.
- Si no hay seleccion manual valida, Home usa como fallback el libro en lectura con mayor progreso.
- El CTA para cambiar lectura usa el copy `Cambiar libro`.
- El fondo de Home usa un gradiente suave alineado con Progreso/Biblioteca.
- Las cards resumen y la card de reto anual tienen bordes rosados sutiles y sombras burdeos ligeras.
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
- La pantalla de calendario usa el titulo visible `Book Journal`.
- La pantalla de calendario usa fondo degradado suave y bordes reforzados en cada dia para mejorar legibilidad visual.
- El resumen de calendario usa formato emoji, numero y texto.
- El selector Mes/Semana mantiene la misma logica, con estilo visual premium.
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
- En alta de libros, los resultados de Open Library usan keys unicas aunque varias ediciones compartan titulo.
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
- El simbolo de marca se obtiene desde `AppBrand.symbol`.
- Cada card prioriza portada, titulo, autor y progreso opcional.
- Los libros en lectura muestran progreso si tienen `currentPage` y `totalPages`.
- Los libros completados muestran rating si estan valorados.
- Los empty states de Biblioteca son editoriales y no generan scroll excesivo.
- La bottom nav mantiene `Insights` como label y usa rosa/accent muted en iconos no seleccionados.

## Progreso

Estado actual implementado:

- `ProgressScreen` ya no es una lista simple de accesos.
- Progreso usa `AppBrandHeader` con logo real ReadPp y saludo dinamico del perfil lector.
- El titulo grande `Tu Progreso` fue retirado; se conserva el texto descriptivo de seguimiento.
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
- Sprint 14 Demo Polish esta implementado y pendiente de validacion local por el usuario.
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
- Hito 7 Sprint 19.4 - Design System Consolidation completado y validado.
- Estado actual de Design System: `ReadPpPageHeader`, `CurrentReadingCard`, `MetricCard`, `ReadPpEmptyState` y `ReadPpSurface` son componentes compartidos vigentes.
- Pantallas principales alineadas: Home, Biblioteca, Calendario, Progreso, Estadisticas, Insights y Settings usan titulos/datos destacados desde el tema oficial.
- Validacion vigente Sprint 19.4: `dart format lib test` OK, `flutter analyze` OK y `flutter test` OK con 55/55 tests.
- Hito 7 Sprint 19.5 - Reading Experience Polish implementado.
- Estado actual de lecturas activas: swipe de revision independiente de la seleccion principal, etiquetas explicitas y acceso a progreso desde lecturas secundarias.
- Estado actual de progreso: porcentaje, paginas actuales/totales y restantes visibles en `CurrentReadingCard`.
- Estado actual de historial: sesiones recientes ordenadas de forma estable, ultimo avance destacado y notas visibles con limite de lineas.
- Relecturas siguen fuera de alcance y sin cambios de modelo; arquitectura futura documentada en `architecture.md`.
- Validacion disponible Sprint 19.5: format, `dart analyze` y `git diff --check` OK; validacion Flutter pendiente por bloqueo del SDK local durante esta ejecucion.
- Hito 7 Sprint 19.6 - Insights Premium implementado.
- Insights actual: autor favorito con carrusel de portadas; mejores lecturas con portada, rating y review; curiosidades con libro largo/corto y ritmo medio.
- Validacion intermedia 19.6: format y `dart analyze` OK.
- Hito 7 Sprint 19.7 - Accessibility & Responsiveness implementado.
- Navbar visible y consistente en rutas principales; tabs con estado semantico seleccionado.
- Portadas, lectura actual, calendario y diario incorporan labels semanticos en interacciones clave.
- Responsive actual: alturas sensibles al text scale, metricas de Insights en Wrap y cards premium horizontales con ancho adaptable.
- Validacion final disponible: format, `dart analyze` y `git diff --check` OK; `flutter analyze/test` pendientes por bloqueo del SDK local.

## Estado vigente tras revision Sprint 19

- Fecha de revision: 2026-06-22.
- Sprint 19.1-19.7 permanece implementado en `master` y sincronizado con `origin/master`.
- `dart format` OK, `dart analyze` OK y `flutter analyze` OK.
- Suite actual: 54/55 tests; falla el test de semantica del carrusel de lecturas activas.
- ReadPp no debe considerarse release-ready mientras la suite este roja.
- Bloqueantes: semantica de `CurrentReadingCard` y revision del apilado de `MainNavigationScreen` en rutas internas.
- Riesgos no bloqueantes: subtitulo incorrecto en Paginas por mes, graficas sin resumen semantico y widgets legacy sin eliminar.
- Validacion visual final de Sprint 19.5-19.7 sigue pendiente en Android, Web/Desktop y TalkBack.
- Version declarada actual: `1.0.0+1`; `v0.2.0-alpha` es solo una propuesta hasta resolver estrategia de versionado.

## Estado historico de release hardening

- Los bloqueantes P1 detectados en la revision de Sprint 19 quedan corregidos en codigo.
- Suite restaurada a 55/55 y `flutter analyze` sin issues.
- Navegacion interna entre tabs reemplaza/limpia la shell en lugar de apilar otra navbar.
- Riesgos rapidos de Stats corregidos: unidad mensual coherente y resumen semantico para graficas.
- ReadPp quedo listo para QA manual de v0.2.0-alpha.
- Este estado queda superado por la release alpha completada y distribuida.

## Estado vigente v0.2.0-alpha

- ReadPp v0.2.0-alpha esta completada y distribuida para QA externo.
- APK Release generada.
- Web desplegada en Vercel.
- Web/PWA se despliega oficialmente con `flutter build web --release`, luego `cd build/web` y `vercel --prod` al proyecto `readpp-web-alpha`; verificar `https://readpp-web-alpha.vercel.app` y no desplegar desde la raiz del proyecto.
- Testers externos activos.
- QA manual previo a release completado.
- Validacion automatizada vigente: 67/67 tests.
- `flutter analyze` OK.
- La instalacion limpia ya no debe mostrar libros demo/base; los datos demo quedan fuera del modo normal.
- Empty states reales son parte del flujo esperado de usuario nuevo.
- Perfil lector incluye validacion y normalizacion basica de nombre/saludo personalizado.
- La busqueda Open Library mantiene `Reintentar` y alta manual como fallback cuando falla la conexion.
- Insights/Curiosidades usa portadas o placeholder editorial cuando una curiosidad se refiere a un libro concreto.
- Pendientes actuales: QA-018, QA-019, QA-020, QA-021 y QA-022.
- Observabilidad Sprint 20.1 esta completada: Sentry integrado, configurado por entorno, DSN via `dart-define`, captura global de errores, breadcrumbs para Open Library y captura de errores de busqueda.
- Validacion real de Sentry completada en Web Release: evento recibido correctamente con environment `alpha` y release `0.2.0-alpha`.
- Analytics Sprint 20.2 completado: PostHog por HTTP detras de `ReadPpAnalytics`, configuracion via `dart-define` y eventos de producto basicos recibidos correctamente.
- Build Web/PWA previa a Hito 7 preparada con Sentry y PostHog via `dart-define`, release `readpp@0.2.0-alpha` y secretos fuera de repo/Memory Bank.
- Roadmap vigente: Sprint 20.3 Funnel basico, v0.4 Google Books fallback robustecido, v0.5 Supabase.

## Observabilidad

Estado actual implementado:

- `ReadPpSentry` centraliza la integracion con Sentry.
- Sentry se habilita solo en release cuando existe `SENTRY_DSN`.
- `SENTRY_ENVIRONMENT` permite configurar el entorno; si no se define, se deriva de modo de ejecucion.
- `SENTRY_RELEASE` permite fijar la release reportada.
- Web Release validado con environment `alpha` y release `0.2.0-alpha`.
- La app captura errores globales mediante `SentryFlutter.init`.
- La navegacion agrega `SentryNavigatorObserver` cuando Sentry esta habilitado.
- Open Library agrega breadcrumbs de busqueda con proveedor, query, plataforma, release, duracion, resultados y tipo de fallo cuando aplica.
- Los errores de busqueda Open Library se capturan con `Sentry.captureException`, tags y contexto especifico.
- La infraestructura temporal de validacion manual fue retirada tras confirmar el evento real en Sentry.
- Ya no existen ruta oculta de validacion, `READPP_ENABLE_SENTRY_VALIDATION` ni `captureValidationException()`.
- Evento real recibido correctamente en Sentry durante la validacion Web Release.
- Validacion tras limpieza temporal: `flutter analyze` OK y `flutter test` OK con 67/67 tests.

## Analytics

Estado actual implementado:

- `ReadPpAnalytics` centraliza analytics de producto en `core/analytics`.
- PostHog se usa mediante HTTP directo, no SDK acoplado a widgets.
- Configuracion por `dart-define`: `ANALYTICS_ENABLED`, `POSTHOG_API_KEY`, `POSTHOG_HOST` y `APP_ENV`.
- Sin configuracion valida, la capa queda en no-op y la app funciona igual.
- Eventos implementados: onboarding completado, libro agregado, alta manual, libro completado, sesion creada, busqueda iniciada/completada/fallida/sin resultados y reto anual creado/actualizado.
- Privacidad aplicada: no se envian titulos, autores, notas, resenas, nombres de usuario ni queries exactas.
- Se envian solo buckets, booleanos, longitudes, contadores, plataforma, `app_env` y release si existe.
- Los eventos usan `distinct_id` anonimo local y `$process_person_profile=false`.
- Eventos reales validados en PostHog: `onboarding_completed`, `search_started`, `search_completed`, `search_no_results`, `book_added`, `book_completed` y `reading_session_created`.
- Visualizacion validada en PostHog: `Activity` y `Trends`; prueba de Trends con `book_added = 2` y `reading_session_created = 1`.
- Validacion local Sprint 20.2: `flutter analyze` OK y `flutter test` OK con 67/67 tests.

## Estado producto Observabilidad

- ReadPp dispone de APK Android.
- ReadPp dispone de Web App / PWA desplegada en Vercel.
- Open Library esta integrado como busqueda principal.
- Sentry cubre observabilidad de errores: que falla.
- PostHog cubre analytics de producto: que hacen los usuarios.
- Metricas disponibles: onboarding completados, libros anadidos, sesiones registradas, busquedas realizadas, busquedas sin resultados y libros completados.
- Validacion automatizada vigente: 67/67 tests.

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
- Sprint 15 redisenia visualmente `/stats` con header editorial, hero metrics, secciones `Lectura`, `Tiempo` y `Objetivo anual`.
- Stats ajuste posterior: `Objetivo anual` pasa a primera posicion en la pantalla y prioriza configuracion/accion antes de informacion secundaria.
- `/stats` reutiliza `MetricCard`, `SectionHeader`, `AppSpacing`, `AppIcons` y `Theme.colorScheme`.
- La card de objetivo anual en `/stats` queda alineada visualmente con Home, Progreso e Insights.
- La metrica duplicada `Lecturas activas` se elimina de la UI de Stats para evitar repetir `Leyendo`.
- Quedan preparados futuros bloques de sesiones avanzadas y graficas, sin implementarlos todavia.

## Siguiente paso recomendado

1. Preparar Beta publica.
2. Mantener la base validada de Hito 9: onboarding de 4 pantallas, Coach Mark de sincronizacion, migracion para usuarios existentes, Supabase Auth completo, Email, Google OAuth y sync multi-dispositivo.
3. Priorizar futuras funcionalidades inteligentes: AI Assistant, automatizaciones y mejoras de producto.
4. Mantener Drift como fuente de verdad local y Supabase como capa de cuenta/sincronizacion.
5. No introducir resolucion automatica de conflictos ni IA sobre datos personales sin sprint especifico de producto, privacidad y QA.

## Estado vigente Hito 7 - Backend con Supabase

- Hito 7 esta en fase de backend progresivo con filosofia Offline First / Local First.
- Drift sigue siendo la fuente de verdad durante el uso normal de la app.
- Supabase queda como backend progresivo para Auth, recuperacion futura y sincronizacion remota.
- La app sigue funcionando sin login y sin variables Supabase configuradas.
- La sincronizacion manual local -> Supabase y Supabase -> local ya existe para las entidades principales.
- Existe schema Supabase y RLS definidos en repositorio y la sincronizacion remota queda validada funcionalmente con Supabase real.
- Existe metadata local de sincronizacion en Drift y se marca desde mutaciones locales mediante `LocalSyncTracker`.

### Sprint 21.1 - Infraestructura Supabase

- Completado.
- Documentacion tecnica creada en `docs/architecture/sprint-21-1-supabase-infrastructure.md`.
- Definida ubicacion futura de configuracion e inicializacion en `core/backend`.
- Variables previstas: `SUPABASE_URL` y `SUPABASE_ANON_KEY`.
- Validacion: `flutter analyze` OK y `flutter test` OK con 67/67.

### Sprint 21.2 - Integracion base Supabase

- Completado.
- Dependencia agregada: `supabase_flutter: ^2.15.0`.
- Capa opcional creada en `reading_tracker/lib/core/backend`.
- Supabase se inicializa solo si existen `SUPABASE_URL` y `SUPABASE_ANON_KEY`.
- Sin variables configuradas, Supabase queda deshabilitado y la app arranca en modo local.
- Commit: `4ef9fbb feat: add optional supabase base integration`.

### Sprint 21.3 - Auth base sin sincronizacion

- Completado.
- `features/auth` creado con separacion `data`, `domain` y `presentation`.
- Modelo de dominio `AppUser` creado con `id`, `email`, `displayName` y `avatarUrl`.
- Contrato `AuthRepository` creado.
- Implementacion con Supabase Auth creada.
- `AuthController` con Riverpod expone usuario, loading, error y metodos de login/logout preparados.
- `AuthScreen` minima creada y aislada, sin integrarse todavia en navegacion principal.
- Si Supabase no esta configurado, Auth queda en estado no autenticado y solo muestra error controlado al intentar login.
- No se modifico Drift.
- No se modifico onboarding.
- No se modifico navegacion principal.
- Validacion: `flutter analyze` OK y `flutter test` OK con 67/67.
- Commit: `dfbe715 feat: add auth base without sync`.

### Sprint 21.4 - Cuenta/Auth en UI sin sincronizacion

- Completado.
- La pantalla de Perfil/Ajustes incluye una card visible `Cuenta`.
- La card de Cuenta muestra estado resumido: `Modo local` cuando no hay sesion y `Sesion iniciada` cuando existe usuario autenticado.
- Nueva pantalla `AccountScreen` integrada en la navegacion con ruta `/account`.
- Estado sin sesion: explica que biblioteca, progreso, sesiones, estadisticas y preferencias siguen almacenados solo en el dispositivo.
- Estado autenticado: muestra email disponible, estado de sesion iniciada y accion para cerrar sesion.
- Nueva pantalla informativa `AccountTransitionScreen` en `/account/transition` antes del formulario de login/registro.
- La pantalla informativa explica la transicion a cuenta y sincronizacion cloud; ofrece `Crear cuenta`, `Ya tengo una cuenta` y `Mas tarde`.
- `AuthScreen` queda integrada en `/account/auth` y puede abrirse en modo registro o inicio de sesion segun el flujo elegido.
- Drift, biblioteca, progreso, estadisticas, sesiones, onboarding y preferencias locales no cambian.
- No se implementa sincronizacion, migracion local-remota, subida/descarga de datos, resolucion de conflictos, tablas Supabase, RLS ni perfiles remotos.
- Validacion: `flutter analyze` OK y `flutter test` OK con 67/67.

### Sprint 21.5 - Preparacion de migracion local a cuenta

- Completado.
- Caso de uso `PrepareAccountMigration` creado para preparar la futura asociacion de datos locales a una cuenta autenticada.
- Entidad de resultado `AccountMigrationPreparation` creada con estado, `userId` y resumen local.
- Estados soportados: `unauthenticated`, `noLocalData` y `readyForFutureSync`.
- Resumen local preparado: numero de libros, numero de sesiones, existencia de objetivo anual y existencia de preferencias de perfil lector.
- `AccountMigrationController` creado como controlador separado; `AuthController` mantiene responsabilidad exclusiva sobre sesion/login/logout.
- Pantalla de Cuenta muestra un bloque informativo de `Preparacion local` cuando hay usuario autenticado.
- La preparacion usa repositorios existentes (`BookRepository`, `ReadingSessionRepository`, `AnnualReadingGoalRepository`) y valores locales ya cargados de perfil lector.
- El dominio no importa Supabase ni SDK remoto.
- No se escribe en Drift.
- No se llama a Supabase.
- No se implementan tablas remotas, RLS, subida, descarga, resolucion de conflictos ni sincronizacion automatica.
- Tests unitarios agregados para usuario no autenticado, usuario sin datos locales y usuario con datos listos para futura sync.
- ADR nuevo: `ADR-003 - Preparacion de migracion local a cuenta`.
- Validacion: `flutter analyze` OK y `flutter test` OK.

### Sprint 21.6 - Modelo remoto Supabase + RLS

- Completado en repositorio.
- Migracion SQL creada en `supabase/migrations/202606270001_remote_data_model.sql`.
- Tablas remotas definidas: `profiles`, `books`, `reading_sessions` y `annual_goals`.
- Todas las tablas incluyen `created_at`, `updated_at` y `deleted_at`.
- Las entidades sincronizables usan UUID remoto propio como `id`.
- Los identificadores locales se conservan como columnas separadas: `local_book_id`, `local_session_id`, `local_goal_id` cuando aplica.
- `profiles.id` coincide con `auth.users.id`.
- RLS habilitado en todas las tablas.
- Politicas SQL definidas para `SELECT`, `INSERT`, `UPDATE` y `DELETE`.
- Regla de propiedad: `auth.uid() = user_id`; en `profiles`, `auth.uid() = id`.
- Nueva feature `features/sync` creada con entidades remotas, DTOs, mappers, contratos de repositorios remotos y datasource remoto abstracto.
- No se implementa repositorio concreto de Supabase.
- No se realizan llamadas desde UI.
- No se modifica Drift ni su comportamiento.
- No se implementa sync local -> nube, nube -> local, merge, resolucion de conflictos ni background sync.
- ADR nuevo: `ADR-004 - Modelo remoto Supabase y RLS`.
- Documentacion tecnica creada en `docs/architecture/sprint-21-6-remote-model-rls.md`.
- Limitacion: la migracion SQL no fue aplicada ni validada contra un proyecto Supabase real desde esta ejecucion.
- Validacion: `flutter analyze` OK y `flutter test` OK.

### Sprint 21.7 - Persistencia local del estado de sincronizacion

- Completado.
- Drift sube a `schemaVersion = 6`.
- Nueva tabla local `sync_metadata` para asociar `entity_type + local_id` con futuro `remote_id`.
- La tabla registra `sync_status`, `pending_operation`, timestamps de sync/local/remoto, ultimo error y contador de reintentos.
- Nueva DAO `SyncMetadataDao` creada en `core/database`.
- La feature `features/sync` incorpora `SyncMetadata`, `SyncEntityType`, `SyncStatus` y `PendingSyncOperation`.
- Contrato `SyncMetadataRepository` e implementacion `LocalSyncMetadataRepository` creados para ocultar Drift.
- Provider Riverpod `syncMetadataRepositoryProvider` disponible para futuros use cases.
- Operaciones soportadas: guardar metadata, leer por entidad/local id, listar pendientes, asociar remoto, marcar synced, marcar pending upload/update/delete y registrar fallo.
- No hay llamadas a Supabase.
- No hay cambios de UI.
- No se modifica el comportamiento local de biblioteca, progreso, sesiones, estadisticas ni preferencias.
- ADR nuevo: `ADR-005 - Metadata local de sincronizacion`.
- Documentacion tecnica creada en `docs/architecture/sprint-21-7-local-sync-metadata.md`.
- Validacion: `dart format lib test` OK, `flutter analyze` OK y `flutter test` OK con 81/81 tests.
- Limitacion: las mutaciones locales todavia no crean ni actualizan metadata automaticamente.

### Sprint 21.8 - Aplicar migracion Supabase + validar RLS real

- Iniciado/preparado, no cerrado.
- La migracion SQL `supabase/migrations/202606270001_remote_data_model.sql` fue revisada.
- Ajuste aplicado: funcion y triggers `set_updated_at` para actualizar `updated_at` automaticamente en `profiles`, `books`, `reading_sessions` y `annual_goals`.
- Documentacion de validacion creada en `docs/architecture/sprint-21-8-supabase-rls-validation.md`.
- La guia incluye metodo de aplicacion por SQL Editor o Supabase CLI, verificacion de esquema, verificacion de RLS activo, verificacion de politicas y pruebas con dos usuarios reales.
- No se aplico la migracion desde esta ejecucion porque no hay `supabase` CLI, no hay `psql`, no hay proyecto CLI enlazado ni credenciales/conexion remota disponible.
- RLS no queda validado aun contra usuarios reales desde esta ejecucion.
- No se implemento sincronizacion, no se conecto la app con Supabase y no hubo cambios de UI.

### Sprint 21.9 - Conectar mutaciones locales con SyncMetadata

- Completado.
- Nueva capa coordinadora `LocalSyncTracker` creada en `features/sync/domain/services`.
- Provider `localSyncTrackerProvider` creado para inyeccion Riverpod.
- `BookRepositoryImpl` marca libros creados, actualizados y eliminados como pendientes de sync tras persistir en Drift.
- `ReadingSessionRepositoryImpl` marca sesiones creadas, actualizadas y eliminadas como pendientes de sync tras persistir en Drift.
- `SaveAnnualReadingGoal` marca el objetivo anual como `pendingUpload/create` cuando se crea y `pendingUpdate/update` cuando se actualiza.
- `ReaderProfileController` marca el perfil lector como `pendingUpdate/update` tras cambios de nombre, saludo, saludo personalizado o lectura principal.
- IDs locales estables para entidades singleton:
  - objetivo anual: `annualReadingGoal`;
  - perfil lector: `reader_profile`.
- No hay llamadas a Supabase.
- No hay cambios visibles en UI.
- Drift y `SharedPreferences` siguen siendo la fuente local usada por la app.
- Tests agregados en `test/local_sync_tracking_test.dart`.
- Validacion: `dart format lib test` OK, `flutter analyze` OK y `flutter test` OK con 88/88 tests.
- Limitacion: aun no existe worker/use case remoto que consuma `sync_metadata`.

### Sprint 22.0 - Primera sincronizacion manual Books local -> Supabase

- Completado.
- Primera sincronizacion manual local -> Supabase limitada a Books.
- El flujo consume `sync_metadata`, filtra `entity_type = book` y procesa operaciones pendientes `create`, `update` y `delete`.
- `create` y `update` cargan el libro local mediante `BookDao.getBookById`, construyen el modelo remoto parcial de Books y lo suben a Supabase.
- Tras una subida correcta, el flujo conserva/guarda `remoteId` en `sync_metadata` y marca la metadata como `synced`.
- `delete` con `remoteId` llama al borrado remoto y marca synced; `delete` sin `remoteId` se marca synced sin llamada remota porque no hay registro remoto que borrar.
- No hay sync automatica.
- No hay recuperacion nube -> local.
- No se sincronizan todavia Reading Sessions, perfil lector ni objetivo anual.
- La UI queda intacta; el caso de uso queda preparado para ejecucion manual.
- Validacion: `dart format` OK, `flutter analyze` OK y `flutter test` OK con 94/94 tests.
- Decision tecnica: en Supabase Books, el upsert remoto usa `id` como conflict target porque el indice `user_id + local_book_id` del schema es parcial con `WHERE deleted_at IS NULL`. `local_book_id` sigue viajando en la fila como identidad local, pero no se usa como conflict target directo en este sprint.
- Impacto futuro: esta decision afecta el diseno de proximos sprints de reconciliacion por `local_book_id`, borrado logico y sync nube -> local.

### ADR vigentes Hito 7

- `ADR-001-local-first.md`: Drift como fuente de verdad local y Supabase como backend progresivo.
- `ADR-002-authentication-strategy.md`: Supabase Auth con Google OAuth y email/contrasena para Auth v1.
- `ADR-003-account-migration-preparation.md`: preparacion de migracion mediante caso de uso dedicado sin sync remota ni Supabase en dominio.
- `ADR-004-remote-data-model-and-rls.md`: modelo remoto con UUID propio, IDs locales separados, auditoria obligatoria y RLS por usuario.
- `ADR-005-local-sync-metadata.md`: estado local de sincronizacion en Drift mediante tabla dedicada, enums de dominio y repositorio desacoplado.

### Riesgos abiertos Hito 7

- Google OAuth requiere mantener configuracion externa correcta en Supabase y plataformas objetivo.
- Email/contrasena queda validado con configuracion real de Supabase Auth.
- La sincronizacion debe asociar datos locales a `user.id` sin perdida de datos.
- Las futuras capas remotas no deben leer directamente desde Supabase como fuente principal de UI.
- Google OAuth y email/contrasena quedan validados con proyecto Supabase configurado.
- La UI y el caso de uso de Cuenta preparan la asociacion, el schema remoto esta definido en repositorio y existe metadata local de sync.
- La metadata local ya se marca automaticamente en altas, ediciones y borrados principales de libros/sesiones y en cambios de objetivo anual/perfil.
- La transferencia manual local -> Supabase, la descarga manual Supabase -> local, la sincronizacion automatica y la UI de estado ya cubren Books, Reading Sessions, Reader Profile y Annual Goal; queda pendiente la resolucion real de conflictos.
- Sprint 21.8 esta bloqueado hasta ejecutar la migracion y las pruebas RLS en Supabase real.

### Decision de cierre

- Sprint 21.7 queda cerrado sin sync remota.
- Sprint 21.8 queda preparado pero no cerrado desde Codex: falta aplicacion/validacion real en Supabase si no se ejecuto externamente.
- Sprint 21.9 queda cerrado sin sync remota.
- Sprint 22.0 queda cerrado con primera sync manual Books local -> Supabase.
- Sprint 22.1 queda cerrado con `SyncOrchestrator`.
- Sprint 22.2 queda cerrado con sync manual Reading Sessions local -> Supabase.
- Sprint 22.3 queda cerrado con sync manual Reader Profile local -> Supabase.
- Sprint 22.4 queda cerrado con sync manual Annual Goal local -> Supabase.
- Sprint 22.5 queda cerrado con descarga manual Supabase -> local conservadora.
- Sprint 22.6 queda cerrado con deteccion de conflictos durante descarga.
- Sprint 22.7 queda cerrado con sincronizacion automatica.
- Sprint 22.8 queda cerrado con estado de sincronizacion en UI.
- Hito 8 queda cerrado completamente.
- Hito 9 queda cerrado completamente con UX-003, UX-004, onboarding de 4 pantallas, Coach Mark de sincronizacion, migracion de usuarios existentes, Supabase Auth completo, Email, Google OAuth, sync multi-dispositivo validada, QA Android/Web, `flutter analyze` sin issues y `flutter test` 178/178.
- La siguiente fase es Beta publica y futuras funcionalidades inteligentes.

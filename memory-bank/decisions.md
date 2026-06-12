# Decisions

## Decisiones tecnicas

- Usar Flutter/Dart para una app mobile-first con posible ejecucion web.
- Usar Riverpod para estado e inyeccion de dependencias.
- Usar Drift + SQLite para persistencia real.
- Usar `WebDatabase` sobre IndexedDB en web por simplicidad inicial.
- Mantener dominio libre de Drift.
- Ubicar conversiones Drift en `data/mappers`.
- Mantener consultas SQL simples y combinar datos en providers/UI cuando el coste sea bajo.
- Usar seed data solo en debug y solo si la base esta vacia.

## Decisiones de producto

- Priorizar registro de libros, sesiones, calendario y estadisticas basicas.
- No implementar backend, login ni JWT por ahora.
- Mantener UX mobile-first.
- Evitar complejidad prematura.
- Las secciones principales deben estar accesibles desde navegacion principal, no escondidas en acciones secundarias.

## Decisiones de trabajo con IA

- Leer contexto antes de editar.
- Explicar archivos tocados y validaciones.
- No hacer refactors amplios salvo peticion explicita.
- Tratar `Stats` como area separada: no tocarla en tareas de calendario/sesiones salvo que se pida.
- El usuario ejecuta `dart format`, `flutter analyze` y `flutter test` en su terminal de VS Code salvo peticion explicita en contrario.
- No hacer commit ni push automaticamente.
- No revisar `git status` ni `git diff` salvo que el usuario lo pida explicitamente.
- No confiar solo en resumen conversacional; verificar archivos modificados.
- Mantener cambios pequenos y acotados por problema.
- No tocar Open Library, modelos ni persistencia salvo que el requisito lo pida claramente.
- La base nueva de Estadisticas MVP se calcula principalmente desde `Book`; las rachas se calculan desde `ReadingSession` sin crear tablas ni entidades nuevas.
- La logica de calculo de estadisticas debe vivir fuera de widgets y pantallas.
- La UI futura debe consumir estadisticas desde un punto unico: `statisticsSummaryProvider`.
- La pantalla `/stats` debe permanecer simple en MVP: tarjetas basicas, sin charts, badges, notificaciones ni gamificacion avanzada.
- Las mutaciones de libros deben invalidar `statisticsSummaryProvider` ademas de cualquier provider legacy de Stats mientras convivan ambas rutas.
- El objetivo anual se persiste en una tabla simple `app_settings` gestionada por Drift con SQL manual, sin paquetes externos.
- El progreso anual usa solo libros `completed` con `finishedAt/completedDate` dentro del ano actual.
- Al entrar en estado `completed`, la app debe ofrecer valoracion y resena opcional; la resena se guarda en `Book.notes`.
- Las fechas de lectura deben mantener un rango valido: `startedAt` y `finishedAt` no pueden estar en el futuro, y `finishedAt` no puede ser anterior a `startedAt`.
- La busqueda Open Library en alta debe mostrar pocos resultados inicialmente y permitir cargar mas para no empujar demasiado el CTA de guardado.
- Hito 3 debe reutilizar la entidad existente `ReadingSession` como base de "ratos de lectura"; no crear una entidad paralela mientras esta cubra el concepto principal.
- Antes de usar sesiones para estadisticas avanzadas, rachas y actividad, consolidar campos estructurados minimos como `pagesRead` y `updatedAt`.
- Registrar sesiones nuevas debe pasar por `RegisterReadingSession`, que centraliza crear la sesion y actualizar el progreso del libro.
- Las sesiones de lectura pueden registrarse en fechas pasadas o en la fecha actual, pero no en fechas futuras.
- La intensidad del calendario se calcula desde `ReadingSession.pagesRead`; si no hay paginas pero si minutos, cuenta como actividad baja.
- Al registrar una sesion que haga llegar el progreso a `totalPages`, no completar automaticamente el libro sin confirmacion; si el usuario confirma, marcar como `completed`, fijar `finishedAt/completedDate` si estaba vacio y ofrecer valoracion/resena opcional.
- Las rachas se basan en dias con al menos una `ReadingSession`; hoy mantiene racha activa, ayer tambien si hoy aun no tiene sesion, y cualquier otro ultimo dia activo da racha actual 0.
- La mejor racha historica se calcula con la secuencia maxima de dias consecutivos con sesiones, ignorando hora y duplicados del mismo dia.
- Las metricas avanzadas de lectura agrupan `ReadingSession` por fecha sin hora, ignoran fechas futuras y calculan semana actual de lunes a domingo y mes actual desde el dia 1 hasta hoy.
- El dia mas activo se elige por mayor numero de paginas leidas y usa minutos como desempate.
- Hito 5 Sprint 1 usa `NavigationBar` Material 3 como shell principal con Inicio, Biblioteca, Progreso, Insights y Ajustes.
- `Progreso` es un hub de acceso a estadisticas, Reading Challenge y activity tracking; no duplica ni reemplaza la logica existente.
- `Ajustes` incluye preferencias visuales locales; perfil real, login y sincronizacion siguen fuera de alcance.
- La navegacion principal debe vivir solo en la `NavigationBar`; evitar duplicar esos accesos en AppBars o CTAs de Home.

## Design System Hito 5 Sprint 2

- El tema principal por defecto es Burgundy.
- Forest queda disponible como segundo tema seleccionable.
- La preferencia de tema se persiste con `shared_preferences`, no con Drift, para no tocar tablas ni repositorios.
- Los componentes base del Design System viven en `core/design_system` y no reemplazan todavia las pantallas existentes.
- Los tokens visuales viven en `core/theme/app_theme_tokens.dart`.
- El sprint no redisenia pantallas completas; solo prepara la base reutilizable.

## Branding & Visual Identity Hito 5 Sprint 2.5

- La marca de producto se centraliza como ReadPp.
- El wordmark textual usa `READPP` con punto final como fallback hasta tener logo definitivo.
- Los assets de branding viven en `assets/branding` y se declaran en `pubspec.yaml`.
- La tipografia objetivo es Playfair Display para titulos e Inter para contenido.
- Las fuentes definitivas no se descargan desde Codex; se deja `assets/fonts` preparado y el tema referencia las familias por contrato.
- La iconografia se abstrae con `AppIcons`; por ahora usa Material Icons redondeados para no anadir dependencias, y queda preparada para Lucide.
- Motion se define como tokens reutilizables, no como animaciones ad hoc en pantallas.
- Burgundy y Forest se mantienen como paletas oficiales; no se introduce un tercer tema.

## Home Premium Redesign Hito 5 Sprint 3

- El redisenio visual se limita a Home; Biblioteca, Estadisticas, Insights y Detalle Libro quedan sin redisenar.
- Home debe sentirse como biblioteca personal moderna, no como dashboard administrativo.
- La lectura actual es el bloque principal con portada protagonista y CTA para continuar o registrar avance.
- Anadir libro se mueve a un FAB para quitar el bloque grande del flujo principal.
- El objetivo anual se muestra como card independiente reutilizando `StatisticsSummary`; la edicion sigue viviendo en Estadisticas.
- La actividad reciente muestra maximo 3 sesiones y enlaza a calendario con `Ver actividad`.

## Premium Redesign Hito 5 Sprints 4-8

- Los redisenios visuales deben tocar solo la pantalla indicada por sprint, salvo navegacion principal cuando el requisito pida label/icon color.
- No tocar Drift, repositorios, modelos ni logica de negocio durante sprints de refinamiento visual.
- Mantener datos reales existentes: `Book`, `ReadingSession`, `StatisticsSummary`, `booksProvider`, `statisticsSummaryProvider` y providers de sesiones.
- La marca `dP + ReadPp` en headers editoriales debe ser pulsable y navegar a Home (`/`).
- Bottom navigation debe mantener `Insights` como label y usar un color muted/accent para iconos no seleccionados.
- Biblioteca debe sentirse como coleccion privada: portadas primero, metadata secundaria reducida, filtros compactos, empty states editoriales.
- Book Detail debe sentirse como ficha editorial premium: portada protagonista, progreso claro, informacion editorial en pills, sesiones como timeline.
- Acciones sin funcionalidad real no deben parecer activas; marcarlas como `Proximamente`, secundarias o desactivadas.
- Acciones destructivas como eliminar libro deben quedar accesibles pero visualmente secundarias.
- Progreso debe funcionar como dashboard editorial premium, no como menu de accesos.
- Progreso reutiliza `statisticsSummaryProvider` para racha, objetivo anual, paginas y completados; no crea nuevos calculos de dominio.
- La actividad reciente en Progreso puede consumir `readingSessionsForRangeProvider` para mostrar sesiones reales, sin inventar datos.
- El CTA de reto lector puede llevar a `/stats`, donde ya vive la edicion/configuracion del objetivo anual.
- El usuario prefiere ejecutar validaciones localmente; no correr `dart format`, `flutter analyze` ni `flutter test` si el pedido lo prohibe.
- La tipografia fue iterada por peticiones de usuario; antes de cerrar Hito 5 conviene revisar la decision final de fuentes y actualizar `AppTypography`/Memory Bank si cambia.

## UX Review Hito 5 Sprints 9-11B

- Separacion conceptual aprobada: Home = resumen general; Biblioteca = coleccion de libros; Progress = seguimiento; Stats = metricas; Insights = descubrimientos/curiosidades; Perfil = usuario, ajustes y preferencias.
- Biblioteca debe mantener foco exclusivo en libros: buscar, filtrar, consultar y anadir. Puede mostrar total textual de libros, pero no cards superiores de paginas, sesiones, rachas, objetivos o metricas globales.
- Biblioteca conserva acceso rapido para anadir libros desde el header (`+ / Anadir`) y desde FAB.
- Home puede tener accion superior para anadir/buscar libro; no debe duplicar acceso superior a Perfil porque Perfil ya vive en bottom nav.
- Add Book debe sentirse parte del producto premium: hero, buscador Open Library protagonista, resultados visuales, seleccion clara, formulario agrupado y CTA principal.
- Insights debe sentirse como pantalla principal premium, no secundaria: header de marca, hero, insight principal, metricas destacadas, secciones y cards editoriales.
- Perfil debe tratarse como ajustes/preferencias, no dashboard: mantener selector de tema y seccion `Proximamente`; no mostrar metricas lectoras, reto lector ni estadisticas globales.
- Pantallas principales con contenido scrolleable deben reservar padding inferior suficiente para que bottom navigation no oculte cards o CTAs.
- Tipografia actual indicada por el usuario: Roboto global.

## Onboarding Hito 5 Sprint 12

- Onboarding se muestra solo en primera apertura.
- El estado completado se persiste localmente con `SharedPreferences`.
- La flag de persistencia es `onboarding_completed`.
- Completar u omitir onboarding marca la experiencia como completada.
- Usuarios recurrentes no ven onboarding automaticamente.
- Tras onboarding, el usuario entra al flujo normal de la aplicacion.
- El onboarding no introduce autenticacion, backend, sincronizacion ni nuevas arquitecturas.
- Los empty states de primer uso deben guiar hacia anadir el primer libro cuando la pantalla aun no tiene datos.
- Mantener Burgundy y Forest en onboarding.
- Mantener estrategia tipografica actual: Roboto para UI/body y Space Grotesk para titulos principales/display.
- ReadPp queda feature-complete para v1 tras Sprint 12; el siguiente foco es Sprint 13 - Release Candidate & Store Readiness.

## Release Candidate Hito 5 Sprint 13

- ReadPp v1.0 RC queda completo tras Sprint 13.
- Estado actual: Ready for Store Preparation.
- Sprint 13 no introduce nuevas funcionalidades de producto.
- No se introduce backend, login, registro ni sincronizacion.
- No se modifican arquitectura ni modelos de datos.
- La validacion vigente es `flutter analyze` OK y `flutter test` OK.
- El trabajo de cierre incluye auditoria visual, navegacion, tipografia, accesibilidad basica, store readiness, limpieza de codigo y estabilizacion.
- La publicacion requiere pasos externos de tienda: assets finales, firma release, AAB firmado, politica de privacidad publicada y ficha Play Store completa.

## Branding Final y Publication Preparation

- Nombre publico oficial del producto: ReadPp.
- Tema principal oficial: Burgundy.
- Tema secundario oficial: Forest.
- Tipografia de marca y titulos principales: Space Grotesk.
- Tipografia de UI, body, labels, botones y metricas: Roboto.
- Los assets oficiales de marca se centralizan bajo `reading_tracker/assets/branding`.
- El logo oficial queda integrado como asset del proyecto.
- Los iconos de app reemplazan los placeholders de Flutter en Android, iOS y Web/PWA.
- El splash basico Burgundy queda aceptado como base de marca para Release Candidate.
- La preparacion de publicacion queda separada del desarrollo funcional: no introducir backend, login, registro, sync ni features nuevas para v1.
- Antes de publicar quedan tareas externas: final splash branding pass, Android adaptive icon review, verificacion real de icono, screenshots, store listing copy, privacy policy publica, firma release, AAB firmado y Play Store submission.
- Estado del proyecto tras Branding Final: ReadPp v1.0 Release Candidate Ready; Publication Preparation In Progress.

## Demo Polish Sprint 14

- Sprint 14 debe mantenerse como pulido de demo/publicacion, no como redisenio ni refactor.
- Antes de modificar se debe verificar que cada problema exista en codigo.
- `annualGoalProgress` se trata como porcentaje `0-100`; cualquier indicador visual que espere `0-1` debe recibir el valor normalizado.
- El nombre por defecto visible en headers es `Lectora`; no implementar perfil, usuario real ni persistencia hasta que se pida.
- El simbolo de marca visible en headers principales se centraliza en `AppBrand.symbol` y actualmente es `dP`.
- Home debe usar el mismo simbolo de marca que Biblioteca, Progreso, Insights y Onboarding.
- Las correcciones de copy deben ser puntuales y verificadas; no hacer reescrituras masivas de contenido.
- En pulidos de demo no tocar providers, Drift, repositorios, modelos ni logica de negocio.

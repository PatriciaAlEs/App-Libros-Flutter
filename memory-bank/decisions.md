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

## Stats Premium Redesign Sprint 15

- Hito 5 Sprint 15 completed.
- Statistics screen redesigned for visual consistency with Home, Progress and Insights.
- Stats debe usar header editorial en lugar de AppBar generica.
- Stats puede reorganizar metricas en secciones visuales sin modificar providers, repositorios ni calculos.
- `MetricCard` y `SectionHeader` son los componentes preferidos para Stats.
- La card de objetivo anual puede redisenarse visualmente, manteniendo `saveAnnualReadingGoalProvider` y `statisticsSummaryProvider`.
- Eliminar metricas duplicadas cuando muestren exactamente el mismo dato o concepto visible; en Sprint 15 se resolvio `Leyendo` / `Lecturas activas`.
- Sprint 15 no introduce nuevas funcionalidades ni cambios de arquitectura.

## Reader Profile, Branding y Header Consistency Sprint 16/17.x

- El perfil lector es local y se persiste con `SharedPreferences`; no usar backend, Supabase ni repositorios remotos para esta fase.
- El perfil lector guarda nombre, saludo elegido, saludo personalizado y libro principal de lectura actual.
- El saludo dinamico debe salir de `readerProfileControllerProvider` y reutilizarse en todos los headers principales.
- Si hay nombre configurado, el saludo usa momento del dia: `Buenos dias`, `Buenas tardes` o `Buenas noches`.
- Si no hay nombre, el saludo usa fallback Lectora/Lector/Lectore o el saludo personalizado.
- La seleccion de libro principal en Home se guarda localmente y no debe cambiar sola mientras el libro siga en estado `Leyendo`.
- Si no hay seleccion manual valida, Home puede usar como fallback el libro en lectura con mayor progreso.
- `AppBrandHeader` es el componente unico para logo real ReadPp + saludo dinamico en pantallas principales.
- El logo real preferido para headers es `img-logo/transparent-logo (1).png`; no anadir `flutter_svg` mientras el PNG sea suficiente.
- Home puede mantener composicion propia para ubicar Perfil y CTAs, pero debe reutilizar `AppBrandHeader` para el logo y alinear saludo/logo sin truncar.
- Biblioteca, Progreso, Estadisticas, Insights y Ajustes deben usar `AppBrandHeader(readerProfile: ...)` sin hardcodear `Hola, Lectora`.
- Los titulos grandes redundantes de Biblioteca/Progreso pueden retirarse cuando el header de marca y el texto contextual ya aportan jerarquia suficiente.
- Los cambios de Sprint 17.x son visuales/locales: no tocar providers de libros, repositorios, Supabase/backend ni navegacion inferior.
- El usuario sigue ejecutando `dart format .`, `flutter pub get`, `flutter analyze`, `flutter test` y `git status` manualmente cuando corresponda.

## Calendar y Search Polish Sprint 17.x

- El calendario puede usar el titulo visible `Book Journal` aunque el resto de la app mantenga copy en espanol, por decision visual del usuario.
- El calendario debe compartir el lenguaje de fondo degradado rosa con Home, Progreso y Biblioteca.
- Las celdas del calendario necesitan borde visible para diferenciarse del fondo; evitar superficies sin contraste suficiente.
- El resumen del calendario usa jerarquia compacta: emoji arriba, numero, label debajo.
- El selector Mes/Semana conserva la logica existente y solo cambia estilo visual.
- Los resultados de busqueda Open Library no deben usar solo el titulo como `Key`; Open Library puede devolver varias ediciones con el mismo titulo.
- Las keys de resultados deben ser estables y unicas entre widgets hermanos, combinando indice visible y metadatos del resultado sin modificar la seleccion ni la busqueda.

## Onboarding Refresh Sprint 17.6

- Onboarding conserva `PageView`, indicadores, `Omitir`, `Siguiente`, `Empezar` y la flag `onboarding_completed`.
- Usar PNGs desde `assets/images/onboarding/` para las ilustraciones, evitando dependencias nuevas.
- El logo real de ReadPp reemplaza el branding manual antiguo en onboarding.
- No tocar `onboarding_controller`, persistencia ni navegacion para refrescos visuales del first run.
- Los assets de onboarding deben mantenerse con nombres sin espacios: `slide_1.png`, `slide_2.png` y `slide_3.png`.

## Home Premium Polish Sprint 17.7

- Home puede adoptar una composicion editorial propia si una referencia visual aprobada lo pide, manteniendo providers, repositorios y navegacion intactos.
- La direccion visual aprobada para Home es Burgundy/soft pink, lectura editorial premium, botones pill, cards compactas y sombras suaves.
- El saludo puede tener mas protagonismo que el logo en Home cuando la referencia priorice bienvenida editorial.
- Resumenes, calendario semanal y lecturas en curso pueden calcularse en presentation desde datos ya cargados, sin crear providers ni modificar logica de negocio.
- El reto anual de Home usa el asset `assets/images/home/annual_goal_illustration.png` como soporte visual decorativo.
- El hero de lectura actual debe mantener portada, progreso, paginas, tiempo y accion de cambio sin eliminar informacion funcional.

## Alpha QA y Visual Source of Truth Hito 6 Sprint 18.x

- ReadPp entra en fase Alpha Testing & Polish; el orden de prioridad es bugs funcionales, inconsistencias UX, polish visual, interacciones premium y preparacion Beta.
- Biblioteca pasa a ser la fuente de verdad visual de la aplicacion. Cuando Home difiere de Biblioteca, Home debe adaptarse a Biblioteca.
- El header superior se centraliza en un componente compartido (`ReadPpPageHeader` / header de pantalla) con logo, perfil opcional, titulo/saludo, subtitulo opcional, acciones principales, SafeArea, padding y fondo coherentes.
- La tarjeta de lectura actual se centraliza como componente compartido (`CurrentReadingCard` / card destacada) con card burgundy editorial, portada a la izquierda, badge `LECTURA ACTUAL`, indicador `1 / N`, accion discreta de cambio, titulo grande, autor, progreso y card completa clicable.
- La card de lectura actual no debe incluir CTA interno `Ver lectura`; la card completa es la accion de navegacion.
- El carrusel de lecturas activas en Home es para revisar rapidamente otras lecturas en curso, no para elegir implicitamente la lectura principal.
- La accion para cambiar lectura principal debe existir separada conceptualmente del swipe y persistir en `reader_profile_current_reading_id`.
- Las pantallas principales deben mantener la navbar inferior visible, incluida la pantalla de reto lector.
- No anadir nuevas funcionalidades durante polish si el sprint pide solo correccion de comportamiento o sincronizacion.

## Design Decisions - Do Not Regress

- Visual source of truth: Biblioteca es la referencia visual principal.
- Current Reading Card: toda la card es clicable.
- Current Reading Card: no debe volver el boton interno `Ver lectura`.
- Typography: Space Grotesk se usa para titulos.
- Typography: Roboto se usa para cuerpo, textos pequenos, labels y UI.
- Reading Challenge: el CTA debe ser `Buscar libro` o `Cambiar libro`, nunca `Buscar portada`.
- Calendar: los dias son clicables.
- Calendar: no mostrar CTA textual `Abrir calendario`.

## Calendar, Diario y Reading Challenge Hito 6 Sprint 18.x

- En Calendario, seleccionar un dia debe mostrar las sesiones de ese dia y crear/editar una sesion debe refrescar Calendario y Diario sin reiniciar la app.
- Las celdas del calendario deben tener fondo blanco; la intensidad se comunica con bordes, sombras suaves o acentos del tema Burgundy/Forest, no coloreando agresivamente toda la celda.
- El calendario muestra hasta 3 portadas pequenas por dia y `+N` si hay mas libros; se eliminan textos internos tipo `75 pag` o `35 min`.
- El CTA textual `Abrir calendario` es redundante y debe eliminarse porque los dias ya son interactivos.
- El titulo visible del diario pasa a `Diario de lectura`, fuera de la card principal y con la tipografia oficial de titulos.
- La card principal del dia muestra la sesion/libro seleccionado y es la unica que navega al detalle; las cards pequenas de sesiones actualizan la seleccion y mantienen editar/borrar.
- El reto lector usa copy `Buscar libro` / `Cambiar libro`, no `Buscar portada`.
- Si existe al menos un libro completado, el reto lector puede usar automaticamente la portada del ultimo completado como imagen principal, manteniendo override manual.
- El selector del reto busca entre libros del usuario para elegir portada, no abre directamente una busqueda remota como flujo principal.

## Book Search, Deduplicacion y Fallbacks Hito 6 Sprint 18.15-18.17

- `BookSearchRepository` es el punto unico de entrada para busqueda de libros; las pantallas de alta no deben acoplarse a Open Library ni a un proveedor concreto.
- Open Library se mantiene como proveedor primario y Google Books se incorpora como proveedor secundario de fallback.
- Si Open Library devuelve resultados, se usan esos resultados y no se consulta Google Books.
- Si Open Library responde sin resultados, hace timeout o falla, se activa Google Books.
- Si Google Books tambien falla o no encuentra resultados, el flujo pasa a alta manual.
- Los mensajes de usuario distinguen sin conexion, timeout, API no disponible, respuesta invalida y sin resultados; los nombres de proveedor quedan ocultos para usuario final salvo debug.
- Los logs debug deben registrar proveedor usado, numero de resultados, fallback activado y motivo del fallback.
- `BookDuplicateMatcher` centraliza la deduplicacion y debe reutilizarse en alta por API, alta manual y futuros enriquecimientos.
- Criterios de deduplicacion: ISBN normalizado, `externalSource + externalId`, y fallback por titulo+autor normalizados.
- La normalizacion compara lowercase, trim, espacios duplicados eliminados, diacriticos ignorados, puntuacion basica ignorada y autor principal cuando exista.
- Drift persiste `externalSource` y `externalId` en libros para detectar duplicados entre proveedores y preparar enriquecimiento futuro.
- Un intento de duplicado no crea libro y muestra `Este libro ya esta en tu biblioteca.` con acciones `Ver libro`, `Cambiar estado` y `Cancelar`.
- El alta manual es ultima opcion de fallback, no el flujo principal. El escaneo ISBN es una ayuda opcional, no un bloqueo.
- Una portada local se guarda solo en el dispositivo como referencia/ruta local y no se sube a backend.
- Si un libro manual aparece mas tarde via API, el flujo futuro debe enriquecer el libro existente sin perder estado, progreso, sesiones, rating ni review.

## Roadmap Backend y Local-first

- ReadPp sigue local-first con Drift/SQLite durante Alpha.
- Proximo paso tecnico mayor post-Alpha: Supabase para Auth, backend cloud y sincronizacion multi-dispositivo.
- La sincronizacion futura debe recuperar biblioteca, sesiones, progreso, estadisticas y perfil lector en otro dispositivo.
- La persistencia local debe mantenerse para que la app no dependa siempre de internet.

## Motion & Delight Hito 7 Sprint 19.1

- Las animaciones de ReadPp deben sentirse calmadas, elegantes, editoriales y modernas.
- Evitar animaciones excesivas, rebotes constantes, efectos arcade o gamificacion agresiva.
- El momento principal de celebracion es completar un libro desde `reading` a `completed`.
- El confeti de completado debe ser breve, no bloqueante y dispararse una sola vez por evento real de finalizacion.
- Cambiar entre lecturas activas usa fade + slide horizontal ligero sobre `CurrentReadingCard`.
- Navegacion entre pantallas principales usa fade/fade-through corto, sin animaciones teatrales.
- Abrir libro desde Home, Biblioteca o Calendario usa transicion suave hacia Book Detail; no usar Hero de portadas todavia.
- Los botones principales conservan ripple Material y microinteraccion de escala/feedback tactil cuando usan componentes custom.
- Empty states pueden tener entrada suave; no introducir ilustraciones complejas todavia.
- Busqueda de libros debe mostrar skeletons/placeholders en vez de pantallas vacias o spinners principales.

## Premium Statistics Hito 7 Sprint 19.2

- Las estadisticas deben leerse como visualizaciones editoriales, no como dashboard corporativo.
- `StatsScreen` puede calcular visualizaciones de presentacion desde `StatisticsSummary`, libros y sesiones existentes sin crear tablas nuevas.
- El reto lector debe mostrar un progress ring ademas del copy de progreso.
- El donut de biblioteca muestra solo las categorias pedidas para claridad: pendientes, leyendo, completados y abandonados.
- La distribucion de generos usa `Book.genre` cuando existe y agrupa categorias sobrantes como `Otros`.
- Tiempo de lectura reciente se visualiza como barras semanales de minutos.
- Paginas leidas por mes se visualizan como barras mensuales.
- La distribucion de formatos queda preparada como estado informativo porque el modelo `Book` todavia no guarda metadata de formato.
- Colores de graficos deben derivar de Burgundy/Forest/acento y neutros del tema ReadPp.

## Empty States & First Run Hito 7 Sprint 19.3

- `ReadPpEmptyState` queda como componente compartido para estados vacios editoriales con icono/asset opcional, titulo, descripcion y CTA opcional.
- Los estados vacios deben guiar la siguiente accion sin usar mensajes genericos tipo `No data`.
- Reto lector sin configurar debe mostrar CTA `Configurar reto` y no metricas confusas.
- Estadisticas sin datos suficientes deben ofrecer registrar la primera sesion.
- Calendario/Diario vacio debe explicar que las sesiones apareceran al registrar lectura y ofrecer CTA `Registrar lectura`.
- Biblioteca vacia debe explicar que alli aparecera la biblioteca personal y ofrecer CTA `+ Añadir libro`.
- Insights vacio debe explicar que los insights apareceran al anadir lecturas y registrar sesiones.
- Durante la migracion a `ReadPpEmptyState`, algunos widgets antiguos quedan temporalmente marcados como no usados para evitar editar bloques con mojibake heredado; deben eliminarse en Sprint 19.4 Design System Consolidation.

## Design System Consolidation Hito 7 Sprint 19.4

- `ReadPpSurface` queda como superficie editorial compartida para cards, empty states y bloques visuales que requieran fondo, borde y sombra ReadPp.
- Las pantallas principales deben consumir `ReadPpPageHeader`; `AppBrandHeader` queda como implementacion interna/base del header compartido, no como API preferida de pantallas feature.
- Biblioteca sigue siendo la fuente de verdad visual; Home y resto de pantallas deben adaptar header, espaciados y tipografia a ese lenguaje.
- `MetricCard` usa `ReadPpSurface` y tokens del tema; no debe duplicar decoraciones de card si existe una superficie compartida.
- `ReadPpEmptyState` usa `ReadPpSurface` y motion suave compartida.
- `CurrentReadingCard` debe usar la tipografia del tema para titulo y porcentaje; no debe recuperar estilos locales de Cormorant ni boton interno `Ver lectura`.
- Los titulos y datos destacados de Home, Biblioteca, Calendario, Progreso, Estadisticas, Insights y Settings deben usar `Theme.textTheme` con Space Grotesk definido por el tema.
- `GoogleFonts` debe quedar concentrado en el tema/componentes base cuando sea necesario, no repetido directamente en pantallas principales.
- Se mantiene Roboto para cuerpo, labels, copy pequeno y controles.
- Los cambios de 19.4 son visuales/estructurales de componentes compartidos; no cambian logica de negocio ni flujos de datos.

## Reading Experience Polish Hito 7 Sprint 19.5

- El swipe del carrusel solo cambia la lectura visible; nunca modifica `reader_profile_current_reading_id`.
- La lectura principal se identifica explicitamente como `LECTURA PRINCIPAL`; el resto se identifica como `LECTURA EN CURSO`.
- Cambiar la lectura principal sigue siendo una accion explicita mediante el selector existente.
- `Otras lecturas` sirve para revisar y abrir lecturas activas, no para cambiar silenciosamente la principal.
- El progreso destacado debe mostrar porcentaje, paginas actuales/totales y paginas restantes sin truncados evitables.
- La portada de `CurrentReadingCard` se adapta al espacio vertical real para evitar overflows en dispositivos pequenos.
- El historial de progreso prioriza sesiones recientes y usa `createdAt` como desempate para sesiones del mismo dia.
- Relecturas no estan activas. La arquitectura futura recomendada usa ciclos de lectura separados para no duplicar libros ni perder historial.

## Insights Premium Hito 7 Sprint 19.6

- La seccion se titula unicamente `Tu perfil lector`; no recuperar `Lectura personal`.
- Autor favorito muestra el nombre y todos los libros asociados mediante lista horizontal de portadas.
- `Mejores lecturas` es la unica denominacion para el ranking visual; no duplicar `Lecturas destacadas`.
- Las mejores lecturas priorizan portada, rating y review/notas cuando existen.
- `ReadingInsightRatedBook` es el contrato de presentacion enriquecido con autor, portada y review.
- Insights reutiliza `BookCoverImage` para soportar portada remota, local y placeholder.
- La seccion se llama `Curiosidades`, nunca `Patrones`.
- Curiosidades puede calcularse con datos existentes e incluye libro largo/corto, actividad, genero y ritmo sin nuevas tablas.

## Accessibility & Responsiveness Hito 7 Sprint 19.7

- Las rutas de tabs principales deben abrir `MainNavigationScreen(initialIndex: ...)` para mantener navbar y navegacion coherente.
- Cada item de navbar debe exponer semantica de boton, label y estado seleccionado; la seleccion no puede depender solo del color.
- Botones solo-icono deben tener tooltip/label semantico y area tactil aproximada de 48 px cuando el layout lo permita.
- `BookCoverImage` acepta `semanticLabel` opcional y centraliza semantica de portadas remotas/locales/placeholder.
- Cards completas clicables deben anunciar rol de boton, contenido principal y hint de accion.
- Dias del calendario anuncian fecha, numero de sesiones y actividad; la intensidad visual no es la unica fuente de informacion.
- Alturas sensibles de navbar, Current Reading e Insights deben responder al escalado de texto.
- Grupos de metricas deben usar Wrap/columnas adaptativas cuando tres elementos no quepan con legibilidad.
- No introducir cambios de negocio para resolver accesibilidad o responsive.

## Release gate posterior a Sprint 19

- Una suite roja bloquea cualquier declaracion de Sprint 19 como listo para release, aunque `flutter analyze` este limpio.
- La semantica accesible debe validarse con tests y TalkBack; no basta con anadir un widget `Semantics` si el nodo final fusiona labels de forma distinta.
- La navbar de tabs debe vivir en un unico shell. La correccion futura debe evitar `Navigator.pushNamed` hacia rutas que construyen otro `MainNavigationScreen` cuando el destino es solo otro tab.
- Las visualizaciones con `CustomPaint` deben tener un resumen textual/semantico equivalente.
- Datos y copy de una grafica deben compartir la misma unidad; `Paginas por mes` no puede resumirse con minutos.
- Antes de crear el tag `v0.2.0-alpha`, decidir si se cambia `pubspec.yaml` desde `1.0.0+1` o si se mantiene la linea de versionado 1.0.
- El commit `9af2843` mezcla Motion & Delight con Google Books; futuras entregas deben separar commits por sprint para mejorar trazabilidad.

## Release alpha v0.2.0 - Decisiones cerradas

- ReadPp v0.2.0-alpha se considera completada cuando existen APK Release, Web desplegada en Vercel, testers externos activos, `flutter analyze` OK y suite completa en verde.
- Estado confirmado de release alpha: 67/67 tests.
- Los datos demo/base no deben crearse en modo normal ni en release alpha. Solo pueden existir detras de un modo debug/demo explicito y desactivado por defecto.
- Una instalacion limpia debe mostrar empty states reales y permitir probar onboarding/primer libro como usuario nuevo.
- Perfil lector movil valida nombre/saludo personalizado con minimo 2, maximo 15, trim, capitalizacion inicial, caracteres permitidos y bloqueo basico de terminos ofensivos. Web/Desktop queda como deuda responsive posterior.
- Open Library puede fallar temporalmente; el copy no debe sonar definitivo. Debe mantener `Reintentar` y `Anadir manualmente`.
- Google Books queda en roadmap como fallback robustecido para v0.4, no como garantia de producto de v0.2 si no esta suficientemente observado/validado.
- Insights/Curiosidades debe priorizar portadas o placeholder editorial cuando el dato este asociado a un libro concreto.
- Pendientes post-alpha quedan identificados como QA-018, QA-019, QA-020, QA-021 y QA-022.
- Roadmap actualizado tras Sprint 20.2: Observabilidad y Analytics completados; siguientes bloques Sprint 20.3 Funnel basico, v0.4 Google Books fallback y v0.5 Supabase.

## Web Deployment

- ReadPp es un proyecto Flutter; Vercel no debe desplegar la raiz del proyecto `reading_tracker`.
- ReadPp Web/PWA se despliega mediante build manual de Flutter Web.
- Proceso oficial:
  - Ejecutar `flutter build web --release` desde `reading_tracker`, con `dart-define` de Sentry y Analytics cuando aplique.
  - Entrar en `build/web`.
  - Ejecutar `vercel --prod` desde `build/web`.
  - Seleccionar el proyecto Vercel `readpp-web-alpha`.
  - Verificar `https://readpp-web-alpha.vercel.app`.
- No desplegar directamente desde la raiz del proyecto.
- Vercel debe recibir los artefactos estaticos generados por Flutter, no el workspace fuente.
- Sintoma de configuracion incorrecta: deploy termina en 4-8 segundos, Vercel muestra `Ready`, pero la URL devuelve `404_NOT_FOUND`.
- Ese sintoma suele indicar que se desplego la carpeta equivocada.
- Referencia: procedimiento validado durante Hito 6 Sprint 20.1 Sentry, 2026-06-24.

## Pre-Hito 7 Build Web/PWA

- La build Web/PWA alpha previa a Hito 7 debe activar Sentry y PostHog por `dart-define`.
- Usar release `readpp@0.2.0-alpha`.
- No guardar DSN de Sentry ni API key de PostHog en repositorio ni Memory Bank.
- Comando Bash base:
  - `flutter build web --release \`
  - `  --dart-define=SENTRY_DSN="<SENTRY_DSN>" \`
  - `  --dart-define=SENTRY_ENVIRONMENT=alpha \`
  - `  --dart-define=SENTRY_RELEASE=readpp@0.2.0-alpha \`
  - `  --dart-define=ANALYTICS_ENABLED=true \`
  - `  --dart-define=POSTHOG_API_KEY="<POSTHOG_API_KEY>" \`
  - `  --dart-define=POSTHOG_HOST=https://eu.i.posthog.com \`
  - `  --dart-define=APP_ENV=alpha`
- Tras la build: `cd build/web` y `vercel --prod`.

## Observabilidad Hito 6 Sprint 20.1

- Sentry queda como herramienta de observabilidad de ReadPp para errores de release.
- La integracion debe centralizarse en `ReadPpSentry`; evitar llamadas dispersas a Sentry desde features salvo a traves de helpers explicitos.
- Sentry solo se habilita en release y con `SENTRY_DSN` no vacio para no afectar tests, debug ni flujo normal.
- El DSN se configura mediante `--dart-define=SENTRY_DSN=...`; no commitear secretos ni valores reales.
- `APP_ENV` / entorno alpha se usa para separar eventos de validacion y release segun configuracion vigente del sprint.
- `SENTRY_RELEASE` define la release reportada; para la validacion alpha se uso `0.2.0-alpha`.
- Open Library debe registrar breadcrumbs y capturar excepciones con contexto suficiente para diagnosticar busquedas, manteniendo los mensajes de usuario desacoplados del proveedor.
- Los eventos de busqueda pueden incluir proveedor, query, plataforma, release, duracion, resultados, tipo de fallo y status code si existe.
- La validacion manual de Sentry fue temporal y quedo retirada tras Sprint 20.1.
- No debe quedar visible ni accesible ninguna accion manual de validacion en builds normales de usuarios finales.
- Si se necesita revalidar Sentry en el futuro, cualquier infraestructura manual debe ser explicitamente temporal, protegida y retirada al terminar la validacion.
- Sprint 20.1 se considera validado porque el evento real fue recibido correctamente en Sentry con environment `alpha` y release `0.2.0-alpha`.
- Pendiente siguiente: Sprint 20.3 Funnel basico.

## Analytics Hito 6 Sprint 20.2

- PostHog se usa para analytics de producto; no usar Firebase Analytics en este sprint.
- No se integra SDK de PostHog directamente en widgets: usar `ReadPpAnalytics`.
- La clave de PostHog no se hardcodea; siempre entra por `POSTHOG_API_KEY` via `dart-define`.
- Las claves no deben guardarse en repositorio ni en Memory Bank.
- `ANALYTICS_ENABLED=true` y `POSTHOG_API_KEY` no vacio son necesarios para enviar eventos.
- `POSTHOG_HOST` permite apuntar a EU Cloud u otro host compatible; en alpha se usa EU Cloud.
- `APP_ENV` identifica el entorno de producto, por ejemplo `alpha`.
- Sin configuracion valida, analytics debe ser no-op y la app debe funcionar igual.
- Los eventos no deben contener titulos, autores, notas, resenas, nombre de usuario ni query exacta.
- Las propiedades permitidas son derivadas: buckets, booleanos, longitudes y contadores.
- Los eventos PostHog se envian como anonimos con `$process_person_profile=false`.
- Eventos minimos Sprint 20.2: onboarding, alta de libros, alta manual, completado de libro, sesiones, busqueda Open Library y reto anual.
- Sprint 20.2 queda cerrado porque la app fue ejecutada con analytics activo y eventos reales aparecieron en PostHog.
- Validacion de producto: `Activity` y `Trends` revisados, con prueba de Trends `book_added = 2` y `reading_session_created = 1`.
- Validacion tecnica: `flutter analyze` OK y `flutter test` OK con 67/67 tests.

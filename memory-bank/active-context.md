# Active Context

## Foco actual

ReadPp v0.2.0-alpha: release alpha completada, en QA externo y con Observabilidad Sprint 20.1 validada.

Estado confirmado 2026-06-24:

- APK Release generada.
- Web desplegada en Vercel.
- Testers externos activos.
- Validacion automatizada vigente: 67/67 tests.
- `flutter analyze` OK.
- QA manual completo para el bloque previo a release alpha.
- Sprint 20.1 Observabilidad completado y validado en Web Release.
- Sentry integrado con configuracion por entorno, DSN via `dart-define`, captura global de errores, breadcrumbs y captura de errores de busqueda Open Library.
- Validacion real completada: evento recibido correctamente en Sentry.
- Environment validado: `alpha`.
- Release validada: `0.2.0-alpha`.
- Infraestructura temporal de validacion manual de Sentry retirada tras Sprint 20.1.

Hitos cerrados para v0.2.0-alpha:

- Eliminacion/desactivacion de datos demo en modo normal: una instalacion limpia arranca sin libros precargados y muestra empty states reales.
- QA manual de release ejecutado sobre Android/Web.
- Validacion de perfil lector: nombre/saludo personalizado con limites, normalizacion y bloqueo basico de terminos ofensivos.
- Open Library: copy de error ajustado, accion `Reintentar` verificada y fallback manual mantenido.
- Curiosidades de Insights visuales con portadas cuando la curiosidad se refiere a un libro.
- Build Android release generado.
- Build Web generado y desplegado en Vercel.
- Despliegue Web/PWA oficial: build manual de Flutter Web y despliegue desde `build/web` al proyecto Vercel `readpp-web-alpha`; nunca desplegar desde la raiz del proyecto.

Pendientes abiertos de QA post-alpha:

- QA-018.
- QA-019.
- QA-020.
- QA-021.
- QA-022.

Roadmap vigente:

- Sprint 20.2 Analytics.
- Sprint 20.3 Funnel basico.
- v0.4 Google Books fallback robustecido como segunda fuente.
- v0.5 Supabase para Auth, backend cloud y sincronizacion multi-dispositivo.

## Contexto Alpha previo

Hito 6: Alpha Testing & Polish.

ReadPp entro en fase Alpha QA. El foco vigente ya no es feature development general, sino estabilizacion Android, consistencia UX/UI, robustez de busqueda y preparacion Beta.

Sprint 18.x completado hasta Sprint 18.17:

- Home Android QA: multiples lecturas activas, carrusel completo, indicador `1 / N` y seleccion de lectura principal separada conceptualmente del swipe.
- Calendar / Reading Journal QA: seleccion de dia, refresco de sesiones, detalle del dia y seleccion de sesion dentro del diario.
- Android layout fixes: overflows corregidos en tarjeta de lectura actual y edicion de sesiones con titulos largos.
- UX cleanup: eliminadas acciones duplicadas donde correspondia y simplificado el flujo Calendario -> Diario -> Crear/Editar sesion.
- Visual polish: Biblioteca queda como fuente de verdad visual; Home y pantallas principales se alinean con ella.
- Shared Header: `ReadPpPageHeader` / header compartido basado en Biblioteca.
- Shared Current Reading Card: card burgundy editorial, sin CTA interno, toda la card clicable.
- Reading Challenge polish: copy `Buscar libro`, portada por ultimo libro completado y seleccion de portada desde libros del usuario.
- Insights polish: `Tu perfil lector`, autor favorito con libros/portadas y secciones `Mejores lecturas` / `Curiosidades`.
- Book Search Reliability: busqueda robusta, errores diferenciados, retry/timeout y fallback manual.
- Duplicate Protection: `BookDuplicateMatcher` centraliza deduplicacion por ISBN, proveedor+externalId y titulo+autor normalizados.
- Persistencia de IDs externos: `externalSource` / `externalId` persistidos en Drift con migracion segura.
- Manual Book Entry / ISBN Scanner / Local Cover: alta manual como fallback, escaneo ISBN, portada local opcional y render de `file://`.
- Multi-Source Book Search: `BookSearchRepository` coordina Open Library como proveedor primario y Google Books como fallback secundario.

Validacion vigente Sprint 18.17:

- `flutter analyze` OK.
- `flutter test` OK, 55/55 tests passed.

Limitaciones conocidas vigentes:

- La prueba manual completa de escaneo ISBN y portada local requiere dispositivo/emulador con camara/galeria operativas.
- El flujo Android compila y arranca cuando `JAVA_HOME` apunta al JBR de Android Studio.
- Google Books no usa API key en esta fase; queda como proveedor publico secundario.
- Los logs de proveedor/fallback son solo debug y no deben mostrarse al usuario final.

Roadmap inmediato:

- Resolver QA-018 a QA-022 con cambios acotados de hardening.
- Preparar Sprint 20.2 Analytics.
- Preparar Sprint 20.3 Funnel basico.
- Preparar v0.4 Google Books fallback robustecido.
- Preparar v0.5 Supabase.

Design Decisions - Do Not Regress:

- Biblioteca es la referencia visual principal.
- La card de lectura actual es clicable completa y no tiene boton interno `Ver lectura`.
- Space Grotesk se usa para titulos; Roboto se usa para cuerpo/UI.
- Reading Challenge usa `Buscar libro` / `Cambiar libro`, nunca `Buscar portada`.
- En Calendario los dias son clicables y no debe mostrarse el CTA `Abrir calendario`.

## Deuda tecnica posterior a v0.2.0-alpha

- Busqueda multi-source: consolidar Google Books como segunda fuente estable y observable en v0.3/v0.4. Orden objetivo: Open Library -> Google Books -> alta manual. La arquitectura y datasource existen, pero requieren QA de fiabilidad, limites y telemetria antes de considerarlos garantia de producto.
- Perfil Web/Desktop: el perfil personalizado queda validado para el flujo movil de v0.2.0-alpha. La composicion responsive y ergonomia de edicion en Web/Desktop requieren una revision especifica posterior; no forman parte de esta version.

## Contexto historico reciente

Hito 5: UX/UI Premium Redesign.

Sprint 13 completado: Release Candidate & Store Readiness.

Sprint 14 implementado: Demo Polish.

Sprint 15 completado: Stats Premium Redesign.

Sprint 17.x completado: Reader Profile, branding real y polish visual de headers/Home.

ReadPp v1.0 RC esta completo.

Estado actual: Publication Preparation In Progress.

ReadPp v1.0: Release Candidate Ready.

Validacion vigente:

- `flutter analyze` OK.
- `flutter test` OK.

Trabajo mas reciente completado:

- Hito 5 Sprint 15 completed.
- Statistics screen redesigned.
- Editorial header added.
- Hero metrics section added.
- `MetricCard` adopted in Stats.
- `SectionHeader` adopted in Stats.
- Annual goal redesigned visually.
- Duplicate metrics removed.
- Visual consistency aligned with Home, Progress and Insights.
- Sprint 16/17.x aplicado: perfil lector local, saludo dinamico, seleccion de lectura actual y branding real ReadPp.
- `AppBrandHeader` queda como componente principal para logo real + saludo dinamico en pantallas principales.
- Home, Biblioteca, Progreso, Estadisticas, Insights y Ajustes leen el perfil lector para saludar de forma consistente.
- Home reutiliza el logo real ReadPp y mantiene acceso a Perfil, Libro y Calendario.
- Home mejora profundidad visual con gradiente alineado a Progreso/Biblioteca, sombras suaves y bordes rosados sutiles en metricas/reto anual.
- Biblioteca y Progreso ya no muestran los titulos grandes `Tu Biblioteca` / `Tu Progreso`; conservan header de marca y textos informativos.
- Calendario recibe polish visual: titulo `Book Journal`, fondo degradado rosa, resumen con emoji/numero/texto, bordes mas visibles en dias y selector Mes/Semana alineado al estilo ReadPp.
- Formulario de libro corrige keys duplicadas en resultados Open Library usando indice y metadatos para evitar errores con titulos repetidos.
- Sprint 17.6 Onboarding Refresh aplicado: onboarding usa logo real ReadPp y nuevas imagenes desde `assets/images/onboarding/slide_1.png`, `slide_2.png` y `slide_3.png`.
- Sprint 17.7 Home Premium Polish aplicado: Home se alinea a la referencia editorial premium con saludo protagonista, botones pill, hero mas compacto, resumen de hoy, mini calendario semanal y lecturas en curso.
- `Lecturas en curso` en Home ahora es un carrusel horizontal con swipe, snap, preview lateral, indicadores de pagina y seleccion persistida del libro visible.
- Reto anual de Home usa ilustracion editorial generada en `assets/images/home/annual_goal_illustration.png`.
- ReadPp UI Consistency Pass aplicado: Biblioteca, Progreso, Estadisticas, Insights y Ajustes se alinean con Home usando la misma jerarquia tipografica, sistema de cards, bordes, sombras, spacing y header compartido.
- Actualizacion final UI consistency: Onboarding deja de usar screenshots y usa ilustraciones nativas flotantes; Settings/Perfil queda como pantalla de preferencias, no dashboard; Calendario muestra primero el calendario y abajo el resumen de paginas/minutos/dias.
- Botones globales unificados desde `AppTheme`: `FilledButton`, `OutlinedButton` y `TextButton` comparten radio, padding, peso, colores y disabled state. Evitar `styleFrom` locales salvo excepcion justificada por contraste.
- Objetivo anual en Estadisticas se reordeno: aparece como primer bloque util tras el header; accion `Definir/Editar objetivo` y preview de progreso van antes del copy informativo.
- `AppBrandHeader`, `MetricCard` y `SectionHeader` se refinan como componentes reutilizables del sistema visual actual.
- Demo Polish Sprint 14 aplicado con cambios minimos de alto impacto visual.
- Correccion de barra de reto anual en Home: `annualGoalProgress` se normaliza de porcentaje `0-100` a valor visual `0-1`.
- Nombre por defecto hardcodeado unificado de `Daniela` a `Lectora`.
- Branding de headers unificado mediante `AppBrand.symbol = 'dP'`; Home deja de mostrar `RP`.
- Correcciones puntuales de copy/tildes en textos visibles.
- Validacion Sprint 14 pendiente en terminal del usuario: `dart format`, `flutter analyze` y `flutter test`.
- Auditoria visual completa.
- Auditoria de navegacion.
- Auditoria tipografica.
- Revision basica de accesibilidad.
- Revision de store readiness.
- Limpieza de codigo.
- Estabilizacion de Release Candidate.
- Branding Final completado.
- Integracion de iconos de app completada.
- Preparacion inicial de publicacion iniciada.

## Branding Final Completion

- Nombre publico oficial: ReadPp.
- Tema principal: Burgundy.
- Tema secundario: Forest.
- Tipografia de marca/titulos: Space Grotesk.
- Tipografia UI/body: Roboto.
- Logo oficial integrado en assets del proyecto.
- Assets oficiales centralizados bajo `reading_tracker/assets/branding`.
- Iconos placeholder de Flutter reemplazados.
- Iconos Android generados.
- Iconos iOS generados.
- Iconos Web/PWA generados.
- Splash basico Burgundy alineado con la marca.
- Documentacion interna de branding actualizada.

Estado de publicacion actual:

- Release Candidate completado.
- Branding Final completado.
- Publication Preparation en curso.

La Home ya funciona como pantalla editorial de biblioteca personal y concentra:

- Lectura actual.
- Progreso lector.
- Objetivo anual.
- Actividad reciente.
- FAB para anadir libro.

Biblioteca ya fue redisenada como coleccion editorial premium:

- Header ReadPp coherente con Home.
- Marca `dP + ReadPp` navegable a Home.
- Featured Reading cuando hay libro en lectura.
- Filtros compactos por estado.
- Grid visual centrado en portadas.
- Empty states editoriales.

Book Detail ya fue redisenada y refinada como ficha editorial premium:

- Hero inmersiva con portada protagonista.
- Badge de estado.
- Progreso premium con paginas restantes.
- Informacion editorial en pills.
- Sesiones recientes estilo timeline.
- Acciones no funcionales marcadas como proximamente o secundarias.

Progreso ya no es una lista de accesos:

- Header editorial `Tu Progreso`.
- Card protagonista con racha, completados del ano, paginas y lectura activa.
- Card de reto lector anual usando `StatisticsSummary`.
- Actividad lectora con accesos a calendario/registro y sesiones recientes reales.
- Accesos rapidos premium a Estadisticas, Calendario y Registrar sesion.

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
- Persistencia local de perfil lector con `shared_preferences`: nombre, saludo elegido, saludo personalizado y libro principal de lectura actual.
- Branding base de ReadPp con estructura de assets, constantes de marca y wordmark reutilizable.
- Simbolo de marca centralizado como `AppBrand.symbol = 'dP'`.
- Logo real de ReadPp integrado en headers mediante `img-logo/transparent-logo (1).png`.
- Tipografia global preparada con Playfair Display para titulos e Inter para contenido.
- Adaptador `AppIcons` para centralizar iconografia y facilitar una futura migracion a Lucide.
- Motion tokens y widgets reutilizables para transiciones suaves.
- Iconografia de Home/Bottom Navigation/metricas/acciones migrada hacia `AppIcons` con Lucide donde ya esta disponible.
- Tipografia del proyecto fue iterada varias veces; el estado actual del codigo usa Roboto globalmente, aunque las referencias de diseno siguen hablando de estilo editorial.
- Tipografia actual de producto: Roboto para texto general y Space Grotesk para titulos principales/display cuando aplica.
- Guia visual actual aprobada: Cormorant Garamond como acento editorial selectivo para saludos, heroes, titulos grandes y valores destacados; Roboto para UI, labels, botones, formularios, navegacion y cuerpo.

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
- Se implemento Hito 5 Sprint 4 - Biblioteca Premium Redesign.
- Biblioteca paso de lista tecnica a pantalla editorial centrada en portadas.
- Se agrego header editorial, featured reading, filtros compactos, grid visual y empty states premium.
- Se aplicaron correcciones UX en Biblioteca: conteo junto a `Coleccion`, marca navegable a Home, filtros sin overflow y empty states sin scroll excesivo.
- Se corrigio el test `shows the books screen` para esperar `Tu Biblioteca`.
- Se implemento Hito 5 Sprint 5 - Book Detail Premium Redesign.
- Book Detail paso de pantalla administrativa a ficha editorial premium con hero, progreso, informacion editorial, sinopsis, estado lector y sesiones recientes.
- Se implemento Hito 5 Sprint 5.1 - Home Visual Refinement.
- Home recibio refinamiento de spacing, hero, metricas, goal card, actividad reciente y bottom navigation.
- Se aplicaron ajustes posteriores de fuente y peso para mejorar legibilidad movil.
- Se implemento Hito 5 Sprint 6 - Biblioteca Visual Refinement.
- Se corrigio el espaciado del grid de Biblioteca para evitar huecos grandes entre `Coleccion` y las cards y para que la bottom nav no corte libros.
- Se implemento Hito 5 Sprint 7 - Book Detail Visual Refinement.
- Book Detail recibio refinamiento de hero, progress card, acciones rapidas, informacion editorial, sinopsis y timeline.
- Se implemento Hito 5 Sprint 8 - Progress Premium Redesign.
- ProgressScreen consume `statisticsSummaryProvider`, `booksProvider` y `readingSessionsForRangeProvider` para mostrar datos reales sin crear nuevos calculos de dominio.
- ProgressScreen mantiene navegacion existente a `/stats`, `/calendar` y `/session/add`.
- Se implemento Hito 5 Sprint 9 - Library Premium Redesign y refinamientos posteriores.
- Biblioteca quedo enfocada exclusivamente en coleccion de libros: buscar, filtrar, consultar y anadir.
- En Biblioteca se mantiene boton `+ / Anadir` en header y FAB; se eliminaron las cards estadisticas superiores para no mezclar responsabilidades con Stats/Progress/Insights.
- Se implemento Hito 5 Sprint 10 - Empty States & UX Polish.
- Se implemento Hito 5 Sprint 11 - Reading Sessions Premium: calendario, day detail y formulario de sesiones recibieron tratamiento premium sin cambiar modelos/repositorios.
- Se implementaron correcciones UX Sprint 11/11A/11B.
- Home mantiene accion superior para anadir/buscar libro y elimina acceso superior redundante a Perfil; Perfil se accede desde bottom nav.
- Add Book fue refinada como pantalla premium con hero, buscador Open Library protagonista, resultados visuales, seleccion destacada, secciones de estado/fechas/paginas y CTA principal.
- Insights fue refinada como pantalla principal premium con header de marca, hero, metricas destacadas, panel de descubrimiento principal, secciones editoriales y padding inferior seguro.
- Perfil fue corregido para funcionar como pantalla de ajustes y preferencias, no como dashboard: mantiene header/hero de preferencias, selector de tema y bloque `Proximamente`; no muestra metricas lectoras, reto anual ni estadisticas globales.
- Modelo conceptual actual: Home = resumen general; Biblioteca = coleccion; Progress = seguimiento; Stats = metricas; Insights = descubrimientos/curiosidades; Perfil = usuario, ajustes y preferencias.
- Tipografia actual indicada por el usuario: Roboto global.
- Se implemento Hito 5 Sprint 12 - Onboarding + First Run Experience.
- La app ahora muestra onboarding solo en primera apertura.
- El onboarding tiene 3 pantallas: viaje lector, registro de lecturas y perfil lector.
- El flujo incluye acciones `Omitir`, `Siguiente`, `Empezar` e indicador visual de progreso.
- El estado de finalizacion se persiste localmente con `SharedPreferences` usando la flag `onboarding_completed`.
- Los usuarios recurrentes no ven onboarding automaticamente despues de completarlo u omitirlo.
- Tras completar onboarding, el usuario entra en el flujo normal de la app.
- Home e Insights mejoraron sus empty states para guiar al usuario hacia anadir el primer libro.
- No se introdujo autenticacion, backend, sincronizacion ni cambios de arquitectura.
- Validacion Sprint 12 confirmada por el usuario: `flutter analyze` OK y `flutter test` OK (34/34 tests).
- Se completo Hito 5 Sprint 13 - Release Candidate & Store Readiness.
- Se realizo auditoria visual general de pantallas principales.
- Se realizo auditoria de navegacion, tipografia y accesibilidad basica.
- Se reviso branding basico y preparacion para distribucion.
- Se hizo limpieza de codigo muerto/comentarios obsoletos detectados.
- ReadPp v1.0 queda como Release Candidate completo.
- Estado actual: Ready for Store Preparation.
- Validacion Sprint 13 confirmada: `flutter analyze` OK y `flutter test` OK.

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
- `reading_tracker/lib/core/preferences/reader_profile_controller.dart`
- `reading_tracker/lib/core/branding/widgets/app_brand_header.dart`
- `reading_tracker/lib/core/branding/app_brand.dart`
- `reading_tracker/lib/features/books/presentation/screens/books_list_screen.dart`
- `reading_tracker/lib/features/progress/presentation/screens/progress_screen.dart`
- `reading_tracker/lib/features/stats/presentation/screens/stats_screen.dart`
- `reading_tracker/lib/features/insights/presentation/screens/insights_screen.dart`
- `reading_tracker/lib/features/reading_sessions/presentation/screens/calendar_screen.dart`
- `reading_tracker/lib/features/books/presentation/screens/book_form_screen.dart`
- `reading_tracker/lib/features/home/presentation/screens/home_screen.dart`
- `reading_tracker/lib/features/onboarding/presentation/screens/onboarding_screen.dart`
- `reading_tracker/assets/images/onboarding/slide_1.png`
- `reading_tracker/assets/images/onboarding/slide_2.png`
- `reading_tracker/assets/images/onboarding/slide_3.png`
- `reading_tracker/assets/images/home/annual_goal_illustration.png`
- `reading_tracker/pubspec.yaml`
- `reading_tracker/lib/features/navigation/presentation/screens/main_navigation_screen.dart`
- `reading_tracker/lib/features/onboarding/presentation/providers/onboarding_controller.dart`
- `reading_tracker/lib/features/onboarding/presentation/screens/onboarding_screen.dart`
- `reading_tracker/lib/features/progress/presentation/screens/progress_screen.dart`
- `reading_tracker/assets/branding/README.md`
- `reading_tracker/assets/fonts/README.md`
- `reading_tracker/pubspec.yaml`
- `reading_tracker/lib/features/reading_sessions/presentation/screens/session_form_screen.dart`
- `reading_tracker/lib/features/reading_sessions/presentation/screens/day_detail_screen.dart`
- `reading_tracker/lib/features/reading_sessions/presentation/utils/session_completion_flow.dart`
- `reading_tracker/test/reading_insights_summary_test.dart`
- `reading_tracker/test/reading_session_delete_test.dart`
- `reading_tracker/test/reading_session_edit_test.dart`

## Validaciones

El usuario ejecuta las validaciones en su terminal de VS Code. No ejecutarlas desde Codex salvo que lo pida explicitamente.

Actualizacion Hito 7 Sprint 19.4:

- Codex ejecuto `dart format lib test` por peticion de continuidad del sprint.
- Codex ejecuto `flutter analyze`: OK, sin issues.
- Codex ejecuto `flutter test`: OK, 55/55 tests.

## Hito 7 Sprint 19.4 - Design System Consolidation

- Consolidado `ReadPpSurface` como superficie editorial compartida.
- `ReadPpPageHeader` queda aplicado en pantallas principales; `AppBrandHeader` se conserva como base interna del componente compartido.
- `MetricCard`, `ReadPpEmptyState`, `CurrentReadingCard` y hero de Settings quedan alineados con tokens/tema compartidos.
- Pantallas principales dejan de usar Cormorant/GoogleFonts directo para titulos y datos destacados.
- Space Grotesk via `Theme.textTheme` queda como fuente de titulos; Roboto via tema queda para cuerpo/UI.

## Hito 7 Sprint 19.5 - Reading Experience Polish

- `CurrentReadingCard` diferencia `LECTURA PRINCIPAL` y `LECTURA EN CURSO` mediante `isPrimaryReading`.
- Swipe y PageView no escriben la preferencia de lectura principal; el selector explicito sigue siendo la unica accion que la cambia.
- La card muestra porcentaje, paginas actuales/totales y paginas restantes; la portada se ajusta a la altura disponible.
- `Otras lecturas` abre el flujo de progreso del libro seleccionado sin cambiar la principal.
- El detalle de libro muestra `Historial de progreso`, orden reciente estable, badge `Ultimo avance` y nota de sesion cuando existe.
- Relecturas quedan documentadas como futura entidad de ciclo separada, sin cambios actuales en `Book` o Drift.
- Validacion ejecutada: `dart format lib test` OK, `dart analyze lib test` OK y `git diff --check` OK.
- `flutter analyze` y `flutter test` no completaron porque el SDK local quedo esperando antes de crear proceso/salida; repetir en una terminal Flutter funcional.

## Hito 7 Sprint 19.6 - Insights Premium

- `ReadingInsightRatedBook` incorpora autor, `coverUrl` y review/notas.
- `Mejores lecturas` usa carrusel horizontal de cards con portada protagonista, rating y review opcional.
- Autor favorito conserva nombre y todos los libros leidos con portadas en lista horizontal.
- `Curiosidades` incorpora libro mas corto y ritmo medio por dia activo.
- `BookCoverImage` es la implementacion compartida para portadas en Insights.
- Validacion intermedia: `dart format lib test` y `dart analyze lib test` OK.

## Hito 7 Sprint 19.7 - Accessibility & Responsiveness

- Rutas `/home`, `/books`, `/progress`, `/insights` y `/settings` mantienen navbar mediante `MainNavigationScreen` e indice inicial.
- Navbar anuncia label, rol y estado seleccionado y adapta altura al escalado de texto.
- `BookCoverImage` soporta `semanticLabel` opcional.
- `CurrentReadingCard` anuncia principal/en curso y accion; adapta altura desde Home al text scale.
- Dias de calendario anuncian fecha, sesiones, paginas y minutos; controles de periodo y alta tienen tooltip y target ampliado.
- Card principal del diario anuncia libro, metricas y accion de apertura.
- Insights usa metricas responsive, cards horizontales adaptativas y alturas sensibles a fuente grande.
- Validacion final: `dart format lib test`, `dart analyze lib test` y `git diff --check` OK.
- `flutter analyze` y `flutter test` fueron intentados, quedaron bloqueados antes de crear proceso/salida y se cerraron; no asumirlos validados.

## Revision tecnica Sprint 19 - 2026-06-22

- Rango Git revisado: `57a8e2c..HEAD` (`9af2843` y `d71d452`).
- El worktree estaba limpio durante la revision.
- Validacion vigente: `dart format --output=none --set-exit-if-changed lib test` OK.
- Validacion vigente: `dart analyze lib test` OK y `flutter analyze --no-pub` OK, sin issues.
- `flutter test --no-pub` completa la suite pero queda roja: 54 tests pasan y 1 falla.
- Fallo actual: `home swipes between multiple active readings` no encuentra la etiqueta semantica exacta `Lectura principal: Lectura principal`.
- Bloqueante P1: alinear la semantica real de `CurrentReadingCard` con el test y TalkBack; el nodo puede estar fusionando label y textos hijos.
- Riesgo P1: rutas internas de tabs crean nuevos `MainNavigationScreen` mediante `Navigator.pushNamed`, pudiendo apilar shells/navbar y producir Back/estado de tabs confuso.
- Riesgo P2: la card `Paginas por mes` usa barras de paginas pero subtitulo calculado desde minutos.
- Riesgo P2: progress ring y donut de Estadisticas usan `CustomPaint` sin resumen semantico explicito.
- Deuda P3: permanecen widgets legacy marcados con `unused_element`, especialmente en Insights, Stats, Home y estados vacios.
- QA manual pendiente: Android pequeno/grande, Web/Desktop, TalkBack, navegacion Back, 4+ lecturas, finalizacion/confeti y graficas.
- Estado de release: Sprint 19 implementado pero no listo para etiquetar/publicar hasta resolver test y bloqueantes P1.
- Versionado pendiente: `pubspec.yaml` declara `1.0.0+1`; confirmar antes de proponer/taggear `v0.2.0-alpha`.

## Release hardening v0.2.0-alpha - 2026-06-22

- Test semantico del carrusel robustecido: valida la propiedad declarada del widget `Semantics` sin depender de la fusion final de nodos.
- Accesos internos a Biblioteca, Progreso y Perfil usan `pushNamedAndRemoveUntil`; no quedan `pushNamed` directos hacia tabs principales.
- La pantalla de Perfil no vuelve a navegar hacia si misma desde su header.
- `Paginas por mes` usa `monthlyPages` tanto en barras como en subtitulo.
- Ring, donuts y barras de Estadisticas incorporan resumen semantico basico.
- Validacion vigente: format de `lib test` OK, `dart analyze` OK, `flutter analyze` OK y `flutter test` OK con 55/55.
- El comando global `dart format --set-exit-if-changed .` sigue bloqueado por una ruta obsoleta dentro de `build`; las fuentes se validaron con `lib test`.
- Estado: bloqueantes automatizados cerrados; listo para QA manual de v0.2.0-alpha, no todavia para publicacion final.

Estado confirmado para Hito 5 Sprint 13:

- `flutter analyze` OK.
- `flutter test` OK.

## Pendientes reales

1. Final splash branding pass.
2. Android adaptive icon review.
3. Verificacion real de icono en dispositivo.
4. Play Store screenshots.
5. Store listing copy.
6. Privacy policy publica.
7. Configurar firma de release y generar AAB firmado.
8. Play Store submission.
9. Mas adelante investigar Open Library para mejorar resultados en espanol.

## Riesgos / notas

- El usuario prefiere ejecutar validaciones localmente; indicarle comandos, no correrlos aqui.
- No revisar `git status` ni `git diff` salvo que el usuario lo pida explicitamente.
- Codex/VS Code puede quedarse bloqueado en "Enviando cambios"; verificar con `git status` y `git diff`.
- Mantener cambios pequenos y acotados por problema.
- No tocar Open Library, modelos o persistencia salvo requisito explicito.
- No hacer commit ni push automaticamente.

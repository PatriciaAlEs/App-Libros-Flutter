# Product Requirements

## Nombre

`reading_tracker`

## Descripcion

App Flutter mobile-first para seguimiento personal de lectura. Permite registrar libros, sesiones de lectura, visualizar actividad en calendario, consultar estadisticas e insights de lectura.

Estado actual tras Hito 6 Sprint 18.x: Alpha Testing & Polish, con Android QA, consistencia UX/UI, busqueda multi-fuente, deduplicacion y preparacion Beta como foco.

## Problema

Una persona lectora puede tener varios libros pendientes, en curso o completados, y necesita una forma simple de registrar progreso y habitos de lectura por dia.

## Usuarios objetivo

- Lectores individuales.
- Personas que quieren registrar libros y sesiones sin usar una herramienta compleja.
- Usuarios que priorizan una experiencia simple en movil.

## Funcionalidades implementadas

### Libros

- Listado de libros.
- Filtro por estado.
- Alta desde busqueda en Open Library.
- Alta desde busqueda remota mediante `BookSearchRepository`, con Open Library como proveedor primario y Google Books como fallback.
- Alta manual como fallback cuando no hay resultados o falla la busqueda remota.
- Escaneo ISBN opcional como ayuda para completar datos.
- Portada local opcional guardada solo en el dispositivo.
- Deduplicacion antes de guardar por ISBN, `externalSource + externalId` y titulo+autor normalizados.
- Detalle de libro.
- Cambio de estado: `pending`, `reading`, `completed`, `paused`, `abandoned`.
- Eliminacion de libros.

### Sesiones de lectura

- Alta de sesiones asociadas a libros en estado `reading`.
- Fecha preseleccionada desde calendario/detalle de dia.
- Campos para minutos y paginas leidas (`pagesRead`) con validacion.
- Nota opcional.
- Persistencia en Drift.

### Calendario

- Vista mensual compacta.
- Vista semanal tipo agenda.
- Navegacion por mes/semana.
- Detalle de dia con total de minutos y sesiones.
- Dias con actividad muestran portadas pequenas y contador `+N` cuando hay mas de 3 libros.
- Seleccionar un dia muestra sesiones de ese dia y se refresca tras crear/editar sesiones.
- Empty states para dias/semanas sin sesiones.

### Stats

- Implementado con datos reales desde libros y sesiones.
- Existen calculadora, provider, pantalla, widgets y tests de calculo.
- Incluye resumen de biblioteca, progreso, objetivo anual, rachas y ritmo de lectura.

### Insights

- Hito 4 iniciado.
- Sprint 1, Sprint 2 y Sprint 3 implementados y validados.
- Sprint 4 implementado como perfil lector premium.
- Pantalla `/insights`.
- Muestra `Tu perfil lector`: autor favorito, genero favorito y libro al que mas tiempo se dedico.
- Muestra `Tus mejores lecturas`: Top 3 lecturas del año por rating.
- Muestra `Curiosidades`: libro mas largo, mes con mas lectura, franja horaria habitual y dia mas activo.
- Los calculos usan paginas leidas acumuladas desde `ReadingSession.pagesRead`.
- Genero favorito usa el campo existente `Book.genre` cuando esta disponible.
- Si no hay datos suficientes, muestra estados vacios claros.
- No incluye IA, servicios externos ni tablas nuevas.

### Navegacion principal

- Hito 5 Sprint 1 implementado.
- Navegacion principal con tabs Inicio, Biblioteca, Progreso, Insights y Ajustes.
- Inicio muestra el dashboard actual.
- Biblioteca abre la lista de libros.
- Progreso da acceso a Estadisticas, Reading Challenge, Activity Tracking/calendario y registro de sesion.
- Insights abre la pantalla Insights existente.
- Ajustes permite elegir tema Burgundy o Forest y persiste la preferencia localmente.
- No incluye autenticacion, perfil real, Firebase, servicios externos ni cambios de datos.

### Design System

- Hito 5 Sprint 2 implementado.
- Tema Burgundy por defecto y tema Forest seleccionable.
- Tipografia Material 3 definida para display, headline, title, body y label.
- Tokens reutilizables de spacing, radios, elevaciones y sombras suaves.
- Componentes base creados: `MetricCard`, `InsightCard`, `ProgressCard`, `SectionHeader` y `EmptyStateCard`.
- No redisenia todavia Home, Biblioteca, Estadisticas ni Insights.

### Branding & Visual Identity

- Hito 5 Sprint 2.5 implementado.
- Branding base de ReadPp preparado con estructura de assets para logo principal, app icon y variantes futuras.
- Wordmark reutilizable con fallback textual hasta tener logo definitivo.
- Tipografia global: Playfair Display para titulos e Inter para contenido.
- Burgundy y Forest consolidados como paletas oficiales.
- Iconografia centralizada mediante `AppIcons`, lista para una futura migracion a Lucide o equivalente.
- Motion tokens y widgets reutilizables para cards, FAB, cambios de tema y transiciones basicas.
- No redisenia Biblioteca, Estadisticas, Insights ni Detalle Libro.

### Home Premium

- Hito 5 Sprint 3 implementado.
- Home redisenada como biblioteca personal moderna.
- Header con `READPP •`, `Tu biblioteca personal` y saludo contextual.
- Hero card de lectura actual con portada grande, titulo, autor, porcentaje, pagina actual/total y barra de progreso.
- Empty state elegante cuando no hay libro en lectura.
- Metricas compactas: racha actual, libros completados este ano y paginas leidas.
- Objetivo lector anual en card independiente.
- Actividad reciente compacta con maximo 3 sesiones y accion `Ver actividad`.
- Anadir libro se accede desde FAB.
- No redisenia Biblioteca, Estadisticas, Insights ni Detalle Libro.

### Alpha QA & Shared Components

- Hito 6 Sprint 18.x implementado.
- Biblioteca es la referencia visual principal para header, fondo, spacing y jerarquia.
- Header compartido (`ReadPpPageHeader` / header de pantalla) reutilizable en pantallas principales.
- Card compartida de lectura actual (`CurrentReadingCard` / card destacada) con diseno burgundy editorial y toda la card clicable.
- Home soporta multiples lecturas activas con indicador `1 / N` y swipe horizontal.
- La seleccion de lectura principal se mantiene separada del swipe del carrusel.
- Reading Challenge usa `Buscar libro` / `Cambiar libro` y puede usar portada de ultimo libro completado.
- Insights queda como perfil lector con mejores lecturas, autor favorito con portadas y curiosidades.

## Fuera del MVP actual

- Backend.
- Login o cuentas de usuario.
- Firebase.
- Stripe o pagos.
- Sincronizacion remota.
- Funciones sociales.
- Exportacion/importacion.

## Modelo de datos resumido

### Book

Campos principales: `id`, `title`, `author`, `publisher`, `coverUrl`, `isbn`, `externalSource`, `externalId`, `firstPublishYear`, `genre`, `language`, `status`, `totalPages`, `currentPage`, `rating`, `notes`, `startDate`, `completedDate`, `createdAt`, `updatedAt`.

### ReadingSession

Campos: `id`, `bookId`, `date`, `minutes`, `pagesRead`, `note`, `createdAt`, `updatedAt`.

Relaciones:

- Un libro puede tener muchas sesiones.
- Una sesion pertenece a un libro.
- Un dia puede contener varias sesiones.

## Requisitos no funcionales

- Mobile-first.
- Persistencia local con Drift + SQLite.
- Arquitectura simple por features.
- Dominio sin dependencia directa de Drift.
- Mappers en capa `data`.
- Estado con Riverpod.
- Tests focalizados en logica y calculos.

## Criterios de aceptacion actuales

- Se puede buscar y guardar un libro desde Open Library.
- Si Open Library falla o no devuelve resultados, se consulta Google Books antes de ofrecer alta manual.
- Si un libro ya existe, no se crea duplicado y se informa con `Este libro ya esta en tu biblioteca.`.
- Se puede crear libro manual como fallback, con ISBN y portada opcionales.
- Se puede cambiar estado y eliminar libros.
- Se puede registrar una sesion para libros en lectura.
- El calendario refleja sesiones guardadas.
- El detalle de dia muestra sesiones y total de minutos.
- Stats muestra metricas calculadas desde datos reales.
- Insights muestra perfil lector, mejores lecturas y curiosidades cuando hay datos suficientes.
- Las secciones principales son accesibles desde la navegacion inferior.
- El usuario puede seleccionar y conservar localmente el tema visual.
- La identidad visual global queda preparada para redisenos futuros.
- Home prioriza lectura actual, progreso lector, objetivo anual y actividad reciente.

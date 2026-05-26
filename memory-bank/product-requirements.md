# Product Requirements

## Nombre

`reading_tracker`

## Descripcion

App Flutter mobile-first para seguimiento personal de lectura. Permite registrar libros, sesiones de lectura, visualizar actividad en calendario, consultar estadisticas e insights de lectura.

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

Campos principales: `id`, `title`, `author`, `publisher`, `coverUrl`, `isbn`, `firstPublishYear`, `genre`, `language`, `status`, `totalPages`, `currentPage`, `rating`, `notes`, `startDate`, `completedDate`, `createdAt`, `updatedAt`.

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
- Se puede cambiar estado y eliminar libros.
- Se puede registrar una sesion para libros en lectura.
- El calendario refleja sesiones guardadas.
- El detalle de dia muestra sesiones y total de minutos.
- Stats muestra metricas calculadas desde datos reales.
- Insights muestra perfil lector, mejores lecturas y curiosidades cuando hay datos suficientes.
- Las secciones principales son accesibles desde la navegacion inferior.
- El usuario puede seleccionar y conservar localmente el tema visual.

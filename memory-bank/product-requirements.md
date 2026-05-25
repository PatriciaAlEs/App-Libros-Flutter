# Product Requirements

## Nombre

`reading_tracker`

## Descripcion

App Flutter mobile-first para seguimiento personal de lectura. Permite registrar libros, sesiones de lectura, visualizar actividad en calendario, consultar estadisticas e insights iniciales.

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
- Cambio de estado: `pending`, `reading`, `completed`.
- Eliminacion de libros.

### Sesiones de lectura

- Alta de sesiones asociadas a libros en estado `reading`.
- Fecha preseleccionada desde calendario/detalle de dia.
- Campo de minutos con validacion `> 0`.
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
- Sprint 1 implementado y validado.
- Pantalla `/insights`.
- Muestra libro mas leido, autor mas leido y genero favorito.
- Los calculos usan paginas leidas acumuladas desde `ReadingSession.pagesRead`.
- Genero favorito usa el campo existente `Book.genre` cuando esta disponible.
- Si no hay datos suficientes, muestra estados vacios claros.
- No incluye predicciones ni IA.

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
- Insights muestra libro mas leido, autor mas leido y genero favorito cuando hay sesiones con paginas leidas.

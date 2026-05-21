# Product Requirements

## Nombre

`reading_tracker`

## Descripcion

App Flutter mobile-first para seguimiento personal de lectura. Permite registrar libros, sesiones de lectura, visualizar actividad en calendario y consultar estadisticas.

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

- Parcialmente implementado.
- Existen calculadora, provider, pantalla, widgets y tests de calculo.
- Pendiente cerrar UX, textos y validacion funcional final.

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

Campos: `id`, `bookId`, `date`, `minutes`, `note`, `createdAt`.

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
- Stats existe, pero no debe considerarse cerrado hasta validar UX y datos finales.

# Data Model

## Book

Entidad de dominio ubicada en `features/books/domain/entities/book.dart`.

Campos clave:

- `id`
- `title`
- `author`
- `publisher`
- `coverUrl`
- `isbn`
- `firstPublishYear`
- `genre`
- `language`
- `status`
- `totalPages`
- `currentPage`
- `rating`
- `notes`
- `startDate`
- `completedDate`
- `createdAt`
- `updatedAt`

Estados:

- `pending`
- `reading`
- `completed`

## ReadingSession

Entidad de dominio ubicada en `features/reading_sessions/domain/entities/reading_session.dart`.

Campos:

- `id`
- `bookId`
- `date`
- `minutes`
- `pagesRead`
- `note`
- `createdAt`
- `updatedAt`

## Relaciones

- Un libro puede tener muchas sesiones.
- Una sesion pertenece a un libro.
- Un dia puede tener varias sesiones y varios libros.

## Persistencia

- Tablas Drift: `books`, `reading_sessions`.
- `reading_sessions.bookId` referencia `books.id`.
- Las fechas de sesion se normalizan a dia para consultas de calendario.

# Contexto del proyecto

## Resumen

`reading_tracker` es una app Flutter para registrar libros, seguir el estado de lectura y visualizar sesiones de lectura en calendario.

Arquitectura actual:

- `lib/core`: infraestructura compartida, tema, Drift, providers de base de datos y utilidades.
- `lib/features/books`: busqueda/alta de libros, listado, detalle y estado de lectura.
- `lib/features/reading_sessions`: sesiones de lectura, calendario mes/semana, detalle de dia y formulario de sesion.
- `lib/features/stats`: reservado; archivos creados pero todavia vacios.

## Stack

- Flutter / Dart.
- Riverpod (`flutter_riverpod`) para estado e inyeccion.
- Drift + SQLite para persistencia real.
- Drift web con `WebDatabase` sobre IndexedDB.
- `http` para Open Library.
- `uuid` para IDs.
- `intl` declarado, poco usado todavia.

## Entrada y rutas

Entrada:

- `reading_tracker/lib/main.dart`
- `reading_tracker/lib/app.dart`

Rutas principales:

- `/`: listado de libros.
- `/book/add`: busqueda y alta desde Open Library.
- `/book/detail`: detalle de libro.
- `/calendar`: calendario de lectura.
- `/calendar/day`: detalle de un dia.
- `/session/add`: registrar sesion de lectura.

## Drift

Archivos importantes:

- `core/database/app_database.dart`: `AppDatabase`, `schemaVersion = 2`, tablas y DAOs.
- `core/database/app_database.g.dart`: generado por Drift.
- `core/database/connection/`: conexion por plataforma.
  - IO: `NativeDatabase` con archivo `reading_tracker.sqlite`.
  - Web: `WebDatabase` con IndexedDB.
- `core/database/tables/books_table.dart`: tabla `books`.
- `core/database/tables/reading_sessions_table.dart`: tabla `reading_sessions`.
- `core/database/daos/book_dao.dart`: CRUD de libros.
- `core/database/daos/reading_session_dao.dart`: CRUD y queries por rango/dia.

Notas:

- `Book` de dominio no depende de Drift.
- `ReadingSession` de dominio no depende de Drift.
- Los mappers estan en capa `data`.
- Si se cambian tablas/DAOs, ejecutar build_runner.

## Books

Entidad:

- `features/books/domain/entities/book.dart`

Campos relevantes:

- Metadatos externos: `title`, `author`, `publisher`, `coverUrl`, `isbn`, `firstPublishYear`, `genre`, `language`.
- Datos del lector: `status`, `totalPages`, `currentPage`, `rating`, `notes`, `startDate`, `completedDate`, `createdAt`, `updatedAt`.

Flujo actual:

- Buscar libro por titulo/autor/ISBN en Open Library.
- Seleccionar resultado y guardar metadatos.
- Listar, filtrar por estado, abrir detalle, cambiar estado y eliminar.

Archivos clave:

- `features/books/data/datasources/book_api_datasource.dart`
- `features/books/data/mappers/book_mapper.dart`
- `features/books/data/repositories/book_repository_impl.dart`
- `features/books/presentation/providers/books_provider.dart`
- `features/books/presentation/screens/books_list_screen.dart`
- `features/books/presentation/screens/book_form_screen.dart`
- `features/books/presentation/screens/book_detail_screen.dart`

## Reading Sessions

Entidad:

- `features/reading_sessions/domain/entities/reading_session.dart`

Campos:

- `id`
- `bookId`
- `date`
- `minutes`
- `note`
- `createdAt`

Funcionalidad:

- Registrar minutos leidos por dia.
- Asociar sesiones a libros.
- Varias sesiones por libro y por dia.
- Consultar sesiones por dia o rango.

Archivos clave:

- `features/reading_sessions/data/mappers/reading_session_mapper.dart`
- `features/reading_sessions/data/repositories/reading_session_repository_impl.dart`
- `features/reading_sessions/presentation/providers/reading_sessions_provider.dart`
- `features/reading_sessions/presentation/screens/calendar_screen.dart`
- `features/reading_sessions/presentation/screens/day_detail_screen.dart`
- `features/reading_sessions/presentation/screens/session_form_screen.dart`

## Calendario

Estado actual:

- Vista mensual y semanal en `/calendar`.
- Navegacion por mes/semana.
- Cada dia muestra mini portadas de libros con sesiones.
- Vista mensual optimizada para mobile:
  - maximo 2 mini portadas por dia.
  - contador `+N` si hay mas libros.
  - celdas estables para evitar overflow.
- Detalle de dia muestra sesiones, total de minutos y permite navegar al libro.
- Formulario `/session/add` permite seleccionar libro, fecha, minutos y nota.

Pendientes UX:

- Mejorar jerarquia visual del calendario semanal.
- Pulir responsive en pantallas muy estrechas.
- Permitir editar/eliminar sesiones desde el detalle del dia.
- Mejorar textos/labels a un idioma consistente.
- Considerar bottom navigation si crecen las secciones.

## Seed Data

Archivo:

- `core/database/database_seed.dart`

Estado:

- Seed solo en debug usando `kDebugMode`.
- Inserta datos solo si la base esta vacia.
- Crea libros y sesiones de prueba.
- Usa IDs fijos y `insertOrIgnore` para evitar duplicados.
- Se dispara desde repositorios antes de lecturas/escrituras para evitar mezclar seed con UI.

## Decisiones tecnicas tomadas

- Mantener `domain` libre de Drift.
- Ubicar conversiones Drift en `data/mappers`.
- Mantener consultas SQL simples; combinar libros/sesiones en providers/UI por ahora.
- Usar `WebDatabase` para web por simplicidad; posible migracion futura a `WasmDatabase` con worker dedicado.
- Seed en infraestructura/repositorios, no en pantallas.
- No implementar backend, login ni JWT todavia.

## Comandos utiles

Ejecutar desde `reading_tracker`:

```powershell
C:\src\flutter\bin\flutter.bat pub get
C:\src\flutter\bin\flutter.bat analyze
C:\src\flutter\bin\flutter.bat test
C:\src\flutter\bin\flutter.bat build web
C:\src\flutter\bin\flutter.bat run -d chrome
```

Generar Drift:

```powershell
C:\src\flutter\bin\cache\dart-sdk\bin\dart.exe run build_runner build --delete-conflicting-outputs
```

Nota: `--delete-conflicting-outputs` puede aparecer como ignorado segun la version de build_runner actual.

## Verificacion reciente

Ultimas validaciones ejecutadas correctamente:

- `flutter analyze`: sin issues.
- `flutter test`: tests pasando.
- `flutter build web`: OK.

## Siguientes pasos recomendados

- Probar manualmente el calendario mensual en mobile y desktop.
- Registrar sesiones en varios dias y verificar persistencia tras refrescar.
- Implementar editar/eliminar sesiones.
- Mejorar vista semanal con una distribucion mas parecida a agenda.
- Anadir tests de repositorio/DAO para `ReadingSession`.
- Completar `stats` usando sesiones reales.
- Revisar migracion web futura a `WasmDatabase` si se quiere evitar `sql.js` legacy.

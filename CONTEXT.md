# Contexto del proyecto

## Resumen

Este repositorio contiene una app Flutter llamada `reading_tracker`, pensada para registrar libros y seguir su estado de lectura.

La app usa una arquitectura por capas y features:

- `lib/core`: infraestructura compartida, tema, base de datos y utilidades.
- `lib/features/books`: dominio, datos y presentacion de libros.
- `lib/features/stats`: calculo y UI de estadisticas.
- `test`: tests de Flutter.

## Stack principal

- Flutter / Dart
- Riverpod (`flutter_riverpod`) para estado e inyeccion de dependencias.
- Drift + SQLite para persistencia local.
- `path_provider` y `path` para ubicar el archivo de base de datos.
- `uuid` para generar identificadores.
- `intl` para formato de fechas.

## Entrada de la app

La entrada actual esta en `reading_tracker/lib/main.dart`.

`main.dart` crea un `ProviderScope` y monta `MyApp`, que configura un `MaterialApp` con:

- titulo `Reading Tracker`
- tema basado en `Colors.deepPurple`
- pantalla inicial `BooksListScreen`

Tambien existe `reading_tracker/lib/app.dart`, con rutas nombradas:

- `/`
- `/book/add`
- `/book/detail`

De momento `main.dart` no esta usando `App`, sino `MyApp`.

## Estructura relevante

### Core

- `reading_tracker/lib/core/database/app_database.dart`: configura Drift, SQLite y `BookDao`.
- `reading_tracker/lib/core/database/tables/books_table.dart`: tabla de libros.
- `reading_tracker/lib/core/database/daos/book_dao.dart`: operaciones de base de datos.
- `reading_tracker/lib/core/database/database_provider.dart`: provider de base de datos.
- `reading_tracker/lib/core/theme/app_theme.dart`: tema compartido.
- `reading_tracker/lib/core/utils/id_generator.dart`: generacion de IDs.
- `reading_tracker/lib/core/utils/date_formatter.dart`: formato de fechas.

### Books

- `reading_tracker/lib/features/books/presentation/screens/books_list_screen.dart`: listado principal.
- `reading_tracker/lib/features/books/presentation/screens/book_form_screen.dart`: formulario de libro.
- `reading_tracker/lib/features/books/presentation/screens/book_detail_screen.dart`: detalle de libro.
- `reading_tracker/lib/features/books/presentation/providers/books_provider.dart`: `AsyncNotifier` para cargar y mutar libros.
- `reading_tracker/lib/features/books/data/repositories/book_repository_impl.dart`: implementacion del repositorio con Drift.
- `reading_tracker/lib/features/books/domain/repositories/book_repository.dart`: contrato del repositorio.
- `reading_tracker/lib/features/books/domain/enums/book_status.dart`: estados `pending`, `reading`, `completed`.
- `reading_tracker/lib/features/books/domain/entities/book.dart`: entidad `Book`.

### Stats

- `reading_tracker/lib/features/stats/domain/stats_calculator.dart`: logica de estadisticas.
- `reading_tracker/lib/features/stats/presentation/providers/stats_provider.dart`: provider de estadisticas.
- `reading_tracker/lib/features/stats/presentation/screens/stats_screen.dart`: pantalla de estadisticas.
- `reading_tracker/lib/features/stats/presentation/widgets/stat_card.dart`: tarjeta de estadistica.

## Comandos utiles

Ejecutar desde `reading_tracker`:

```powershell
flutter pub get
flutter analyze
flutter test
flutter run
```

Para regenerar codigo de Drift:

```powershell
dart run build_runner build --delete-conflicting-outputs
```

## Notas para futuras tareas

- El README actual es el generado por defecto de Flutter; convendria reemplazarlo cuando la app este mas estable.
- Hay comentarios en algunos archivos que parecen tener problemas de codificacion, por ejemplo caracteres tipo `Ã` y `â`.
- Revisar consistencia de imports: algunos archivos leidos apuntan a `domain/models/...`, mientras la estructura actual listada usa `domain/entities/...` y `domain/enums/...`.
- `lib/app.dart` y `lib/main.dart` definen configuraciones de `MaterialApp` distintas. Conviene decidir una entrada unica para evitar divergencias.
- Drift usa `schemaVersion => 1`; cualquier cambio futuro en tablas deberia ir acompanado de migracion.

## Convenciones sugeridas

- Mantener la separacion `domain`, `data` y `presentation` dentro de cada feature.
- Evitar logica de base de datos directamente en widgets.
- Usar providers para exponer repositorios, notifiers y datos derivados.
- Mantener las entidades de dominio independientes de Drift.
- Antes de tocar persistencia, revisar tabla, DAO, repositorio y providers juntos.

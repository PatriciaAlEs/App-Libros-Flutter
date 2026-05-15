# Contexto del proyecto

## Resumen

Este repositorio contiene una app Flutter llamada `reading_tracker`, pensada para registrar libros y seguir su estado de lectura.

La app usa una arquitectura por capas y features:

- `lib/core`: infraestructura compartida, tema, base de datos y utilidades.
- `lib/features/books`: dominio, datos y presentacion de libros.
- `lib/features/stats`: calculo y UI de estadisticas.
- `test`: tests de Flutter.

## Stack principal

- Flutter / Dart.
- Riverpod (`flutter_riverpod`) para estado e inyeccion de dependencias.
- Drift y SQLite estan declarados en `pubspec.yaml`, pero la app esta conectada ahora con un DAO en memoria para poder continuar sin codigo generado.
- `uuid` para generar identificadores.
- `intl` esta declarado para formato de fechas.

## Entrada de la app

La entrada actual esta en `reading_tracker/lib/main.dart`.

`main.dart` crea un `ProviderScope` y monta `App`, definida en `reading_tracker/lib/app.dart`.

`App` configura un `MaterialApp` con:

- titulo `Reading Tracker`
- tema centralizado en `lib/core/theme/app_theme.dart`
- rutas nombradas `/`, `/book/add` y `/book/detail`

## Estructura relevante

### Core

- `reading_tracker/lib/core/database/app_database.dart`: contiene `AppDatabase` y `BookDao` en memoria.
- `reading_tracker/lib/core/database/database_provider.dart`: expone `databaseProvider` y `bookDaoProvider`.
- `reading_tracker/lib/core/database/tables/books_table.dart`: tabla Drift declarada, actualmente no conectada.
- `reading_tracker/lib/core/database/daos/book_dao.dart`: export de compatibilidad para `BookDao`.
- `reading_tracker/lib/core/theme/app_theme.dart`: tema compartido.
- `reading_tracker/lib/core/utils/id_generator.dart`: reservado para generacion de IDs.
- `reading_tracker/lib/core/utils/date_formatter.dart`: reservado para formato de fechas.

### Books

- `reading_tracker/lib/features/books/domain/entities/book.dart`: entidad `Book`.
- `reading_tracker/lib/features/books/domain/enums/book_status.dart`: estados `pending`, `reading`, `completed`.
- `reading_tracker/lib/features/books/domain/repositories/book_repository.dart`: contrato del repositorio.
- `reading_tracker/lib/features/books/data/repositories/book_repository_impl.dart`: implementacion del repositorio usando `BookDao`.
- `reading_tracker/lib/features/books/data/repositories/book_repository_provider.dart`: providers del repositorio.
- `reading_tracker/lib/features/books/presentation/providers/books_provider.dart`: `AsyncNotifier` para cargar y mutar libros.
- `reading_tracker/lib/features/books/presentation/screens/books_list_screen.dart`: listado principal.
- `reading_tracker/lib/features/books/presentation/screens/book_form_screen.dart`: formulario de libro.
- `reading_tracker/lib/features/books/presentation/screens/book_detail_screen.dart`: detalle de libro.
- `reading_tracker/lib/features/books/presentation/widgets/book_card.dart`: tarjeta de libro.
- `reading_tracker/lib/features/books/presentation/widgets/status_filter_bar.dart`: filtro por estado.

### Stats

Los archivos de stats existen, pero estan vacios todavia:

- `reading_tracker/lib/features/stats/domain/stats_calculator.dart`
- `reading_tracker/lib/features/stats/presentation/providers/stats_provider.dart`
- `reading_tracker/lib/features/stats/presentation/screens/stats_screen.dart`
- `reading_tracker/lib/features/stats/presentation/widgets/stat_card.dart`

## Comandos utiles

Ejecutar desde `reading_tracker`:

```powershell
flutter pub get
flutter analyze
flutter test
flutter run
```

Si se vuelve a conectar Drift como persistencia real:

```powershell
dart run build_runner build --delete-conflicting-outputs
```

## Estado actual

- La navegacion principal esta centralizada en `App`.
- `main.dart` ya no define otro `MaterialApp` paralelo.
- Los imports principales apuntan a `domain/entities` y `domain/enums`.
- El provider real de repositorio esta en `data/repositories/book_repository_provider.dart`.
- La app puede listar, crear, filtrar, abrir detalle, cambiar estado y eliminar libros durante la sesion.
- La persistencia es temporal en memoria; al cerrar la app se pierden los libros.
- **Flutter 3.44.0 (master) instalado en `c:\src\flutter` y añadido al PATH del sistema.**
- **Dart SDK está disponible con Flutter.**
- Las dependencias del proyecto están actualizadas en `pubspec.lock`.

## Siguientes pasos recomendados

- ✓ **Flutter instalado**: Reinicia el terminal o VS Code para que los cambios de PATH tomen efecto.
- Ejecutar `flutter analyze` y `flutter test` para validar el código.
- Decidir si la siguiente fase mantiene DAO en memoria temporalmente o reconecta Drift con codigo generado.
- Completar stats cuando el flujo de libros este estable.
- Instalar Android SDK y/o Visual Studio si necesitas compilar para Android o Windows respectivamente.
- Reemplazar el README generado por defecto.

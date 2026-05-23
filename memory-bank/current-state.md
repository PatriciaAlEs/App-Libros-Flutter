# Current State

## Producto

`reading_tracker` es una app Flutter mobile-first para registrar libros, sesiones de lectura, progreso, calendario y estadisticas basicas.

La Home ya funciona como dashboard principal. Actualmente ofrece:

- Card/CTA "Anadir nuevo libro".
- Seccion "Lectura actual" con todos los libros en estado `Leyendo`.
- Registro rapido de avance desde cada lectura actual.
- Resumen rapido de lectura.
- Actividad reciente del dia actual.
- Sugerencias de pendientes cuando no hay lecturas activas.

## UX Home

Estado actual implementado:

- Si existen varios libros en estado `Leyendo`, Home muestra una card por libro.
- Si no hay libros en estado `Leyendo`, Home muestra sugerencias de libros pendientes.
- Las sugerencias de pendientes priorizan libros mas antiguos usando la fecha disponible de alta/creacion.
- La card de lectura actual muestra progreso cuando hay `currentPage` y `totalPages`.
- Si falta `totalPages`, se muestra una accion clara: "Anadir total de paginas".
- El registro rapido desde Home usa un dialogo centrado, no bottom sheet.
- El dialogo mantiene campos de pagina actual, paginas leidas y minutos.
- El dialogo permite guardar cambios o ir al detalle completo del libro.
- El contenido del dialogo es scrollable para evitar overflow en movil.
- La card "Anadir nuevo libro" es la entrada principal para anadir libros desde Home.
- El FAB/boton redundante de anadir libro fue eliminado.

## Actividad reciente

Estado actual implementado:

- El registro rapido desde Home crea una `ReadingSession` cuando `pagesRead > 0` o `minutes > 0`.
- Se reutiliza el repositorio/provider existente de sesiones.
- Tras guardar, se refresca el provider usado por la actividad reciente.
- Home muestra solo actividad del dia actual.
- Las sesiones se ordenan por `createdAt` descendente.
- Si hay varias sesiones hoy, aparecen dentro de un contenedor con altura maxima y scroll interno.
- Empty state actual: "Aun no hay actividad hoy. Registra una sesion para ver tu ritmo de lectura."

## Libros y progreso

Estado actual implementado:

- Al crear libro se puede introducir `totalPages`.
- Al seleccionar un resultado de Open Library, `totalPages` se autorrellena si llega `number_of_pages` o `number_of_pages_median`.
- El campo `totalPages` sigue siendo editable manualmente aunque venga de Open Library.
- En detalle se pueden editar paginas.
- Desde Home se puede anadir `totalPages` cuando falta.
- `Book` ya tenia campos compatibles para `totalPages`, `currentPage` y `rating`; no fue necesario cambiar el modelo.
- La valoracion final al completar lectura permite decimales con pasos de `0.25`.

## Ciclo de vida del libro

Estado actual implementado:

- Estados soportados: `pending`, `reading`, `completed`, `paused` y `abandoned`.
- Etiquetas visibles: Pendiente, Leyendo, Completado, Pausado y Abandonado.
- `addedAt` representa cuando se anadio el libro a la app.
- `startedAt` y `finishedAt` se exponen como fechas de lectura editables.
- Persistencia reutiliza los campos existentes `createdAt`, `startDate` y `completedDate`.
- En el formulario de alta aparecen fechas cuando el estado inicial lo requiere.
- En detalle se pueden editar manualmente fecha de inicio y fecha de finalizacion.

## Biblioteca y navegacion

Estado actual implementado:

- Biblioteca usa un icono de libros.
- La vista general de Biblioteca muestra primero libros en estado `Leyendo`.
- Despues se muestran el resto de estados.
- Se mantienen filtros/tabs existentes y la opcion de ver todos.
- Cada card muestra estado visual del libro.
- Los libros en lectura muestran progreso si tienen `currentPage` y `totalPages`.
- Los libros completados muestran rating si estan valorados.

## Validacion

Validaciones pendientes de ejecutar por el usuario:

```bash
dart format lib/features/books/data/datasources/book_api_datasource.dart lib/features/books/domain/entities/book.dart lib/features/books/domain/entities/book_search_result.dart lib/features/books/domain/enums/book_status.dart lib/features/books/presentation/screens/book_detail_screen.dart lib/features/books/presentation/screens/book_form_screen.dart lib/features/books/presentation/widgets/book_card.dart test/widget_test.dart
flutter analyze
flutter test
```

## Siguiente paso recomendado

1. Usuario ejecuta formato, tests y analisis.
2. Revisar cualquier fallo que aparezca.
3. Si todo esta correcto, cerrar el sprint de ciclo de vida del libro.
4. Continuar con Stats MVP o el siguiente bloque que priorice el usuario.

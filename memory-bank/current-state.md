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
- En detalle se pueden editar paginas.
- Desde Home se puede anadir `totalPages` cuando falta.
- `Book` ya tenia campos compatibles para `totalPages`, `currentPage` y `rating`; no fue necesario cambiar el modelo.
- La valoracion final al completar lectura permite decimales con pasos de `0.25`.

## Biblioteca y navegacion

Estado actual implementado:

- Biblioteca usa un icono de libros.
- La vista general de Biblioteca muestra primero libros en estado `Leyendo`.
- Despues se muestran el resto de estados.
- Se mantienen filtros/tabs existentes y la opcion de ver todos.

## Validacion

Validaciones pendientes de ejecutar por el usuario:

```bash
dart format lib/features/books/presentation/screens/book_form_screen.dart lib/features/books/presentation/screens/book_detail_screen.dart lib/features/books/presentation/screens/books_list_screen.dart lib/features/home/presentation/screens/home_screen.dart test/widget_test.dart
flutter analyze
flutter test
```

## Siguiente paso recomendado

1. Usuario ejecuta formato, analisis y tests.
2. Revisar cualquier fallo que aparezca.
3. Revisar `git status` y `git diff`.
4. Si todo esta correcto, cerrar Sprint UX Home.
5. Continuar con Stats MVP o el siguiente bloque que priorice el usuario.

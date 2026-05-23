# Progress

## Completado

- Base Flutter creada para `reading_tracker`.
- Arquitectura por features con dominio, data y presentation.
- Riverpod configurado para estado e inyeccion.
- Persistencia Drift + SQLite.
- Modelos principales de libros y sesiones.
- Pantalla de libros / Biblioteca.
- Detalle de libro.
- Formulario de alta/edicion de libro.
- Registro de sesiones de lectura.
- Calendario de lectura.
- Estadisticas basicas iniciales.
- Busqueda con Open Library.
- Open Library autorrellena `totalPages` con `number_of_pages` o `number_of_pages_median` cuando estan disponibles.
- `totalPages` permanece editable manualmente.
- Estados de libro ampliados con `paused` y `abandoned`.
- Fechas de lectura `startedAt` y `finishedAt` editables manualmente desde detalle.
- Formulario de alta muestra fechas cuando el estado inicial lo requiere.
- Biblioteca muestra estado, progreso en libros en lectura y rating en completados valorados.
- Home convertida en dashboard principal.
- CTA/card "Anadir nuevo libro" en Home.
- Eliminado FAB/boton redundante de anadir libro.
- Lectura actual muestra multiples libros en estado `Leyendo`.
- Registro rapido desde Home en dialogo centrado.
- Registro rapido crea sesiones cuando hay paginas o minutos.
- Actividad reciente muestra acciones registradas desde Home.
- Actividad reciente de Home limitada al dia actual.
- Actividad reciente ordenada por `createdAt` descendente.
- Actividad reciente contenida con scroll interno.
- Soporte para introducir `totalPages` al crear libro.
- Edicion de paginas desde detalle.
- Accion "Anadir total de paginas" desde Home cuando falta `totalPages`.
- Progreso visible como porcentaje y "Pagina X de Y" cuando hay datos suficientes.
- Valoracion final con decimales en pasos de `0.25`.
- Biblioteca con icono de libros.
- Biblioteca ordena primero libros en estado `Leyendo` en la vista general.
- Tests ajustados para el formulario con multiples campos de texto.
- Test de estado inicial ajustado para hacer visible "Guardar libro" antes de tocarlo.

## Parcial / en seguimiento

- Validacion final del Sprint UX Home pendiente en terminal del usuario.
- Validacion final del sprint de ciclo de vida del libro pendiente en terminal del usuario.
- Revisión de textos y consistencia visual fina pendiente para el sprint visual/UI.
- Stats MVP queda como siguiente bloque funcional despues de cerrar Home.
- Open Library puede mejorar resultados en espanol, pero queda para una fase posterior.

## Pendiente inmediato

El usuario debe ejecutar:

```bash
dart format lib/features/books/data/datasources/book_api_datasource.dart lib/features/books/domain/entities/book.dart lib/features/books/domain/entities/book_search_result.dart lib/features/books/domain/enums/book_status.dart lib/features/books/presentation/screens/book_detail_screen.dart lib/features/books/presentation/screens/book_form_screen.dart lib/features/books/presentation/widgets/book_card.dart test/widget_test.dart
flutter test
flutter analyze
```

## Pendiente futuro

- Cerrar sprint de ciclo de vida del libro tras validacion.
- Continuar con Stats MVP.
- Investigar Open Library para mejorar resultados en espanol.
- Hacer sprint visual/UI: paleta, estilo, referencias y design system.
- Ampliar tests de flujos criticos si el alcance del siguiente sprint lo requiere.

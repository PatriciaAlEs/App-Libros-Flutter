# Requisitos de Producto: reading_tracker

## 1. Nombre del producto

`reading_tracker`

## 2. Descripcion breve

`reading_tracker` es una app Flutter mobile-first para seguimiento personal de lectura. Permite registrar libros, gestionar su estado, anotar sesiones de lectura, visualizar actividad en calendario y consultar estadisticas basicas.

## 3. Problema que resuelve

Las personas lectoras suelen tener libros pendientes, lecturas activas y progreso repartido en varios titulos. La app centraliza ese seguimiento y ayuda a ver habitos de lectura por dia sin configurar una herramienta compleja.

## 4. Usuarios objetivo

- Lectores individuales que quieren organizar su biblioteca personal.
- Personas que quieren saber cuanto leen y en que dias mantienen actividad.
- Usuarios que prefieren una experiencia sencilla, rapida y pensada para movil.

## 5. Objetivo del MVP

Crear una app sencilla y mantenible para registrar libros y sesiones de lectura, visualizar la actividad en calendario y ofrecer estadisticas basicas a partir de los datos guardados.

## 6. Funcionalidades incluidas en el MVP

- Libros:
  - Buscar libros por titulo, autor o ISBN usando Open Library.
  - Guardar metadatos del libro.
  - Listar libros.
  - Ver detalle de libro.
  - Cambiar estado entre `pending`, `reading` y `completed`.
  - Eliminar libros.
- Sesiones de lectura:
  - Registrar sesiones asociadas a libros en estado `reading`.
  - Guardar fecha, minutos leidos y nota opcional.
  - Persistir sesiones con Drift + SQLite.
- Calendario:
  - Vista mensual compacta.
  - Vista semanal con mas detalle diario.
  - Detalle de dia con sesiones, portadas, titulos, notas y total de minutos.
- Estadisticas:
  - Seccion parcialmente implementada.
  - Debe cerrarse funcionalmente con datos reales, copy final y comportamiento validado antes de considerarse completa.

## 7. Funcionalidades fuera del MVP

- Backend propio.
- Login, JWT o sincronizacion entre usuarios.
- Recomendaciones avanzadas.
- Funciones sociales.
- Exportacion/importacion de biblioteca.
- Analiticas avanzadas.
- Arquitectura empresarial o capas innecesarias para el tamano actual.

## 8. Flujos principales de usuario

### Alta de libro

1. El usuario abre el listado de libros.
2. Pulsa anadir libro.
3. Busca por titulo, autor o ISBN.
4. Selecciona un resultado.
5. La app guarda el libro y lo muestra en el listado.

### Cambio de estado

1. El usuario abre el detalle de un libro.
2. Cambia su estado a `pending`, `reading` o `completed`.
3. La app persiste el cambio.

### Registro de sesion

1. El usuario abre calendario o detalle de dia.
2. Pulsa anadir sesion.
3. Selecciona un libro en estado `reading`.
4. Confirma fecha, minutos y nota opcional.
5. La app guarda la sesion y actualiza calendario/detalle.

### Revision de calendario

1. El usuario abre `/calendar`.
2. Alterna entre mes y semana.
3. Toca un dia.
4. Revisa sesiones, total de minutos y libros asociados.

### Consulta de estadisticas

1. El usuario abre Stats.
2. La app muestra metricas basicas desde libros y sesiones.
3. Pendiente: cerrar funcionalmente esta seccion antes de considerarla completa.

## 9. Modelo de datos resumido

### Book

Representa un libro guardado por el usuario.

Campos principales:

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

Estados permitidos:

- `pending`
- `reading`
- `completed`

### ReadingSession

Representa una sesion de lectura asociada a un libro.

Campos:

- `id`
- `bookId`
- `date`
- `minutes`
- `note`
- `createdAt`

Relaciones:

- Un libro puede tener muchas sesiones.
- Una sesion pertenece a un libro.
- Un dia puede contener varias sesiones y varios libros.

## 10. Requisitos no funcionales

- Mobile-first: la experiencia principal debe funcionar bien en pantallas pequenas.
- Mantenible: preferir soluciones simples, locales y alineadas con la arquitectura actual.
- Persistencia real: libros y sesiones deben guardarse con Drift + SQLite.
- Offline-first local: el uso principal no debe depender de backend propio.
- Estados claros: mostrar carga, error y empty states cuando corresponda.
- Validacion: los minutos de lectura deben ser mayores que 0.
- Arquitectura limpia sin sobredimensionar:
  - `domain` libre de Drift.
  - mappers en `data/mappers`.
  - estado con Riverpod.
  - UI en `presentation`.

## 11. Criterios de aceptacion

- El usuario puede buscar y guardar un libro.
- El usuario puede ver sus libros en un listado.
- El usuario puede cambiar el estado de un libro.
- El usuario puede registrar una sesion solo para libros en estado `reading`.
- El formulario de sesion rechaza minutos vacios, invalidos o menores/iguales a 0.
- Al guardar una sesion, esta aparece en el calendario y en el detalle del dia.
- El detalle de dia muestra portada, titulo, minutos y nota opcional por sesion.
- El detalle de dia muestra el total de minutos leidos.
- Si no hay sesiones en un dia, se muestra un empty state claro.
- Los datos persisten tras cerrar o refrescar la app.
- Stats aparece como seccion parcialmente implementada hasta cerrar su comportamiento final.

## 12. Backlog priorizado

### Alta prioridad

- Editar y eliminar sesiones desde el detalle de dia.
- Cerrar `stats` con datos reales, copy final y comportamiento validado.
- Revisar textos y acentos para una experiencia consistente en espanol.

### Media prioridad

- Verificar manualmente persistencia completa: libro en lectura -> sesion -> calendario -> refresh.
- Anadir tests de repositorio/DAO para sesiones.
- Anadir tests de calculos de stats con casos reales.
- Mejorar responsive en pantallas muy estrechas.
- Mejorar empty states con acciones contextuales.

### Baja prioridad

- Considerar bottom navigation si crecen las secciones.
- Evaluar migracion web a `WasmDatabase` si `WebDatabase` legacy limita el proyecto.
- Pulir visualmente el calendario semanal.

## 13. Prompt usado con IA para generar/refinar requisitos

```text
Usando el contexto del proyecto reading_tracker, genera un documento de requisitos de producto para el MVP.

Contexto:
- Es una app Flutter mobile-first para seguimiento personal de lectura.
- Debe permitir registrar libros, sesiones de lectura, progreso, calendario y estadisticas.
- Usa Riverpod para estado y Drift + SQLite para persistencia.
- La arquitectura debe ser simple, mantenible y sin sobredimensionar.
- La seccion Stats esta parcialmente implementada y no debe marcarse como cerrada.

Incluye:
1. Nombre del producto.
2. Descripcion breve.
3. Problema que resuelve.
4. Usuarios objetivo.
5. Objetivo del MVP.
6. Funcionalidades incluidas y fuera del MVP.
7. Flujos principales de usuario.
8. Modelo de datos resumido.
9. Requisitos no funcionales.
10. Criterios de aceptacion.
11. Backlog priorizado.
12. Conclusion.

Redacta en castellano, de forma clara, profesional y no excesivamente larga.
No inventes funcionalidades no presentes en el contexto.
```

## 14. Conclusion

`reading_tracker` tiene una base solida para un MVP de seguimiento de lectura: libros, sesiones y calendario ya forman el flujo principal. El siguiente paso de producto es cerrar las operaciones pendientes sobre sesiones y terminar Stats con datos reales, manteniendo el enfoque mobile-first y la arquitectura simple que ya existe.

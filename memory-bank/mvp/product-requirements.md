> ENTREGABLE ACADEMICO: Este documento se conserva como entrega del proyecto de requisitos MVP. El PRD vivo del proyecto esta en memory-bank/product-requirements.md.

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
  - Cambiar estado entre `pending`, `reading`, `completed`, `paused` y `abandoned`.
  - Eliminar libros.
- Sesiones de lectura:
  - Registrar sesiones asociadas a libros en estado `reading`.
  - Guardar fecha, minutos leidos, paginas leidas (`pagesRead`) y nota opcional.
  - Persistir sesiones con Drift + SQLite.
- Calendario:
  - Vista mensual compacta.
  - Vista semanal con mas detalle diario.
  - Detalle de dia con sesiones, portadas, titulos, notas y total de minutos.
- Estadisticas:
  - Seccion implementada con datos reales desde libros y sesiones.
  - Incluye resumen de progreso, actividad, objetivo anual, rachas y ritmo de lectura.
- Insights:
  - Hito 4 Sprint 1, Sprint 2 y Sprint 3 implementados y validados.
  - Hito 4 Sprint 4 implementado y pendiente de validacion local.
  - Sprint 1: muestra libro mas leido, autor mas leido y genero favorito.
  - Sprint 2: muestra ritmo de lectura, prediccion simple de fin de libro y forecast anual cuando hay datos suficientes.
  - Sprint 3: muestra Top Lecturas del Año y Ranking Personal.
  - Sprint 4: reorganiza Insights como perfil lector premium con mejores lecturas y curiosidades.
  - Usa paginas leidas acumuladas desde `ReadingSession.pagesRead`.
  - No incluye IA, servicios externos ni tablas nuevas.
- Navegacion principal:
  - Hito 5 Sprint 1 implementado.
  - Tabs Inicio, Biblioteca, Progreso, Insights y Ajustes.
  - Progreso da acceso a Estadisticas, Reading Challenge y Activity Tracking.
  - Ajustes permite elegir tema Burgundy o Forest con preferencia persistida localmente.
  - No incluye autenticacion ni perfil real.
- Design System:
  - Hito 5 Sprint 2 implementado.
  - Tema Burgundy por defecto y tema Forest seleccionable.
  - Tokens visuales de spacing, radios, elevaciones y sombras suaves.
  - Componentes base reutilizables: `MetricCard`, `InsightCard`, `ProgressCard`, `SectionHeader` y `EmptyStateCard`.
  - No redisenia todavia pantallas completas.

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
2. Cambia su estado a `pending`, `reading`, `completed`, `paused` o `abandoned`.
3. La app persiste el cambio.

### Registro de sesion

1. El usuario abre calendario o detalle de dia.
2. Pulsa anadir sesion.
3. Selecciona un libro en estado `reading`.
4. Confirma fecha, minutos, paginas leidas y nota opcional.
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
- `paused`
- `abandoned`

### ReadingSession

Representa una sesion de lectura asociada a un libro.

Campos:

- `id`
- `bookId`
- `date`
- `minutes`
- `pagesRead`
- `note`
- `createdAt`
- `updatedAt`

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
- Stats aparece como seccion implementada con datos reales.
- Insights aparece como seccion implementada con Sprint 1, Sprint 2, Sprint 3 y Sprint 4: perfil lector, mejores lecturas y curiosidades.
- Navegacion principal muestra Inicio, Biblioteca, Progreso, Insights y Ajustes como secciones de primer nivel.
- Ajustes permite seleccionar y conservar localmente el tema visual.

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
- La seccion Stats esta implementada con datos reales.
- La seccion Insights esta implementada para Hito 4 Sprint 1, Sprint 2, Sprint 3 y Sprint 4 como perfil lector premium.

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

`reading_tracker` tiene una base solida para un MVP de seguimiento de lectura: libros, sesiones, calendario, estadisticas e insights ya forman el flujo principal. Los siguientes pasos deben mantener el enfoque mobile-first y la arquitectura simple que ya existe.

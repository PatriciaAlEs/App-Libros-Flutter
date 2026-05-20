# User Flows

## Alta de libro

1. Usuario abre listado de libros.
2. Pulsa anadir libro.
3. Busca por titulo, autor o ISBN.
4. Selecciona un resultado de Open Library.
5. La app guarda metadatos y muestra el libro en el listado.

## Cambiar estado de libro

1. Usuario abre detalle de libro.
2. Cambia estado entre `pending`, `reading` y `completed`.
3. La app persiste el cambio.

## Registrar sesion

1. Usuario abre calendario o detalle de dia.
2. Pulsa anadir sesion.
3. Selecciona un libro en estado `reading`.
4. Confirma fecha, minutos y nota opcional.
5. La app guarda en Drift y actualiza calendario/detalle.

## Revisar calendario

1. Usuario abre `/calendar`.
2. Alterna entre mes y semana.
3. Toca un dia para ver detalle.
4. Revisa sesiones, total de minutos y libros asociados.

## Consultar estadisticas

1. Usuario abre Stats.
2. La app muestra un resumen calculado desde libros y sesiones.
3. Usuario ve metricas utiles para entender progreso y habitos.

Estado: parcialmente implementado; pendiente cerrar funcionalmente antes de considerar Stats completo.

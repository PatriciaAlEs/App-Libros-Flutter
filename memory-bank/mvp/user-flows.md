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

1. Usuario abre Progreso.
2. Pulsa Estadisticas.
3. La app muestra un resumen calculado desde libros y sesiones.
4. Usuario ve metricas utiles para entender progreso y habitos.

Estado: implementado con datos reales.

## Navegar secciones principales

1. Usuario usa la navegacion inferior.
2. Cambia directamente entre Inicio, Biblioteca, Progreso, Insights y Ajustes.
3. La app mantiene rutas internas para detalle, formularios, calendario y estadisticas.

Estado: Hito 5 Sprint 1 implementado y pendiente de validacion local.

## Seleccionar tema visual

1. Usuario abre Ajustes desde la navegacion inferior.
2. Selecciona Burgundy o Forest.
3. La app aplica el tema y conserva la preferencia localmente.

Estado: Hito 5 Sprint 2 implementado y pendiente de validacion local.

## Usar Home Premium

1. Usuario abre Inicio.
2. Ve su lectura actual como bloque principal con portada, progreso y CTA.
3. Consulta racha, completados del ano, paginas leidas y objetivo lector.
4. Revisa hasta 3 sesiones recientes o abre `Ver actividad`.
5. Usa el FAB para anadir un libro.

Estado: Hito 5 Sprint 3 implementado y pendiente de validacion local.

## Consultar insights

1. Usuario abre Insights.
2. La app muestra perfil lector, mejores lecturas y curiosidades.
3. Usuario ve estos insights cuando existen sesiones, libros en lectura o completados del ano con datos suficientes.

Estado: Hito 4 Sprint 1, Sprint 2 y Sprint 3 implementados y validados; Sprint 4 implementado y pendiente de validacion local.

- Sprint 1: libro mas leido, autor mas leido y genero favorito.
- Sprint 2: ritmo de lectura, prediccion de fin de libro y forecast anual.
- Sprint 3: Top Lecturas del Año y Ranking Personal.
- Sprint 4: perfil lector premium con `Tu perfil lector`, `Tus mejores lecturas` y `Curiosidades`.

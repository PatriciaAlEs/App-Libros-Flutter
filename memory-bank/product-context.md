# Product Context

## Problema

Las personas lectoras suelen tener libros pendientes, lecturas activas y progreso repartido en varios titulos. `reading_tracker` centraliza ese seguimiento y permite ver habitos de lectura por dia.

## Usuario objetivo

Usuario individual que quiere registrar su biblioteca personal y entender cuanto lee, sin configurar una herramienta compleja.

## Casos de uso principales

- Buscar un libro y guardarlo con metadatos remotos, usando Open Library como fuente primaria y Google Books como fallback.
- Anadir un libro manualmente como ultima opcion cuando la busqueda no responde o no encuentra resultados.
- Evitar duplicados aunque el libro venga de API, alta manual o una fuente futura.
- Marcar libros como `pending`, `reading`, `completed`, `paused` o `abandoned`.
- Registrar una sesion de lectura con fecha, minutos, paginas leidas y nota opcional.
- Ver en calendario que dias tuvo actividad.
- Abrir un dia concreto y revisar las sesiones registradas.
- Consultar estadisticas simples de progreso y actividad.
- Consultar un perfil lector con mejores lecturas y curiosidades.
- Acceder a secciones principales desde navegacion inferior.

## Experiencia deseada

- Rapida de usar con una mano.
- Formularios cortos y claros.
- Calendario compacto en mes y mas detallado en semana/dia.
- Navegacion principal clara y accesible.
- Estados vacios utiles, con llamadas a la accion cuando proceda.
- Visualmente consistente con Biblioteca como pantalla de referencia.
- Local-first: debe seguir funcionando con datos locales aunque la conectividad sea limitada.

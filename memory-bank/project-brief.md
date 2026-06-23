# Project Brief

## Producto

`reading_tracker` es una app Flutter para seguimiento personal de lectura. El objetivo del MVP es permitir registrar libros, gestionar su estado de lectura, registrar sesiones, visualizar actividad en calendario, consultar estadisticas basicas y ver insights de lectura.

## Principios

- Mobile-first: la experiencia principal debe funcionar bien en pantallas pequenas.
- Mantenible y sencillo: preferir soluciones directas, con poco acoplamiento y sin arquitectura sobredimensionada.
- Persistencia real: los datos principales se guardan con Drift + SQLite.
- IA con control tecnico: los asistentes pueden acelerar tareas, pero deben respetar la arquitectura existente, explicar cambios y evitar refactors innecesarios.

## Alcance del MVP

- Libros: busqueda/alta, listado, detalle, estado, progreso y eliminacion.
- Sesiones de lectura: crear sesiones por libro y dia, con minutos y nota opcional.
- Calendario: vista mensual, vista semanal y detalle de dia.
- Estadisticas: resumen basico a partir de libros y sesiones reales.
- Insights: perfil lector, mejores lecturas y curiosidades a partir de datos reales.
- Navegacion principal: tabs Inicio, Biblioteca, Progreso, Insights y Ajustes.
- Design System: temas Burgundy/Forest, tokens visuales y componentes reutilizables.
- Branding: identidad ReadPp, tipografia Playfair/Inter, iconografia centralizada y motion base.
- Home Premium: lectura actual protagonista, metricas compactas, objetivo anual y actividad reciente.
- Alpha QA: shared header basado en Biblioteca, card compartida de lectura actual, carrusel de multiples lecturas activas, calendario/diario sincronizados, polish de reto lector/insights y QA manual previo a release completado.
- Busqueda de libros: Open Library como proveedor primario, Google Books como fallback, alta manual como ultima opcion y deduplicacion por ISBN, proveedor+externalId o titulo+autor normalizados.
- Release alpha: ReadPp v0.2.0-alpha completada con APK Release generada, Web desplegada en Vercel, testers externos activos, 67/67 tests y `flutter analyze` OK.

## Fuera de alcance por ahora

- Backend propio.
- Login, JWT o sincronizacion entre usuarios.
- Social, recomendaciones avanzadas o gamificacion compleja.
- Arquitecturas pesadas que no aporten valor inmediato al MVP.

## Roadmap vigente

- Resolver QA-018, QA-019, QA-020, QA-021 y QA-022 detectadas tras la salida alpha.
- v0.3 Observabilidad.
- v0.4 Google Books fallback robustecido.
- v0.5 Supabase para Auth, backend cloud y sincronizacion multi-dispositivo manteniendo persistencia local.

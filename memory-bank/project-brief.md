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

## Fuera de alcance por ahora

- Backend propio.
- Login, JWT o sincronizacion entre usuarios.
- Social, recomendaciones avanzadas o gamificacion compleja.
- Arquitecturas pesadas que no aporten valor inmediato al MVP.

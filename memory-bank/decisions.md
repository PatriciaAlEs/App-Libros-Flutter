# Decisions

## Decisiones tecnicas

- Usar Flutter/Dart para una app mobile-first con posible ejecucion web.
- Usar Riverpod para estado e inyeccion de dependencias.
- Usar Drift + SQLite para persistencia real.
- Usar `WebDatabase` sobre IndexedDB en web por simplicidad inicial.
- Mantener dominio libre de Drift.
- Ubicar conversiones Drift en `data/mappers`.
- Mantener consultas SQL simples y combinar datos en providers/UI cuando el coste sea bajo.
- Usar seed data solo en debug y solo si la base esta vacia.

## Decisiones de producto

- Priorizar registro de libros, sesiones, calendario y estadisticas basicas.
- No implementar backend, login ni JWT por ahora.
- Mantener UX mobile-first.
- Evitar complejidad prematura.

## Decisiones de trabajo con IA

- Leer contexto antes de editar.
- Explicar archivos tocados y validaciones.
- No hacer refactors amplios salvo peticion explicita.
- Tratar `Stats` como area separada: no tocarla en tareas de calendario/sesiones salvo que se pida.

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
- El usuario ejecuta `dart format`, `flutter analyze` y `flutter test` en su terminal de VS Code salvo peticion explicita en contrario.
- No hacer commit ni push automaticamente.
- No revisar `git status` ni `git diff` salvo que el usuario lo pida explicitamente.
- No confiar solo en resumen conversacional; verificar archivos modificados.
- Mantener cambios pequenos y acotados por problema.
- No tocar Open Library, modelos ni persistencia salvo que el requisito lo pida claramente.
- La base nueva de Estadisticas MVP se calcula desde `Book` y no usa `ReadingSession` hasta un sprint posterior.
- La logica de calculo de estadisticas debe vivir fuera de widgets y pantallas.
- La UI futura debe consumir estadisticas desde un punto unico: `statisticsSummaryProvider`.
- La pantalla `/stats` debe permanecer simple en MVP: tarjetas basicas, sin charts, objetivos, rachas ni sesiones hasta nuevos sprints.
- Las mutaciones de libros deben invalidar `statisticsSummaryProvider` ademas de cualquier provider legacy de Stats mientras convivan ambas rutas.

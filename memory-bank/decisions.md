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
- La base nueva de Estadisticas MVP se calcula principalmente desde `Book`; las rachas se calculan desde `ReadingSession` sin crear tablas ni entidades nuevas.
- La logica de calculo de estadisticas debe vivir fuera de widgets y pantallas.
- La UI futura debe consumir estadisticas desde un punto unico: `statisticsSummaryProvider`.
- La pantalla `/stats` debe permanecer simple en MVP: tarjetas basicas, sin charts, badges, notificaciones ni gamificacion avanzada.
- Las mutaciones de libros deben invalidar `statisticsSummaryProvider` ademas de cualquier provider legacy de Stats mientras convivan ambas rutas.
- El objetivo anual se persiste en una tabla simple `app_settings` gestionada por Drift con SQL manual, sin paquetes externos.
- El progreso anual usa solo libros `completed` con `finishedAt/completedDate` dentro del ano actual.
- Al entrar en estado `completed`, la app debe ofrecer valoracion y resena opcional; la resena se guarda en `Book.notes`.
- Las fechas de lectura deben mantener un rango valido: `finishedAt` no puede ser anterior a `startedAt`.
- La busqueda Open Library en alta debe mostrar pocos resultados inicialmente y permitir cargar mas para no empujar demasiado el CTA de guardado.
- Hito 3 debe reutilizar la entidad existente `ReadingSession` como base de "ratos de lectura"; no crear una entidad paralela mientras esta cubra el concepto principal.
- Antes de usar sesiones para estadisticas avanzadas, rachas y actividad, consolidar campos estructurados minimos como `pagesRead` y `updatedAt`.
- Registrar sesiones nuevas debe pasar por `RegisterReadingSession`, que centraliza crear la sesion y actualizar el progreso del libro.
- Las sesiones de lectura pueden registrarse en fechas pasadas o en la fecha actual, pero no en fechas futuras.
- Al registrar una sesion que haga llegar el progreso a `totalPages`, no completar automaticamente el libro sin confirmacion; si el usuario confirma, marcar como `completed`, fijar `finishedAt/completedDate` si estaba vacio y ofrecer valoracion/resena opcional.
- Las rachas se basan en dias con al menos una `ReadingSession`; hoy mantiene racha activa, ayer tambien si hoy aun no tiene sesion, y cualquier otro ultimo dia activo da racha actual 0.
- La mejor racha historica se calcula con la secuencia maxima de dias consecutivos con sesiones, ignorando hora y duplicados del mismo dia.

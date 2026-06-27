# Sprint 21.6 - Modelo remoto Supabase + RLS

## Estado

Implementado en repositorio. Pendiente de aplicar y validar contra un proyecto Supabase real.

## Alcance

Este sprint prepara el modelo remoto para futura sincronizacion. No sincroniza datos y no cambia el comportamiento local de ReadPp.

Drift sigue siendo la fuente principal de datos.

## Migracion SQL

Archivo:

- `supabase/migrations/202606270001_remote_data_model.sql`

Tablas creadas:

- `profiles`
- `books`
- `reading_sessions`
- `annual_goals`

Todas las tablas incluyen:

- `created_at`
- `updated_at`
- `deleted_at`

`deleted_at` queda preparado para soft delete e incremental sync, pero la app no lo usa todavia.

## Identificadores

Las entidades sincronizables usan un UUID remoto como clave primaria:

- `books.id`
- `reading_sessions.id`
- `annual_goals.id`

Los IDs locales se conservan como columnas separadas:

- `books.local_book_id`
- `reading_sessions.local_session_id`
- `reading_sessions.local_book_id`
- `annual_goals.local_goal_id`

`profiles.id` coincide con `auth.users.id`.

## RLS

RLS queda habilitado en todas las tablas.

Politicas minimas:

- `SELECT`
- `INSERT`
- `UPDATE`
- `DELETE`

Regla general:

- `auth.uid() = user_id`

Regla para `profiles`:

- `auth.uid() = id`

No se crean politicas abiertas.

## Flutter

Se crea `features/sync` con:

- entidades remotas;
- DTOs remotos;
- mappers DTO <-> entidad;
- contratos de repositorio remoto;
- contrato base de datasource remoto;
- constantes de tablas remotas.

No se implementa ningun repositorio concreto de Supabase en este sprint.

## Validacion local

- `flutter analyze` OK.
- `flutter test` OK.

## Limitaciones

- La migracion SQL no fue aplicada contra Supabase desde esta ejecucion.
- Las politicas RLS requieren validacion con usuarios reales en un proyecto Supabase.
- No existe aun mapeo persistente local-remoto en Drift.
- No existe resolucion de conflictos.
- No existe sync local -> nube ni nube -> local.

## Siguiente paso recomendado

Sprint 21.7: aplicar la migracion en Supabase, validar RLS con usuarios reales y disenar metadatos locales persistentes para asociar registros locales con IDs remotos.

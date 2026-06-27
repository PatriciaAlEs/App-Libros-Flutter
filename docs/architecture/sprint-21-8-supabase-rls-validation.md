# Sprint 21.8 - Supabase remote schema and RLS validation

## Estado

Preparado para ejecucion real. No aplicado desde Codex.

## Motivo

Durante esta ejecucion no existe acceso operativo al proyecto real de Supabase desde el entorno local:

- `supabase` CLI no esta instalado.
- `psql` no esta instalado.
- No hay `supabase/config.toml` ni proyecto CLI enlazado en el repositorio.
- No se han proporcionado credenciales ni conexion remota para aplicar SQL desde terminal.

Por tanto, esta guia documenta el metodo recomendado y las pruebas RLS que deben ejecutarse en el proyecto real. No debe marcarse el sprint como cerrado hasta completar estos pasos en Supabase.

## Migracion revisada

Archivo:

- `supabase/migrations/202606270001_remote_data_model.sql`

Tablas esperadas:

- `profiles`
- `books`
- `reading_sessions`
- `annual_goals`

Revision realizada:

- Tablas, columnas, claves primarias e indices revisados.
- RLS revisado para `SELECT`, `INSERT`, `UPDATE` y `DELETE`.
- Politicas abiertas no detectadas.
- Ajuste aplicado: se agrego funcion y triggers `set_updated_at` para mantener `updated_at` en updates.

## Metodo recomendado para aplicar la migracion

Opcion A: Supabase SQL Editor

1. Abrir el proyecto real en Supabase.
2. Ir a `SQL Editor`.
3. Copiar el contenido completo de:
   - `supabase/migrations/202606270001_remote_data_model.sql`
4. Ejecutarlo una vez.
5. Confirmar que no hay errores.

Opcion B: Supabase CLI

Requiere tener CLI instalado, login realizado y proyecto enlazado:

```bash
supabase link --project-ref <project-ref>
supabase db push
```

## Verificacion de esquema

Ejecutar en SQL Editor:

```sql
select
  table_name,
  column_name,
  data_type,
  is_nullable
from information_schema.columns
where table_schema = 'public'
  and table_name in ('profiles', 'books', 'reading_sessions', 'annual_goals')
order by table_name, ordinal_position;
```

Resultado esperado:

- Existen las cuatro tablas.
- Todas tienen `id`, `created_at`, `updated_at` y `deleted_at`.
- `books`, `reading_sessions` y `annual_goals` tienen `user_id`.
- `profiles.id` referencia `auth.users(id)`.

## Verificacion de RLS activo

```sql
select
  schemaname,
  tablename,
  rowsecurity
from pg_tables
where schemaname = 'public'
  and tablename in ('profiles', 'books', 'reading_sessions', 'annual_goals')
order by tablename;
```

Resultado esperado:

- `rowsecurity = true` para las cuatro tablas.

## Verificacion de politicas

```sql
select
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
from pg_policies
where schemaname = 'public'
  and tablename in ('profiles', 'books', 'reading_sessions', 'annual_goals')
order by tablename, policyname;
```

Resultado esperado:

- Cada tabla tiene politicas de `SELECT`, `INSERT`, `UPDATE` y `DELETE`.
- Las tablas con `user_id` usan `auth.uid() = user_id`.
- `profiles` usa `auth.uid() = id`.
- No existen politicas con condiciones tipo `true`.

## Pruebas RLS con dos usuarios reales

Requisitos:

- Crear o identificar dos usuarios reales de Auth:
  - `<USER_A_UUID>`
  - `<USER_B_UUID>`
- Sustituir los placeholders antes de ejecutar.
- Ejecutar primero en un proyecto de staging si existe.

### Prueba 1 - usuario A solo inserta sus propios datos

```sql
begin;

set local role authenticated;
select set_config('request.jwt.claim.sub', '<USER_A_UUID>', true);

insert into public.books (
  user_id,
  local_book_id,
  title,
  status
) values (
  '<USER_A_UUID>',
  'rls-book-a',
  'RLS Book A',
  'reading'
);

-- Esperado: ERROR por RLS.
insert into public.books (
  user_id,
  local_book_id,
  title,
  status
) values (
  '<USER_B_UUID>',
  'rls-book-b-from-a',
  'RLS Book B From A',
  'reading'
);

rollback;
```

Resultado esperado:

- Primer `INSERT`: permitido.
- Segundo `INSERT`: rechazado por RLS.

### Prueba 2 - usuario A no lee datos de usuario B

```sql
begin;

-- Preparacion como owner de base de datos. Ejecutar antes de asumir rol authenticated.
insert into public.books (
  user_id,
  local_book_id,
  title,
  status
) values (
  '<USER_B_UUID>',
  'rls-book-b',
  'RLS Book B',
  'reading'
);

set local role authenticated;
select set_config('request.jwt.claim.sub', '<USER_A_UUID>', true);

select *
from public.books
where local_book_id = 'rls-book-b';

rollback;
```

Resultado esperado:

- El `SELECT` devuelve 0 filas.

### Prueba 3 - usuario A no modifica datos de usuario B

```sql
begin;

insert into public.books (
  user_id,
  local_book_id,
  title,
  status
) values (
  '<USER_B_UUID>',
  'rls-book-b',
  'RLS Book B',
  'reading'
);

set local role authenticated;
select set_config('request.jwt.claim.sub', '<USER_A_UUID>', true);

update public.books
set title = 'Should not update'
where local_book_id = 'rls-book-b';

delete from public.books
where local_book_id = 'rls-book-b';

rollback;
```

Resultado esperado:

- `UPDATE 0`.
- `DELETE 0`.

### Prueba 4 - usuario A solo accede a su perfil

```sql
begin;

set local role authenticated;
select set_config('request.jwt.claim.sub', '<USER_A_UUID>', true);

insert into public.profiles (
  id,
  reader_name
) values (
  '<USER_A_UUID>',
  'Reader A'
);

-- Esperado: ERROR por RLS.
insert into public.profiles (
  id,
  reader_name
) values (
  '<USER_B_UUID>',
  'Reader B From A'
);

rollback;
```

Resultado esperado:

- Perfil propio: permitido.
- Perfil de otro usuario: rechazado por RLS.

## Tablas pendientes de repetir

Las pruebas anteriores muestran el patron con `books` y `profiles`. Repetir el mismo esquema para:

- `reading_sessions`
- `annual_goals`

Validaciones esperadas:

- `INSERT` propio permitido.
- `INSERT` ajeno rechazado.
- `SELECT` ajeno devuelve 0 filas.
- `UPDATE` ajeno afecta 0 filas.
- `DELETE` ajeno afecta 0 filas.

## Resultado obtenido

Pendiente de ejecucion real en Supabase.

## Limitaciones pendientes

- La migracion no ha sido aplicada desde esta ejecucion.
- RLS no ha sido validado contra usuarios reales desde esta ejecucion.
- La app no esta conectada a estas tablas.
- No hay sync local -> nube ni nube -> local.
- No hay resolucion de conflictos.
- No hay marcado automatico de `sync_metadata` desde mutaciones locales.

## Criterio para cerrar Sprint 21.8

El sprint solo puede cerrarse cuando:

- la migracion se haya ejecutado en Supabase real;
- las cuatro tablas existan;
- RLS este activo;
- las pruebas con dos usuarios reales confirmen aislamiento por usuario;
- se documente el resultado obtenido en esta misma guia.

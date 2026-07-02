# QA Hito 8 - Sync manual y recuperacion remota

Fecha: 2026-07-02

## Causa encontrada

El flujo de sync manual ejecutaba subida y descarga, pero `AutoSyncCoordinator` solo devolvia `failed` cuando un paso lanzaba una excepcion completa. Los use cases de entidades capturaban errores por fila, incrementaban `failed` y guardaban `sync_metadata.error_message`, pero el coordinador podia terminar como `completed`.

Efecto visible: `SyncStatusCard` resolvia estado fallido por `sync_metadata.failed`, pero no tenia el detalle runtime de la excepcion y mostraba el mensaje generico `No se pudo completar la ultima sincronizacion.`

Cambio aplicado:

- Si upload tiene `failed > 0`, la sync termina como `failed` y no ejecuta download.
- Si download tiene `failed > 0`, la sync termina como `failed` con detalle.
- Los errores por fila incluyen operacion, tabla, entidad, `localId`, excepcion real y codigo/status si Supabase lo expone.
- En debug se imprime log seguro con `userId` redacted para confirmar que se envia `user_id` sin exponer el identificador completo.

## Tablas remotas esperadas

La app espera estas tablas en `public`:

- `profiles`
- `books`
- `reading_sessions`
- `annual_goals`

Columnas criticas para libros:

- `id uuid primary key`
- `user_id uuid not null references auth.users(id)`
- `local_book_id text not null`
- `title text not null`
- `status text not null`
- `created_at timestamptz`
- `updated_at timestamptz`
- `deleted_at timestamptz`

Columnas criticas para sesiones:

- `id uuid primary key`
- `user_id uuid not null references auth.users(id)`
- `local_session_id text not null`
- `local_book_id text not null`
- `remote_book_id uuid references public.books(id)`
- `pages_read integer`
- `minutes_read integer`
- `session_date date not null`
- `created_at timestamptz`
- `updated_at timestamptz`
- `deleted_at timestamptz`

RLS esperado:

- RLS habilitado en las cuatro tablas.
- `select`, `insert`, `update`, `delete` permitidos solo cuando `auth.uid() = user_id`.
- En `profiles`, `auth.uid() = id`.

La migracion de referencia es `supabase/migrations/202606270001_remote_data_model.sql`.

## QA manual - subida local

Comando usado:

```powershell
flutter run -d emulator-5554 --release --dart-define-from-file=dart_defines/dev.json
```

Para ver logs debug de sync, usar build debug/profile durante QA:

```powershell
flutter run -d emulator-5554 --dart-define-from-file=dart_defines/dev.json
```

Pasos:

1. Instalacion limpia.
2. Iniciar sesion con email.
3. Crear un libro desde Open Library.
4. Guardar el libro.
5. Marcarlo como empezado.
6. Actualizar progreso a pagina 50 de 450.
7. Ir a `Perfil`.
8. Pulsar `Sincronizar ahora`.

Resultado esperado:

- `SyncStatusCard` muestra `Todo sincronizado`.
- En Supabase, `public.books` contiene una fila con `user_id = auth.uid()` del usuario autenticado.
- `local_book_id` coincide con el id local.
- `current_page = 50`.
- `status = reading`.
- `sync_metadata` local queda con `pending_operation = none`, `sync_status = synced` y `remote_id` asignado para el libro.

Si falla:

- Revisar el texto visible en `SyncStatusCard`.
- En debug, revisar logs `[ReadPp sync]` para tabla, operacion, error, code/status.
- Revisar `sync_metadata.error_message` local para la entidad fallida.

## QA manual - recuperacion remota

Pasos:

1. Con la subida local aprobada, confirmar que existe el libro en Supabase.
2. Borrar datos locales o reinstalar app.
3. Abrir la app.
4. Iniciar sesion con la misma cuenta.
5. Esperar el auto-sync de login o pulsar `Perfil` > `Sincronizar ahora`.

Resultado esperado:

- La app descarga el libro remoto.
- El libro aparece en biblioteca con progreso y estado remotos.
- `sync_metadata` local queda reconstruido como `synced` con `remote_id`.

Si no descarga:

- Confirmar que `public.books.user_id` coincide con el usuario autenticado actual.
- Confirmar que `deleted_at is null`.
- Confirmar que RLS permite `select using (auth.uid() = user_id)`.
- Revisar logs `[ReadPp sync] operation=select_many table=books`.

## Queries utiles en Supabase

```sql
select id, user_id, local_book_id, title, current_page, status, deleted_at
from public.books
order by updated_at desc;
```

```sql
select schemaname, tablename, policyname, cmd, qual, with_check
from pg_policies
where schemaname = 'public'
  and tablename in ('profiles', 'books', 'reading_sessions', 'annual_goals')
order by tablename, policyname;
```

```sql
select tablename, rowsecurity
from pg_tables
where schemaname = 'public'
  and tablename in ('profiles', 'books', 'reading_sessions', 'annual_goals');
```

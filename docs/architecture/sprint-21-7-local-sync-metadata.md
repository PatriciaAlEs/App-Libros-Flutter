# Sprint 21.7 - Persistencia local del estado de sincronizacion

## Estado

Implementado y validado localmente.

## Alcance

Este sprint prepara la persistencia local necesaria para que ReadPp pueda asociar registros Drift con futuros registros remotos.

No implementa sincronizacion remota, no llama a Supabase y no cambia la experiencia de usuario.

Drift sigue siendo la fuente principal de datos.

## Drift

`AppDatabase` sube a `schemaVersion = 6`.

Nueva tabla:

- `sync_metadata`

Campos principales:

- `id`
- `entity_type`
- `local_id`
- `remote_id`
- `sync_status`
- `pending_operation`
- `last_synced_at`
- `last_local_update`
- `last_remote_update`
- `error_message`
- `retry_count`
- `created_at`
- `updated_at`

La combinacion `entity_type + local_id` es unica para evitar multiples estados de sync para el mismo registro local.

## Dominio

La feature `features/sync` incorpora metadata local tipada:

- `SyncEntityType`
- `SyncStatus`
- `PendingSyncOperation`
- `SyncMetadata`
- `SyncMetadataRepository`

Tipos de entidad iniciales:

- `profile`
- `book`
- `reading_session`
- `annual_goal`

Estados iniciales:

- `not_synced`
- `synced`
- `pending_upload`
- `pending_update`
- `pending_delete`
- `conflict`
- `failed`

Operaciones pendientes:

- `none`
- `create`
- `update`
- `delete`

## Data

Se agrega:

- `SyncMetadataDao`
- mapper Drift <-> dominio
- `LocalSyncMetadataRepository`
- provider Riverpod `syncMetadataRepositoryProvider`

Operaciones soportadas:

- crear/guardar metadata;
- buscar por tipo de entidad e ID local;
- listar registros pendientes de sync;
- asociar ID remoto;
- marcar como sincronizado;
- marcar subida, actualizacion o borrado pendiente;
- registrar fallo e incrementar reintentos.

## Validacion local

- `dart format lib test` OK.
- `flutter analyze` OK.
- `flutter test` OK, 81/81 tests.

Nota: `dart format .` no se usa como validacion global porque el directorio `build/` contiene rutas temporales obsoletas generadas por Flutter en esta maquina. El codigo fuente fue formateado con `dart format lib test`.

## Limitaciones

- La metadata aun no se crea automaticamente cuando se modifican libros, sesiones, objetivo anual o perfil.
- No hay subida local -> nube.
- No hay descarga nube -> local.
- No hay resolucion de conflictos.
- La migracion remota Supabase del Sprint 21.6 sigue pendiente de aplicacion/validacion real.

## Siguiente paso recomendado

Sprint 21.8: conectar las mutaciones locales principales con `SyncMetadataRepository` para marcar operaciones pendientes sin ejecutar todavia llamadas remotas, o aplicar/validar primero el schema Supabase real si se dispone del proyecto configurado.

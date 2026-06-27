# ADR-005 - Metadata local de sincronizacion

## Estado

Aceptado

## Fecha

2026-06-27

## Contexto

ReadPp ya cuenta con autenticacion, preparacion de migracion a cuenta y un modelo remoto Supabase definido en repositorio. Antes de implementar subida o descarga de datos, la app necesita conservar localmente el estado de asociacion entre registros Drift y futuros registros remotos.

La aplicacion debe seguir siendo local-first. Drift continua siendo la fuente principal y la futura sincronizacion debe poder operar sin contaminar el dominio con detalles de Supabase.

## Alternativas consideradas

Opcion A: agregar columnas de sincronizacion en cada tabla local

Ventajas:

- Consultas directas sobre cada entidad.
- Menos joins para casos simples.

Desventajas:

- Duplica campos y reglas por tabla.
- Obliga a tocar cada modelo local cuando crezca la sync.
- Mezcla datos de producto con estado operativo de sincronizacion.

Opcion B: crear una tabla local unica de metadata de sincronizacion

Ventajas:

- Mantiene separado el dato de producto y el estado operativo.
- Evita repetir columnas en `books`, `reading_sessions` y futuras tablas.
- Permite consultar pendientes de sync de forma uniforme.
- Facilita incorporar nuevas entidades sincronizables.

Desventajas:

- Requiere mapear `entity_type + local_id`.
- La integridad con tablas locales no queda representada por claves foraneas especificas.

Opcion C: esperar a implementar sync real

Ventajas:

- Evita trabajo preparatorio.

Desventajas:

- Mezcla migracion Drift, estado local y llamadas remotas en un mismo sprint.
- Aumenta riesgo de perdida de datos o estados ambiguos.

## Decision

ReadPp incorpora una tabla Drift `sync_metadata` como registro local unico para el estado de sincronizacion.

La tabla conserva:

- tipo de entidad sincronizable;
- ID local;
- ID remoto futuro;
- estado de sincronizacion;
- operacion pendiente;
- timestamps locales/remotos;
- ultimo error;
- numero de reintentos.

Los tipos de entidad, estados y operaciones pendientes se modelan con enums de dominio:

- `SyncEntityType`
- `SyncStatus`
- `PendingSyncOperation`

El acceso a Drift queda encapsulado detras de `SyncMetadataRepository` y su implementacion local `LocalSyncMetadataRepository`.

No se realizan llamadas a Supabase. No se modifica el comportamiento de biblioteca, sesiones, estadisticas, progreso ni preferencias.

## Consecuencias

### Positivas

- La app puede registrar estados pendientes antes de escribir sincronizacion remota.
- El dominio evita magic strings para tipos y estados.
- Drift sigue siendo la fuente principal de datos.
- La futura sync podra consultar pendientes y asociaciones local-remotas desde una API estable.

### Negativas

- La tabla no aplica claves foraneas por entidad porque agrupa multiples tipos sincronizables.
- Todavia no hay consumidores funcionales que creen metadata automaticamente al mutar libros o sesiones.
- La estrategia de conflictos sigue pendiente.

## Impacto

Esta decision afecta a:

- `core/database`
- `features/sync/domain`
- `features/sync/data`
- futuros sprints de sync local -> nube y nube -> local.

No implica:

- sincronizacion con Supabase;
- subida o descarga de datos;
- cambios de UI;
- cambios en los flujos locales existentes.

## Referencias

- `docs/adr/ADR-001-local-first.md`
- `docs/adr/ADR-004-remote-data-model-and-rls.md`
- Sprint 21.7 - Persistencia local del estado de sincronizacion.

# ADR-004 - Modelo remoto Supabase y RLS

## Estado

Aceptado

## Fecha

2026-06-27

## Contexto

ReadPp mantiene Drift como fuente principal de datos y ya cuenta con infraestructura Supabase, autenticacion y preparacion de migracion local a cuenta. Para avanzar hacia sincronizacion futura entre dispositivos hace falta definir una estructura remota segura y coherente con el modelo local-first.

Este sprint no sincroniza datos. La decision consiste en definir como se representaran remotamente los datos personales de lectura y como se aislaran por usuario antes de implementar subida, descarga o merge.

## Alternativas consideradas

Opcion A: reutilizar IDs locales como claves primarias remotas

Ventajas:

- Modelo inicial simple.
- Menos columnas.

Desventajas:

- Acopla Drift al modelo remoto.
- Dificulta resolver duplicados entre dispositivos.
- Complica migraciones futuras si cambian generadores locales.

Opcion B: usar UUID remoto propio y conservar IDs locales como columnas

Ventajas:

- Separa identidad remota e identidad local.
- Permite mapear datos por dispositivo y usuario.
- Facilita futuras estrategias de merge.
- Encaja con Supabase/Postgres y RLS.

Desventajas:

- Agrega columnas `local_*_id`.
- Requiere una futura tabla o metadatos de mapeo si la sincronizacion se vuelve mas compleja.

Opcion C: esperar a implementar sync para crear schema remoto

Ventajas:

- Evita anticipar campos.

Desventajas:

- Bloquea validar RLS y contratos.
- Mezcla decisiones de seguridad con logica de sincronizacion.
- Aumenta riesgo de diseno apresurado cuando se implemente sync.

## Decision

ReadPp define un modelo remoto Supabase con tablas por entidad sincronizable y RLS obligatoria desde el primer sprint de schema remoto.

Tablas iniciales:

- `profiles`
- `books`
- `reading_sessions`
- `annual_goals`

Cada entidad sincronizable usa:

- `id` como UUID remoto.
- `user_id` para propiedad del dato, excepto `profiles`, donde `id` coincide con `auth.users.id`.
- `local_*_id` para conservar el identificador local de Drift cuando aplica.
- `created_at`, `updated_at` y `deleted_at` en todas las tablas.

`deleted_at` se incorpora desde el inicio para soportar soft delete e incremental sync, aunque la app todavia no lo usa.

RLS se habilita en todas las tablas con politicas minimas de `SELECT`, `INSERT`, `UPDATE` y `DELETE` basadas en:

- `auth.uid() = user_id` para tablas de datos.
- `auth.uid() = id` para `profiles`.

No se crean politicas abiertas.

En Flutter se crea una feature `sync` con entidades remotas, DTOs, mappers y contratos de repositorio. No se implementa sincronizacion ni llamadas desde UI.

## Consecuencias

### Positivas

- La estructura remota queda preparada antes de la sync.
- RLS queda definida desde el inicio.
- Drift sigue siendo la fuente principal.
- El dominio local no reutiliza modelos Drift como DTOs remotos.
- Los futuros sprints pueden implementar sync sobre contratos existentes.

### Negativas

- El schema aun no ha sido aplicado ni verificado contra un proyecto Supabase real desde esta ejecucion.
- Las politicas RLS necesitaran QA con usuarios reales.
- La estrategia de conflicto y mapeo persistente local-remoto sigue pendiente.

## Impacto

Esta decision afecta a:

- `supabase/migrations/202606270001_remote_data_model.sql`
- `features/sync/domain`
- `features/sync/data`
- Futuros sprints de sync manual, incremental y automatica.

No implica:

- Cambios en Drift.
- Cambios en UI.
- Subida o descarga de datos.
- Resolucion de conflictos.
- Sincronizacion automatica.

## Referencias

- `docs/adr/ADR-001-local-first.md`
- `docs/adr/ADR-002-authentication-strategy.md`
- `docs/adr/ADR-003-account-migration-preparation.md`
- Sprint 21.6 - Modelo remoto de Supabase + RLS.

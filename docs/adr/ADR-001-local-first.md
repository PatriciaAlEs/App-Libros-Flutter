# ADR-001 - Arquitectura Offline First / Local First

## Estado

Aceptado

## Fecha

2026-06-25

## Contexto

ReadPp es una aplicacion Flutter para seguimiento personal de lectura. Antes del Hito 7, la app ya funciona sin backend y persiste sus datos principales localmente mediante Drift + SQLite.

El Hito 7 introduce Supabase como backend propio para autenticacion, sincronizacion progresiva y capacidades futuras de catalogo compartido. La decision critica es definir si Supabase pasa a ser la base principal de ejecucion o si se mantiene la arquitectura local actual como base de la experiencia.

ReadPp debe seguir permitiendo:

- Consultar la biblioteca sin conexion.
- Registrar sesiones de lectura sin conexion.
- Usar la app sin login.
- Mantener los datos locales existentes tras iniciar sesion.
- Sincronizar datos entre dispositivos de forma progresiva y controlada.

La app maneja informacion personal de lectura, progreso, sesiones, preferencias y biblioteca. Aunque estos datos no son credenciales ni secretos, deben tratarse con privacidad y evitar dependencias innecesarias de red para flujos cotidianos.

## Alternativas consideradas

Opcion A: Supabase como fuente de verdad principal

La app consultaria y escribiria principalmente en Supabase, usando Drift solo como cache local o almacenamiento auxiliar.

Ventajas:

- Modelo mental simple para backend centralizado.
- Menos logica inicial de reconciliacion local/remota.
- Recuperacion entre dispositivos mas directa.

Desventajas:

- La experiencia dependeria mas de la conexion.
- Riesgo de romper el comportamiento offline actual.
- Mayor acoplamiento entre UI, backend y disponibilidad de red.
- Drift perderia su papel actual como base fiable del producto.

Opcion B: Drift como fuente de verdad y Supabase como sincronizacion

La app mantiene Drift como fuente de verdad durante el uso normal. Supabase se usa para autenticacion, respaldo, sincronizacion entre dispositivos y backend progresivo.

Ventajas:

- Mantiene el comportamiento offline actual.
- Permite evolucionar hacia sync sin reescribir el producto de golpe.
- La UI puede seguir leyendo desde una fuente local rapida y estable.
- Login y backend no bloquean la experiencia principal.
- Facilita sync manual o progresiva por fases.

Desventajas:

- Requiere disenar metadatos de sincronizacion.
- Introduce reconciliacion entre datos locales y remotos.
- Puede necesitar politicas claras de conflicto y borrado logico.

Opcion C: Modelo hibrido con algunas pantallas leyendo directo de Supabase

Algunas funcionalidades seguirian usando Drift, mientras otras leerian directamente de Supabase.

Ventajas:

- Puede acelerar features concretas conectadas al backend.
- Reduce trabajo local en algunas pantallas nuevas.

Desventajas:

- Fragmenta la arquitectura.
- Hace menos predecible el comportamiento offline.
- Puede provocar inconsistencias entre datos locales y remotos.
- Aumenta el riesgo de que la UI dependa de red sin necesidad.

## Decision

ReadPp adopta una arquitectura Offline First / Local First.

Drift sera la fuente de verdad mientras la aplicacion esta en uso. La biblioteca, el progreso, las sesiones de lectura, las preferencias y las estadisticas se consultaran y modificaran primero en la base local.

Supabase se incorporara como backend progresivo para:

- Autenticacion mediante Supabase Auth.
- Asociacion de datos locales a un `user_id`.
- Sincronizacion entre dispositivos.
- Recuperacion de biblioteca y progreso en nuevos dispositivos.
- Futuro catalogo global incremental.

Supabase no sustituye a Drift como base principal de ejecucion. La app no debe depender de conexion para consultar la biblioteca ni para registrar una sesion de lectura.

Cada entidad sincronizable debera poder evolucionar hacia un modelo con identificador local y remoto:

- `local_id`: generado y usado por Drift.
- `remote_id`: UUID generado y usado por Supabase.

Estos identificadores no se sustituyen entre si. La capa de sincronizacion sera responsable de mapear ambos mundos.

La primera version de sincronizacion usara una politica conservadora: en conflictos iniciales, gana el dato local. Los borrados deberan prepararse como soft delete mediante `deleted_at`, evitando hard delete.

Esta decision se toma porque el valor principal de ReadPp es que la lectura y el registro personal funcionen siempre, incluso sin red o sin cuenta. Supabase debe ampliar la portabilidad y continuidad entre dispositivos, no convertirse en un punto unico de fallo para la experiencia diaria.

## Consecuencias

### Positivas

- La app mantiene su funcionamiento offline actual.
- El usuario puede seguir usando ReadPp sin login.
- La biblioteca y las sesiones no dependen de disponibilidad de red.
- El login no implica perdida ni reemplazo de datos locales.
- La sincronizacion puede implementarse por fases.
- La UI puede seguir leyendo de una fuente local rapida y predecible.
- Supabase queda acotado a identidad, sincronizacion y backend progresivo.
- La arquitectura permite un futuro catalogo global sin mezclarlo con la biblioteca personal.

### Negativas

- Sera necesario anadir metadatos de sincronizacion a entidades locales.
- Habra que implementar una capa explicita de sync.
- La resolucion de conflictos requiere reglas de producto claras.
- La duplicidad `local_id` / `remote_id` aumenta la complejidad del modelo.
- La recuperacion multi-dispositivo no sera inmediata hasta implementar sync.
- Las features conectadas deberan respetar la regla de no leer desde Supabase directamente como fuente principal de UI.

## Impacto

Esta decision afecta a:

- Persistencia local con Drift.
- Diseno futuro del schema de Supabase.
- Autenticacion con Supabase Auth.
- Asociacion de datos locales al usuario autenticado.
- Sincronizacion de biblioteca, sesiones, progreso y preferencias.
- Politicas de conflicto y borrado logico.
- Capa de repositorios y servicios de datos.
- Futuro catalogo global `book_catalog`.
- Documentacion tecnica del Hito 7.

No implica cambios inmediatos de codigo Dart, dependencias, tablas reales ni migraciones. Es una decision arquitectonica base para orientar los siguientes sprints del Hito 7.

## Referencias

- Hito 7 - Backend con Supabase manteniendo arquitectura local-first.
- `docs/hito-7-supabase-architecture.md`
- Sprint 21 - Diseno tecnico.
- Sprint 22 - Schema Supabase.
- Sprint 23 - Auth sin sync.
- Sprint 24 - Sync manual.
- Sprint 25 - Sync automatica progresiva.
- Sprint 26 - Catalogo incremental.

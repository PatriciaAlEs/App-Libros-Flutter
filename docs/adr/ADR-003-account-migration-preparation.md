# ADR-003 - Preparacion de migracion local a cuenta

## Estado

Aceptado

## Fecha

2026-06-27

## Contexto

ReadPp ya dispone de infraestructura opcional de Supabase, autenticacion base y pantallas de Cuenta/Auth. La app, sin embargo, sigue siendo local-first: Drift es la fuente principal de datos y debe seguir funcionando sin login, sin red y sin sincronizacion remota.

El siguiente paso antes de sincronizar es preparar la asociacion entre los datos locales existentes y el `user.id` autenticado. Esta preparacion debe detectar biblioteca, progreso, sesiones, estadisticas y preferencias locales sin subir datos ni crear tablas remotas todavia.

La decision importante es donde ubicar esta responsabilidad para evitar que Auth, UI o dominio queden acoplados a Supabase o a una futura estrategia de sincronizacion concreta.

## Alternativas consideradas

Opcion A: incorporar la preparacion en `AuthController`

Ventajas:

- Menos archivos iniciales.
- La preparacion ocurre cerca del cambio de sesion.

Desventajas:

- Mezcla login/logout con deteccion de datos locales.
- Hace crecer `AuthController` fuera de su responsabilidad.
- Complica testear migracion sin Auth.

Opcion B: preparar migracion directamente desde la UI de Cuenta

Ventajas:

- Implementacion rapida.
- Facil mostrar el resultado.

Desventajas:

- Acopla reglas de migracion a widgets.
- Dificulta reutilizar la preparacion en futuras pantallas o sync manual.
- Hace mas dificil probar la logica sin Flutter UI.

Opcion C: crear un caso de uso dedicado y un controlador separado

Ventajas:

- Mantiene `AuthController` centrado en autenticacion.
- Permite probar la preparacion sin Supabase real.
- Mantiene dominio sin dependencias directas de Supabase.
- Deja una pieza reutilizable para futuros sprints de sync.
- Expone un resultado explicito con estado y resumen local.

Desventajas:

- Agrega una capa adicional antes de que exista sync real.
- El resumen inicial es conservador y en memoria.

## Decision

ReadPp usara un caso de uso dedicado para preparar la futura migracion local a cuenta.

El caso de uso:

- Recibe el usuario autenticado como valor de dominio (`AppUser?`).
- Consulta datos locales mediante repositorios existentes.
- Detecta biblioteca, sesiones, objetivo anual y preferencias locales.
- Devuelve un resultado explicito con estado, `userId` y resumen de datos.
- No escribe en Drift.
- No llama a Supabase.
- No sube ni descarga datos.

La presentacion usa un controlador separado de migracion de cuenta para orquestar esta preparacion. `AuthController` conserva una unica responsabilidad: gestionar estado de sesion y acciones de autenticacion.

La deteccion de preferencias especificas de UI/perfil se realiza fuera del caso de uso para evitar importar controladores de Riverpod o clases de presentacion dentro del dominio.

## Consecuencias

### Positivas

- La futura sync tiene una base testeable y desacoplada.
- Auth permanece separado de migracion/sync.
- Drift sigue siendo la fuente principal.
- La app no cambia su comportamiento local.
- No hay dependencia de Supabase en el dominio.
- Los siguientes sprints pueden ampliar el resultado con metadatos de asociacion real.

### Negativas

- La preparacion actual no persiste ningun estado de migracion.
- La deteccion de sesiones se basa en libros locales y no cubre sesiones huerfanas si existieran.
- La asociacion real a `user_id`, metadatos de sync y resolucion de conflictos siguen pendientes.

## Impacto

Esta decision afecta a:

- `features/auth/domain/usecases/prepare_account_migration.dart`
- `features/auth/domain/entities/account_migration_preparation.dart`
- `features/auth/presentation/controllers/account_migration_controller.dart`
- Pantalla de Cuenta como superficie informativa.
- Futuros sprints de asociacion local, sync manual y sync automatica.

No implica:

- Cambios en schema Drift.
- Tablas Supabase.
- RLS.
- Subida o descarga de datos.
- Sincronizacion automatica.

## Referencias

- `docs/adr/ADR-001-local-first.md`
- `docs/adr/ADR-002-authentication-strategy.md`
- Sprint 21.5 - Preparacion de migracion de datos a cuenta.

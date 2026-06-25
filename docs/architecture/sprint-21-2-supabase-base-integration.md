# Sprint 21.2 - Integracion base de Supabase

## Objetivo del sprint

Anadir la dependencia oficial de Supabase para Flutter y preparar una inicializacion segura y opcional, sin modificar la logica funcional de ReadPp.

La app debe seguir funcionando completamente en modo local aunque Supabase no este configurado.

## Decision aplicada

No se crea un ADR nuevo para este sprint.

La decision arquitectonica relevante ya esta aceptada en `ADR-001 - Arquitectura Offline First / Local First`:

- Drift sigue siendo la fuente de verdad durante el uso de la app.
- Supabase se incorpora como backend progresivo.
- Supabase no debe ser obligatorio para consultar biblioteca ni registrar sesiones.

Sprint 21.2 implementa la primera infraestructura tecnica de esa decision, sin introducir Auth, tablas ni sincronizacion.

## Cambios implementados

### Dependencia

Se anade:

- `supabase_flutter`

Uso previsto:

- Inicializacion del SDK oficial.
- Acceso futuro a Supabase Auth.
- Cliente base para sincronizacion futura.

### Configuracion

La configuracion se lee mediante `String.fromEnvironment`:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

Nota:

- El SDK actual recibe este valor mediante el parametro `publishableKey`.
- ReadPp mantiene el nombre de variable `SUPABASE_ANON_KEY` como contrato de configuracion del proyecto.

Reglas:

- Si faltan las variables, Supabase queda deshabilitado.
- Si las variables estan vacias, Supabase queda deshabilitado.
- La app sigue arrancando sin backend.
- No se hardcodean claves ni URLs reales.

### Capa base

Ubicacion creada:

- `reading_tracker/lib/core/backend`

Archivos:

- `supabase_config.dart`
- `supabase_initializer.dart`
- `supabase_client_provider.dart`

Responsabilidades:

- Centralizar configuracion de Supabase.
- Inicializar Supabase solo si existe configuracion.
- Exponer si Supabase esta habilitado.
- Exponer un provider nullable del cliente.
- Evitar dependencias directas desde widgets o features.

## Integracion en arranque

La inicializacion se conecta en:

- `reading_tracker/lib/main.dart`

Orden resultante:

1. `ReadPpSentry.init` mantiene la envoltura del arranque.
2. Dentro del `appRunner`, se intenta inicializar Supabase.
3. Si Supabase no esta configurado, no ocurre nada.
4. La app arranca con `ProviderScope`.

## Fuera de alcance

No se implementa todavia:

- Login.
- Registro.
- Logout.
- Google OAuth.
- Pantallas de Auth.
- Tablas Supabase.
- Sincronizacion.
- Cambios en Drift.
- Cambios en biblioteca, progreso, estadisticas, insights u onboarding.

## Criterios de validacion

Validacion requerida:

- `flutter analyze` OK.
- `flutter test` OK.
- La app compila sin variables de Supabase.
- Los tests siguen pasando.
- Drift no se ve afectado.
- La experiencia offline permanece intacta.
- Supabase queda preparado pero no obligatorio.

## Siguiente paso recomendado

Sprint 21.3 deberia preparar Auth v1 sin sincronizacion:

- Definir estado de sesion.
- Crear capa `features/auth`.
- Exponer usuario autenticado mediante provider.
- Implementar login con Google y correo/contrasena.
- Mantener la app usable sin login.

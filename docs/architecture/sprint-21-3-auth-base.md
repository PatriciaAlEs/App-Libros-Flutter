# Sprint 21.3 - Auth base sin sincronizacion

## Objetivo

Crear la base tecnica de autenticacion en Flutter sin implementar todavia sincronizacion, migracion de datos locales ni cambios en Drift.

La app debe seguir siendo completamente usable sin login y funcionando en modo local.

## Decision aplicada

No se crea un ADR nuevo en este sprint.

La decision arquitectonica ya esta aceptada en:

- `docs/adr/ADR-002-authentication-strategy.md`

Sprint 21.3 implementa la base tecnica de esa decision:

- Supabase Auth como proveedor.
- Google OAuth preparado.
- Email y contrasena preparado.
- Auth opcional para no romper Local First.

## Estructura creada

Se crea `reading_tracker/lib/features/auth` con separacion por capas:

```txt
lib/features/auth/
├── data/
│   └── auth_repository_impl.dart
├── domain/
│   ├── app_user.dart
│   └── auth_repository.dart
└── presentation/
    ├── controllers/
    │   └── auth_controller.dart
    └── screens/
        └── auth_screen.dart
```

## Que funciona

- Existe un modelo de dominio `AppUser` con datos seguros y necesarios:
  - `id`
  - `email`
  - `displayName`
  - `avatarUrl`
- Existe una abstraccion `AuthRepository`.
- Existe una implementacion basada en Supabase Auth.
- El repositorio puede:
  - obtener usuario actual
  - escuchar cambios de sesion
  - iniciar sesion con email y contrasena
  - registrar usuario con email y contrasena
  - preparar login con Google
  - cerrar sesion
- Existe `AuthController` con Riverpod.
- El controller expone:
  - usuario actual
  - estado autenticado/no autenticado
  - loading
  - error controlado
  - metodos de login, registro, Google y logout
- Si Supabase no esta configurado:
  - el estado permanece como no autenticado
  - no se lanza excepcion global
  - el error solo aparece si el usuario intenta autenticar
- Existe una pantalla `AuthScreen` minima y aislada.

## Que queda preparado

- Integracion con Google OAuth mediante Supabase Auth.
- Login con email y contrasena.
- Registro con email y contrasena.
- Escucha de cambios de sesion.
- Uso futuro de `user.id` para asociar datos sincronizables.
- Extension futura hacia `profiles`, `user_books`, `reading_sessions` y `reader_settings`.

## Que NO se implemento todavia

- Sincronizacion.
- Asociacion de datos locales al usuario.
- Migraciones Drift.
- Tablas Supabase.
- Perfiles remotos.
- RLS.
- Recuperacion de contrasena.
- Verificacion de email.
- Ruta publica o navegacion principal hacia Auth.
- Logout visible en perfil/settings.
- Cambios en onboarding.
- Cambios en biblioteca, progreso, estadisticas, insights o sesiones.

## Riesgos

- Google OAuth requiere configuracion externa en Supabase y proveedores de plataforma.
- La pantalla Auth existe pero aun no esta integrada en navegacion de producto.
- Email y contrasena dependen de la configuracion del proyecto Supabase.
- La experiencia de cuenta debe introducirse sin convertir login en obligatorio.
- La futura sincronizacion debe seguir usando Drift como fuente de verdad local.

## Pasos siguientes

- Definir donde aparece el acceso a cuenta sin interrumpir onboarding.
- Validar login email/contrasena con un proyecto Supabase configurado.
- Configurar Google OAuth en Supabase y plataformas objetivo.
- Preparar `profiles` en un sprint posterior.
- Disenar asociacion de datos locales al `user.id` antes de implementar sync.
- Mantener el estado local como experiencia principal hasta que sync este lista.

## Validacion

Criterios del sprint:

- `flutter analyze` OK.
- `flutter test` OK.
- La app sigue arrancando sin variables Supabase.
- La app sigue funcionando offline/local.
- Drift no se ve afectado.
- Auth no rompe navegacion ni onboarding.

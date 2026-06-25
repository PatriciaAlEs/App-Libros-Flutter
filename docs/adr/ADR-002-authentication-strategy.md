# ADR-002 - Authentication Strategy

## Estado

Aceptado

## Fecha

2026-06-25

## Contexto

ReadPp necesita permitir que una persona pueda iniciar sesion y recuperar su biblioteca, progreso, sesiones y preferencias en diferentes dispositivos, manteniendo la filosofia Offline First / Local First.

La aplicacion debe seguir siendo usable sin login en modo local. La autenticacion no debe romper el modo offline ni obligar al usuario a crear cuenta desde el inicio.

El Hito 7 incorpora Supabase como backend progresivo para autenticacion, sincronizacion y recuperacion multi-dispositivo. Por tanto, la estrategia de autenticacion debe encajar con:

- Drift como fuente de verdad durante el uso normal de la app.
- Supabase como backend de identidad y sincronizacion progresiva.
- Asociacion futura de datos locales a un `user.id` estable.
- Politicas RLS futuras basadas en `user_id`.
- Uso seguro de datos personales minimos.

La decision debe evitar que ReadPp implemente manualmente seguridad sensible como almacenamiento de contrasenas, hashing, emision de tokens o gestion de sesiones.

## Alternativas consideradas

Opcion A: No anadir autenticacion

ReadPp continuaria funcionando solo como app local, sin cuentas ni recuperacion entre dispositivos.

Ventajas:

- Menor complejidad tecnica.
- Sin dependencia de proveedor de Auth.
- La experiencia local actual permanece intacta.

Desventajas:

- No permite recuperar biblioteca y progreso en otro dispositivo.
- Bloquea la sincronizacion multi-dispositivo.
- Limita el valor del backend propio previsto en Hito 7.
- No permite asociar datos sincronizables a un usuario estable.

Opcion B: Implementar autenticacion propia

ReadPp implementaria su propio sistema de usuarios, contrasenas, sesiones y tokens.

Ventajas:

- Control completo sobre el modelo de autenticacion.
- Menor dependencia de servicios externos de Auth.

Desventajas:

- Alto riesgo de seguridad.
- Requiere almacenar y proteger credenciales.
- Requiere implementar hashing seguro de contrasenas.
- Requiere generar, renovar y revocar tokens.
- Aumenta coste de mantenimiento y superficie de ataque.
- No aporta valor diferencial al producto.

Opcion C: Usar Firebase Auth

ReadPp usaria Firebase Auth como proveedor de autenticacion.

Ventajas:

- Servicio maduro y ampliamente usado.
- Buen soporte para Google OAuth.
- Gestiona sesiones, tokens y credenciales.

Desventajas:

- Introduce un segundo backend principal junto a Supabase.
- Aumenta la complejidad de integracion con Postgres y RLS.
- Requiere mapear identidad de Firebase con datos en Supabase.
- Fragmenta la arquitectura del Hito 7.

Opcion D: Usar Supabase Auth

ReadPp usaria Supabase Auth como sistema de autenticacion.

Ventajas:

- Encaja con Supabase como backend progresivo ya elegido para Hito 7.
- Gestiona usuarios, sesiones, JWT y hash seguro de contrasenas.
- Evita implementar seguridad sensible manualmente.
- Permite Google OAuth.
- Permite email y contrasena.
- Integra directamente con Postgres, RLS y futuras tablas sincronizadas por `user_id`.
- Reduce la separacion entre identidad, datos sincronizados y politicas de acceso.

Desventajas:

- Genera dependencia de Supabase Auth.
- Requiere configuracion OAuth adicional para Google.
- Requiere configurar recuperacion y verificacion de email cuando se habiliten.
- Si ReadPp se publica en App Store en el futuro, Apple podria ser necesario por politicas de plataforma.

## Decision

ReadPp usara Supabase Auth como sistema de autenticacion.

Auth v1 incluira dos metodos:

- Continuar con Google.
- Continuar con correo y contrasena.

No se implementaran por ahora:

- Apple.
- Facebook.
- GitHub.
- Discord.
- Magic Link.
- Login anonimo.

Se acepta Supabase Auth porque:

- Ya se ha elegido Supabase como backend progresivo del Hito 7.
- Gestiona usuarios, sesiones, JWT y hash de contrasenas.
- Evita implementar seguridad sensible manualmente.
- Permite Google OAuth.
- Permite email y contrasena.
- Integra bien con Postgres, RLS y futuras tablas sincronizadas por `user_id`.

La autenticacion debe ser opcional desde la experiencia de producto. ReadPp debe seguir funcionando en modo local sin login, y el usuario podra iniciar sesion cuando quiera recuperar o sincronizar su biblioteca y progreso.

## Seguridad

ReadPp nunca almacenara contrasenas.

ReadPp no implementara hashing manual de contrasenas.

ReadPp no generara JWT manualmente.

Supabase Auth sera responsable de:

- Hash seguro de contrasenas.
- Gestion de usuarios.
- Generacion y renovacion de JWT.
- Gestion de sesiones.
- Recuperacion de contrasena.
- Verificacion de email cuando se habilite.
- Integracion con proveedores OAuth configurados.

ReadPp usara unicamente el `user.id` / UUID de Supabase para asociar datos sincronizables al usuario autenticado.

La app solo almacenara datos necesarios para la experiencia:

- UUID del usuario.
- Email cuando venga de Supabase Auth.
- Nombre visible si existe o el usuario lo configura.
- Avatar si existe.
- Preferencias de la aplicacion.
- Datos sincronizables de biblioteca, progreso y sesiones.

No se almacenaran:

- Contrasenas.
- Tokens externos.
- Secretos privados.
- Informacion sensible innecesaria.
- Datos personales que no aporten valor a ReadPp.

## Consecuencias

### Positivas

- Menos riesgo de seguridad.
- Integracion directa con Supabase.
- Login comodo con Google.
- Alternativa para usuarios que no quieran Google.
- Base solida para sincronizacion multi-dispositivo.
- Relacion directa entre usuario autenticado, RLS y datos sincronizados.
- Menor necesidad de infraestructura propia de identidad.

### Negativas

- Dependencia de Supabase Auth.
- Configuracion OAuth adicional para Google.
- Gestion de recuperacion y verificacion de email.
- En iOS, Apple podria ser necesario si se publica en App Store en el futuro.
- Auth queda condicionada a la disponibilidad y comportamiento del SDK de Supabase.

## Impacto

Esta decision afecta a:

- `features/auth`
- `core/backend`
- Futura sincronizacion.
- Futuras politicas RLS.
- `profiles`
- `user_books`
- `reading_sessions`
- `reader_settings`

No implica implementar Auth todavia. La implementacion queda pendiente para Sprint 21.3 o el sprint que corresponda.

## Estado de la decision

- Estado: Aceptado.
- Fecha de aprobacion: 2026-06-25.
- Aprobado por: Proyecto ReadPp.
- Implementacion: Pendiente.
- Relacionado con: Hito 7.

## Referencias

- `docs/hito-7-supabase-architecture.md`
- `docs/adr/ADR-001-local-first.md`
- `docs/architecture/sprint-21-2-supabase-base-integration.md`

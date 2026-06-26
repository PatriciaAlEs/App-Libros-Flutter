# ReadPp - Hito 7 Supabase Architecture

## 1. Estado actual de ReadPp

ReadPp es una app Flutter Offline First para seguimiento personal de lectura. La app funciona actualmente sin backend y debe seguir haciendolo.

Estado actual confirmado:

- App Flutter mobile-first con Web/PWA.
- Persistencia local con Drift + SQLite.
- APK Android generado.
- PWA desplegada en Vercel.
- Open Library integrado para busqueda de libros.
- Sentry integrado y validado para observabilidad de errores.
- PostHog integrado y validado para analytics de producto.
- Suite automatizada vigente: 67/67 tests OK.
- La app soporta uso offline porque los datos principales viven localmente.

El Hito 7 no debe romper este estado. Supabase se incorpora como backend propio y capa de sincronizacion, no como sustituto inmediato de Drift.

## 2. Objetivo del Hito 7

Convertir ReadPp en una app con backend propio usando Supabase, manteniendo compatibilidad con Drift y la filosofia Offline First.

Objetivos principales:

- Mantener Drift como fuente local principal.
- Anadir autenticacion con Supabase.
- Permitir login con Google y correo/contrasena.
- Asociar datos locales existentes al usuario autenticado sin perder informacion.
- Preparar sincronizacion progresiva entre dispositivos.
- Recuperar biblioteca, progreso, sesiones y preferencias en otro dispositivo.
- Guardar solo datos seguros y necesarios.
- Preparar un catalogo incremental de libros en Supabase para reducir dependencia futura de Open Library.

## 3. Principios de arquitectura Offline First

- La app debe poder usarse sin login.
- La app debe arrancar y ser util sin conexion.
- Drift conserva la experiencia principal de lectura, biblioteca y sesiones.
- La fuente de verdad mientras la aplicacion esta en uso sera siempre Drift.
- Supabase sera la fuente de sincronizacion entre dispositivos, no la base de datos principal de ejecucion.
- Supabase no debe bloquear la creacion o edicion local de datos.
- La app nunca debe depender de conexion para consultar la biblioteca.
- La app nunca debe depender de conexion para registrar una sesion de lectura.
- Login no debe borrar ni reemplazar datos locales.
- Tras login, los datos locales pueden asociarse al usuario autenticado.
- La primera sincronizacion debe ser explicita, controlada y reversible en experiencia.
- En sync v1, ante conflicto inicial, gana el dato local.
- No hacer hard delete durante sincronizacion; usar `deleted_at`.
- El backend debe ser una capa de portabilidad y recuperacion, no una dependencia critica del flujo diario.

## 4. Responsabilidad de Drift

Drift sigue siendo la fuente local principal y la fuente de verdad de ReadPp durante el uso normal de la aplicacion.

Responsabilidades:

- Guardar biblioteca local.
- Guardar sesiones de lectura.
- Guardar progreso de libros.
- Guardar estado de lectura.
- Guardar preferencias locales de la app.
- Permitir uso offline completo.
- Alimentar UI, estadisticas e insights.
- Mantener el flujo actual funcionando aunque no exista usuario autenticado.
- Registrar estado de sincronizacion por entidad cuando se introduzca sync.
- Resolver lecturas y escrituras de producto aunque Supabase no este disponible.

En Hito 7, Drift debe evolucionar con campos de sincronizacion, pero no debe ser reemplazado por llamadas directas a Supabase desde UI.

## 5. Responsabilidad de Supabase

Supabase sera el backend propio para identidad, respaldo y sincronizacion entre dispositivos. No sera la base de datos principal de ejecucion de la app.

Responsabilidades previstas:

- Gestionar autenticacion con Supabase Auth.
- Soportar login con Google y correo/contrasena.
- Exponer `user_id` estable para asociar datos.
- Guardar datos sincronizables del usuario.
- Permitir recuperacion de biblioteca y progreso en otro dispositivo.
- Aplicar Row Level Security por usuario.
- Guardar configuracion lectora segura.
- Preparar catalogo incremental de libros compartido por la app.
- Actuar como destino/origen de sync, manteniendo Drift como fuente de verdad local.

Supabase no debe guardar secretos de terceros ni datos sensibles innecesarios.

### Auth v1 - decisiones definitivas

ReadPp ofrecera unicamente dos metodos de autenticacion en Auth v1:

- Continuar con Google, como opcion principal.
- Continuar con correo y contrasena.

No se implementaran todavia:

- Apple.
- Facebook.
- GitHub.
- Discord.
- Magic Link.
- Login anonimo.

La autenticacion estara completamente delegada en Supabase Auth.

Supabase sera responsable de:

- Hash seguro de contrasenas.
- Generacion y renovacion de JWT.
- Gestion de sesiones.
- Recuperacion de contrasena.
- Verificacion del correo electronico cuando se habilite.

ReadPp nunca almacenara contrasenas. La app solo guardara el `user_id` de Supabase y los datos necesarios para la experiencia de usuario.

Datos seguros que puede guardar:

- UUID del usuario.
- Email del usuario si viene de Supabase Auth.
- Nombre visible si el usuario lo configura.
- Avatar si existe.
- Saludo o preferencia de perfil lector.
- Tema visual.
- Reto lector anual.
- Preferencias internas de ReadPp.
- Biblioteca y sesiones del usuario autenticado.
- Progreso de lectura.
- Estadisticas derivadas o configuracion necesaria para calcularlas.

Datos que no debe guardar:

- Contrasenas.
- Tokens externos.
- Claves privadas.
- Datos medicos.
- Ubicacion precisa.
- Datos personales que no aporten valor a la aplicacion.
- Informacion no necesaria para el producto.

## 6. Flujo de autenticacion previsto

### Usuario invitado/local

El usuario puede instalar y usar ReadPp sin cuenta.

Comportamiento:

- Drift crea y mantiene datos locales.
- La biblioteca, sesiones y progreso funcionan offline.
- No existe `user_id` remoto.
- Las entidades pueden tener `sync_status = local_only` o equivalente futuro.

### Login con Google o correo/contrasena

Cuando el usuario decide iniciar sesion:

- La app ofrece `Continuar con Google` como opcion principal.
- La app ofrece `Continuar con correo y contrasena` como alternativa.
- La app abre el flujo correspondiente mediante Supabase Auth.
- Supabase devuelve un usuario autenticado.
- La app obtiene `user_id`, email y metadata permitida como nombre visible o avatar si existen.
- La app crea o actualiza `profiles`.
- La app no borra datos locales existentes.
- La app nunca recibe ni almacena el hash de contrasena ni tokens externos.

### Asociacion de datos locales al usuario

Tras login:

- La app detecta entidades locales sin `user_id`.
- La app propone asociar los datos locales al usuario autenticado.
- En sync v1, se puede hacer asociacion local primero y subida posterior.
- Cada entidad local recibe `user_id` y queda pendiente de sync.
- El dato local gana frente a posibles datos remotos iniciales.

Regla clave:

- Login no equivale a reset.
- Login no reemplaza biblioteca local automaticamente.
- Login habilita portabilidad y respaldo.

### Recuperacion en otro dispositivo

En otro dispositivo:

- Usuario instala o abre ReadPp.
- Usuario inicia sesion con el mismo proveedor.
- La app descarga datos remotos desde Supabase.
- Los datos se escriben en Drift.
- La UI sigue leyendo desde Drift.

En sync v1, la recuperacion puede ser manual o guiada. La sincronizacion automatica puede llegar en fases posteriores.

## 7. Modelo de datos conceptual

### profiles

Representa el perfil minimo asociado a Supabase Auth.

Campos conceptuales:

- `id`
- `user_id`
- `email`
- `display_name`
- `avatar_url`
- `created_at`
- `updated_at`
- `deleted_at`

### user_books

Representa los libros guardados por un usuario.

`user_books` es el catalogo personal del usuario. Contiene estado, progreso, valoracion, notas y cualquier dato propio de la experiencia de lectura de ese usuario.

Campos conceptuales:

- `id`
- `local_id`
- `remote_id`
- `user_id`
- `title`
- `author`
- `isbn`
- `external_source`
- `external_id`
- `cover_url`
- `total_pages`
- `current_page`
- `status`
- `rating`
- `notes`
- `created_at`
- `updated_at`
- `deleted_at`
- `last_synced_at`
- `sync_status`

Nota de privacidad:

- `title`, `author`, `notes` y `rating` forman parte de la biblioteca del usuario. Deben estar protegidos con RLS y nunca exponerse entre usuarios.
- `user_books` y `book_catalog` son conceptos separados. Un libro en `user_books` pertenece a un usuario; un registro en `book_catalog` es una referencia global reutilizable.

### reading_sessions

Representa sesiones de lectura del usuario.

Campos conceptuales:

- `id`
- `local_id`
- `remote_id`
- `remote_book_id`
- `local_book_id`
- `user_id`
- `date`
- `minutes`
- `pages_read`
- `note`
- `created_at`
- `updated_at`
- `deleted_at`
- `last_synced_at`
- `sync_status`

### reader_settings

Representa configuracion lectora y preferencias de ReadPp.

Campos conceptuales:

- `id`
- `local_id`
- `remote_id`
- `user_id`
- `display_name`
- `reader_greeting`
- `custom_greeting`
- `theme`
- `annual_reading_goal`
- `current_reading_book_id`
- `created_at`
- `updated_at`
- `deleted_at`
- `last_synced_at`
- `sync_status`

### sync_metadata

Representa control de sincronizacion por dispositivo o usuario.

Campos conceptuales:

- `id`
- `user_id`
- `device_id`
- `entity_type`
- `last_pull_at`
- `last_push_at`
- `last_successful_sync_at`
- `sync_version`
- `created_at`
- `updated_at`

### book_catalog futuro

Catalogo global incremental compartido para reducir dependencia de Open Library.

`book_catalog` no representa libros propiedad de un usuario. Representa fichas bibliograficas reutilizables por la app.

Decision de producto:

- En una primera fase Open Library seguira siendo la fuente principal.
- Conforme los usuarios busquen y seleccionen libros, ReadPp podra poblar automaticamente `book_catalog`.
- El catalogo global permitira reducir progresivamente la dependencia de Open Library.
- El catalogo global tambien puede acelerar futuras busquedas y mejorar deduplicacion.
- La biblioteca personal seguira viviendo en `user_books`.

Campos conceptuales:

- `id`
- `canonical_title`
- `canonical_author`
- `isbn`
- `cover_url`
- `first_publish_year`
- `publisher`
- `page_count`
- `created_at`
- `updated_at`
- `deleted_at`

### book_sources futuro

Fuentes externas asociadas al catalogo.

Campos conceptuales:

- `id`
- `book_catalog_id`
- `source`
- `external_id`
- `source_url`
- `raw_quality_score`
- `created_at`
- `updated_at`

## 8. Campos de sincronizacion recomendados

Campos transversales recomendados para entidades sincronizables:

- `local_id`: identificador local generado por Drift.
- `remote_id`: UUID generado por Supabase.
- `user_id`: propietario autenticado.
- `sync_status`: estado local de sincronizacion.
- `created_at`: fecha de creacion.
- `updated_at`: fecha de ultima modificacion.
- `deleted_at`: soft delete.
- `last_synced_at`: ultima sincronizacion correcta.

Decision de identificadores:

- Cada entidad sincronizable tendra siempre `local_id` y `remote_id`.
- `local_id` y `remote_id` son conceptos distintos.
- Nunca se sustituira un identificador por el otro.
- Drift puede seguir usando su identificador local para relaciones y UI.
- Supabase usara su UUID remoto para persistencia y relaciones remotas.
- La capa de sync sera responsable de mapear `local_id` <-> `remote_id`.

Estados iniciales posibles para `sync_status`:

- `local_only`
- `pending_create`
- `pending_update`
- `pending_delete`
- `synced`
- `conflict`
- `sync_error`

## 9. Politica inicial de conflictos

### Sync v1

- Local wins.
- No hard delete.
- Si una entidad existe local y remotamente, gana la version local cuando el usuario inicia sync desde ese dispositivo.
- Si existe `deleted_at`, se respeta como soft delete.
- Los conflictos se registran pero no deben bloquear la app.

### Fases futuras

- Remote merge por campos.
- Revision visual de conflictos.
- Resolucion manual si hay cambios incompatibles.
- Estrategia de versiones por entidad.
- Auditoria de cambios si fuera necesario.

## 10. Roadmap de implementacion por sprints

### Sprint 21 - Diseno tecnico

- Cerrar arquitectura local-first.
- Definir tablas conceptuales.
- Definir estrategia de auth.
- Cerrar campos de sync con `local_id` y `remote_id` separados.
- Definir reglas de privacidad y RLS.
- No tocar codigo productivo salvo documentacion.

### Sprint 22 - Schema Supabase

- Crear schema inicial en Supabase.
- Definir tablas: `profiles`, `user_books`, `reading_sessions`, `reader_settings`, `sync_metadata`.
- Definir RLS por `auth.uid()`.
- Crear migraciones SQL revisables.
- No activar sync todavia.

### Sprint 23 - Auth sin sync

- Integrar Supabase Auth.
- Permitir login con Google.
- Permitir login con correo y contrasena.
- No implementar Apple, Facebook, GitHub, Discord, Magic Link ni login anonimo.
- Mantener app usable sin login.
- Mostrar estado de sesion en Ajustes.
- Crear/actualizar `profiles`.
- No subir biblioteca todavia.

### Sprint 24 - Sync manual

- Anadir campos de sync a Drift.
- Asociar datos locales a `user_id`.
- Implementar push manual local -> Supabase.
- Implementar pull manual Supabase -> local para dispositivo nuevo.
- Politica v1: local wins.
- Soft delete con `deleted_at`.

### Sprint 25 - Sync automatica progresiva

- Sincronizar en momentos controlados.
- Reintentos seguros.
- Estado visual de ultima sincronizacion.
- Manejo basico de errores.
- Evitar bloquear UI por red.

### Sprint 26 - Catalogo incremental

- Crear `book_catalog` y `book_sources`.
- Guardar resultados seleccionados por usuarios de forma normalizada.
- Reusar catalogo antes de consultar Open Library.
- Mantener Open Library como fuente externa.
- Preparar enriquecimiento futuro de libros manuales.

## 11. Riesgos tecnicos

- Perder datos locales durante login o primera sync.
- Duplicar libros al asociar datos locales y remotos.
- Conflictos entre dispositivos con cambios simultaneos.
- RLS mal configurado exponiendo datos entre usuarios.
- Dependencia excesiva de red si se rompe local-first.
- Consultas directas a Supabase desde UI que eviten Drift y rompan Offline First.
- Migraciones Drift complejas al agregar campos de sync.
- Diferencias entre IDs locales y remotos.
- Borrados permanentes accidentales si no se respeta `deleted_at`.
- OAuth Web/PWA con redirects mal configurados.
- Configuracion incompleta de email/password, recuperacion de contrasena o verificacion de correo en Supabase Auth.
- Sync automatica prematura antes de tener observabilidad suficiente.

## 12. Decisiones pendientes

- Definir si `profiles.display_name` se alimenta desde Supabase metadata, perfil lector local o ambos.
- Definir si `profiles.avatar_url` se muestra en UI desde Google o queda reservado para futuro.
- Definir copy final de autenticacion: `Continuar con Google` y `Continuar con correo`.
- Definir cuando habilitar verificacion obligatoria de correo.
- Definir estrategia de `device_id`.
- Definir formato final de `sync_status`.
- Definir alcance exacto de sync v1: libros, sesiones, settings o subset.
- Definir experiencia UX para asociar datos locales tras login.
- Definir pantalla de estado de sync.
- Definir si las notas de sesiones/libros se sincronizan desde v1 o en fase posterior.
- Definir reglas exactas de poblamiento automatico de `book_catalog` desde busquedas y selecciones de Open Library.
- Definir estrategia final de deduplicacion remota del catalogo global.

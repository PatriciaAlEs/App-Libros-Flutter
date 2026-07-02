# QA-001 - Supabase Auth

Fecha: 2026-07-02

Alcance: validacion manual de Supabase Auth para la PWA de ReadPp antes de abrirla al publico. Google queda fuera hasta confirmar que el provider OAuth externo esta configurado en Supabase.

## Prerrequisitos

- Ejecutar la PWA con `SUPABASE_URL` y `SUPABASE_ANON_KEY` validos.
- Confirmar en Supabase que Email Auth esta habilitado.
- Usar una cuenta de prueba nueva y una cuenta existente.
- Si Supabase exige confirmacion por email, tener acceso al inbox de prueba.

## Casos de validacion

### Crear cuenta con email

1. Abrir ReadPp.
2. Ir a `Perfil` > `Crear cuenta o iniciar sesion`.
3. Pulsar `Crear cuenta`.
4. Introducir email y contrasena validos.
5. Confirmar que la app muestra `Sesion iniciada` o, si Supabase requiere confirmacion, completar el flujo desde el email y volver a iniciar sesion.
6. Verificar en Supabase Auth que el usuario fue creado.

Resultado esperado: la cuenta existe en Supabase y ReadPp reconoce la sesion tras completar el flujo requerido por el proyecto.

### Login con email

1. Cerrar sesion si hay una sesion activa.
2. Ir a `Perfil` > `Crear cuenta o iniciar sesion` > `Ya tengo una cuenta`.
3. Introducir email y contrasena de una cuenta existente.
4. Pulsar `Iniciar sesion`.

Resultado esperado: ReadPp muestra `Sesion iniciada`, el email aparece en Cuenta y `SyncStatusCard` queda visible.

### Logout

1. Con sesion iniciada, abrir `Perfil`.
2. Pulsar `Cerrar sesion`.

Resultado esperado: ReadPp vuelve a `Modo local`, oculta `SyncStatusCard` y permite iniciar sesion de nuevo.

### Recuperacion de sesion

1. Iniciar sesion con email.
2. Recargar la PWA.
3. Cerrar la pestana o navegador y abrir ReadPp de nuevo.

Resultado esperado: la sesion se recupera automaticamente y `Perfil` sigue mostrando la cuenta activa sin pedir login de nuevo.

### Google login

1. No validar como aprobado hasta configurar Google OAuth en Supabase.
2. Cuando el provider este configurado, probar `Continuar con Google` desde `Perfil/Auth`.

Resultado esperado actual: Google queda condicionado a configuracion externa; no se considera bloqueo de QA-001 para email/password.

## Criterio de avance a QA-002

QA-002 solo debe reanudarse cuando los casos de crear cuenta, login, logout y recuperacion de sesion con email esten aprobados en la PWA.

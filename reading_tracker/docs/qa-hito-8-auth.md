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
# Corrección reactiva posterior a validación manual

## Causas encontradas

`AuthController` comenzaba con un estado anónimo visible mientras ejecutaba en
paralelo `getCurrentUser()` y escuchaba `onAuthStateChange`. Un primer evento
sin usuario podía renderizar prematuramente modo local antes de que Supabase
terminara de restaurar el callback OAuth. Además, `signInWithOAuth()` se trataba
como una operación completa al iniciar el redirect: el controller apagaba el
loading sin esperar una sesión confirmada y el botón Google volvía a quedar
activo, permitiendo un segundo intento.

LibrerIA no tenía una Home autenticada alternativa: existe un único
`HomeScreen`. Sin embargo, su acceso estaba condicionado por un feature flag y
dentro de la rama `books.data`. La integración corregida conserva una única
`LibreriaEntryCard` canónica, siempre visible en Home tanto antes como después
de autenticación y apuntando a `/coach`.

## Flujo corregido

La restauración dispone ahora de `isRestoring`. El controller se suscribe antes
de resolver el usuario actual y espera tanto la consulta inicial como el primer
evento del stream, usando el evento más reciente como autoridad. Durante esta
fase Account, Perfil y Auth muestran un indicador discreto y no presentan modo
local ni habilitan un segundo submit.

El repositorio devuelve el booleano real de `signInWithOAuth()`. Una
cancelación (`false`) limpia loading sin error grave; un redirect iniciado
mantiene loading hasta que `onAuthStateChange` confirma la sesión. Auth navega a
Home únicamente después de observar la transición autenticada. No se añaden
delays, reloads ni navegación previa a la sesión.

Google queda como acción única `Continuar con Google` para cuentas nuevas y
existentes. El correo mantiene `Entrar con correo` y `Crear una cuenta`. Los
enlaces de modo son `¿Ya tienes una cuenta? Inicia sesion` exclusivamente en
registro y `¿Aun no tienes cuenta? Registrate` en login. La pantalla de
transición deja de presentar `Ya tengo una cuenta` como camino separado de
Google.

Los errores distinguen credenciales, confirmación pendiente, cuenta existente,
password débil, rate limit, conectividad, configuración no disponible y fallo
de restauración. Las cancelaciones OAuth no producen error técnico.

## Cobertura añadida y riesgos

Los tests usan repositorios fake y streams controlables para restauración,
transición anónimo/autenticado, navegación tras el primer evento, bloqueo de
doble Google submit, logout, textos login/registro y permanencia de LibrerIA al
cambiar la sesión. No requieren una cuenta Google real.

El callback sigue dependiendo de que `AUTH_REDIRECT_URL`, Supabase Redirect
URLs y Google OAuth estén configurados con el mismo origen. La validación manual
en preview/producción continúa pendiente. Por restricción de esta corrección no
se ejecutaron `dart format`, `flutter analyze` ni `flutter test`.

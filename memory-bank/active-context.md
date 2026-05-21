# Active Context

## Foco actual

Cerrar el MVP alrededor de sesiones y documentacion, con Stats ya considerada funcionalmente cerrada para MVP.

## Riesgos actuales

- Duplicar informacion entre documentos antiguos (`CONTEXT.md`, `memory-bank/mvp/*`) y la memoria nueva.
- Arrastrar suposiciones sobre backend, login, Firebase, Stripe o usuarios que no existen en el codigo.
- Mantener textos con mojibake en UI/documentacion sin distinguir entre problema documentado y feature nueva.
- Olvidar invalidar Stats si se implementa eliminar sesiones en el futuro.

## Siguiente paso recomendado

Priorizar eliminar sesiones desde el detalle de dia o validar persistencia completa del flujo libro en lectura -> sesion -> calendario -> refresh. La edicion de sesiones ya esta implementada y validada con `flutter test` y `flutter analyze`.

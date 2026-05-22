# Active Context

## Foco actual

Cerrar el MVP alrededor de sesiones y documentacion, con Stats ya considerada funcionalmente cerrada para MVP.

## Riesgos actuales

- Duplicar informacion entre documentos antiguos (`CONTEXT.md`, `memory-bank/mvp/*`) y la memoria nueva.
- Arrastrar suposiciones sobre backend, login, Firebase, Stripe o usuarios que no existen en el codigo.
- Mantener textos legacy con mojibake fuera del alcance ya corregido de libros/sesiones sin distinguir entre problema documentado y feature nueva.
- Olvidar invalidar Stats si se implementa eliminar sesiones en el futuro.
- No confundir la terminologia tecnica `ReadingSession` con la terminologia de UI de usuario, que ahora usa "tiempo/rato de lectura".
- Evitar llamadas excesivas a Open Library si se vuelve a tocar busqueda automatica; mantener debounce, minimo de caracteres y proteccion contra resultados obsoletos.

## Siguiente paso recomendado

Priorizar eliminar sesiones desde el detalle de dia o validar persistencia completa del flujo libro en lectura -> tiempo de lectura -> calendario -> refresh. La edicion de sesiones ya esta implementada y validada con `flutter test` y `flutter analyze`; la fase Quick Wins UX, la mejora UX de alta de libros y la busqueda automatica con debounce ya quedaron completadas con tests actualizados.

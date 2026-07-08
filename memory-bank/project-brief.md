# Project Brief

## Producto

`reading_tracker` es una app Flutter para seguimiento personal de lectura. El objetivo del MVP es permitir registrar libros, gestionar su estado de lectura, registrar sesiones, visualizar actividad en calendario, consultar estadisticas basicas y ver insights de lectura.

## Principios

- Mobile-first: la experiencia principal debe funcionar bien en pantallas pequenas.
- Mantenible y sencillo: preferir soluciones directas, con poco acoplamiento y sin arquitectura sobredimensionada.
- Persistencia real: los datos principales se guardan con Drift + SQLite.
- IA con control tecnico: los asistentes pueden acelerar tareas, pero deben respetar la arquitectura existente, explicar cambios y evitar refactors innecesarios.

## Alcance del MVP

- Libros: busqueda/alta, listado, detalle, estado, progreso y eliminacion.
- Sesiones de lectura: crear sesiones por libro y dia, con minutos y nota opcional.
- Calendario: vista mensual, vista semanal y detalle de dia.
- Estadisticas: resumen basico a partir de libros y sesiones reales.
- Insights: perfil lector, mejores lecturas y curiosidades a partir de datos reales.
- Navegacion principal: tabs Inicio, Biblioteca, Progreso, Insights y Ajustes.
- Design System: temas Burgundy/Forest, tokens visuales y componentes reutilizables.
- Branding: identidad ReadPp, tipografia Playfair/Inter, iconografia centralizada y motion base.
- Home Premium: lectura actual protagonista, metricas compactas, objetivo anual y actividad reciente.
- Alpha QA: shared header basado en Biblioteca, card compartida de lectura actual, carrusel de multiples lecturas activas, calendario/diario sincronizados, polish de reto lector/insights y QA manual previo a release completado.
- Busqueda de libros: Open Library como proveedor primario, Google Books como fallback, alta manual como ultima opcion y deduplicacion por ISBN, proveedor+externalId o titulo+autor normalizados.
- Cierre de fase actual: Hito 9 UX & Product completado, Web/PWA lista en Vercel, APK de cierre generada y base preparada para Beta publica.
- Web/PWA vigente: `https://readpp-web-alpha.vercel.app`.
- APK registrada: package `com.readpp.app`, `versionName=1.0.0`, `versionCode=1`, SHA1 `8a771c6ab44b69cba34ad009877a1e8e3ef4b3b1`.
- Validacion vigente de cierre: `flutter analyze` sin issues y `flutter test` 178/178.
- Supabase: backend progresivo para Auth y sincronizacion, manteniendo Drift/SQLite como fuente local.
- Auth: Login Email y Login Google completados.
- Sync: Books, Reading Sessions, Reader Profile y Annual Goal sincronizados con Supabase.
- PWA: Flutter Web desplegado en Vercel desde `build/web`.
- Observabilidad: Sentry integrado por `dart-define`.
- Analytics: PostHog integrado mediante `ReadPpAnalytics` y configuracion por `dart-define`.

## Fuera de alcance por ahora

- Backend propio.
- JWT/backend propio adicional fuera de Supabase.
- Social, recomendaciones avanzadas o gamificacion compleja.
- Arquitecturas pesadas que no aporten valor inmediato al MVP.

## Roadmap vigente

- Beta publica.
- AI Assistant.
- Automatizaciones.
- Mejoras de producto manteniendo local-first.

# LibrerIA Technical Roadmap

> Backlog técnico oficial de LibrerIA, derivado de `LibrerIA Product Design v1`.
>
> Estado: planificación; no autoriza implementación por sí mismo  
> Versión: 1.0  
> Fecha: 9 de julio de 2026

## 0. Propósito y reglas de alcance

Este documento transforma el roadmap funcional de LibrerIA en unidades técnicas pequeñas, comprobables y estimables. Cada tarea está diseñada para ocupar aproximadamente entre 1 y 3 horas de trabajo efectivo.

La referencia de producto y arquitectura sigue siendo `docs/LibrerIA Product Design v1.md`. Si este backlog contradice esa especificación, prevalece Product Design hasta que la decisión se documente.

### 0.1 Reconciliación del alcance

El Product Design vigente define como **MVP corto**:

- 13 preguntas canónicas: 1–8, 15, 22, 23, 31 y 36;
- 12 rutas deterministas sin LLM;
- una recomendación interna como único caso LLM obligatorio;
- Tool Manager de solo lectura;
- ContextBuilder sin memoria persistente;
- navegación sin mutaciones;
- sin catálogo remoto, automatizaciones ni operaciones sobre datos.

Por tanto:

- **Sprint 1–3 forman el candidato a MVP corto.**
- **Sprint 4–6 conservan el orden solicitado, pero son backlog posterior al gate del MVP.**
- Sprint 4 solo puede incorporar Open Library después del MVP, porque el catálogo remoto está explícitamente fuera del MVP corto.
- Sprint 5 pertenece a la fase de acciones seguras y no forma parte del MVP corto.
- Sprint 6 pertenece a la evolución de insights y distribución contextual; no forma parte del MVP corto.

Esta separación evita llamar “MVP” a seis sprints cuyo alcance incluye capacidades que Product Design pospone. Los sprints 4–6 no se eliminan ni se adelantan: quedan preparados como continuación del roadmap.

### 0.2 Decisiones arquitectónicas obligatorias

Todo sprint debe respetar:

- `DA-LIA-001`: LibrerIA Engine decide la ruta.
- `DA-LIA-002`: agente especializado en lectura y ReadPp.
- `DA-LIA-003`: memoria mínima, sin memoria permanente del modelo.
- `DA-LIA-004`: ContextBuilder dinámico y mínimo.
- `DA-LIA-005`: inteligencia híbrida; no usar LLM para reglas o cálculos.
- `DA-LIA-006`: Engine depende de `AiProvider`, nunca de un SDK concreto.

### 0.3 Criterios de producto obligatorios

Los Product Success Criteria `PSC-001` a `PSC-007` son gates de producto. En particular:

- `PSC-003` y `PSC-006` son bloqueantes: no se aceptan datos personales sin trazabilidad ni datos inventados.
- `PSC-004` exige medir por separado rutas locales y rutas LLM.
- `PSC-005` se consigue mediante ContextBuilder y conversación reciente, no mediante memoria permanente.
- `PSC-007` impide cerrar el MVP solo porque el chat funcione técnicamente.

### 0.4 Convenciones del backlog

- Cada ID identifica una tarea entregable y revisable.
- Duración objetivo por tarea: **1–3 horas**.
- Una tarea que supere 3 horas debe dividirse antes de empezar.
- Las estimaciones `S`, `M` y `L` describen el tamaño relativo del sprint, no horas exactas.
- Las tareas documentales, de prueba y observabilidad son parte del trabajo, no actividades opcionales.
- No se introduce memoria vectorial, SQL generado, acceso directo del modelo a Drift/Supabase ni SDK de proveedor dentro del Engine.

---

## Sprint 1 — LibrerIA Experience

**Estimación relativa:** M

### Objetivo del sprint

Crear la entrada visible de LibrerIA dentro de ReadPp, establecer su UI base y definir el esqueleto del Engine sin conectar herramientas, contexto ni proveedor de IA.

Al terminar, el usuario puede abrir una experiencia navegable y accesible, pero todavía no conversar con un modelo ni consultar datos reales mediante LibrerIA.

### Épica 1.1 — Feature LibrerIA

| ID | Tarea técnica | Resultado esperado | Estimación |
|---|---|---|---|
| LIA-1.1.1 | Crear la estructura `features/libreria` por capas | Directorios y exports coherentes con la arquitectura por features | 1 h |
| LIA-1.1.2 | Definir los modelos de presentación mínimos de LibrerIA | Estados de inicio, carga, respuesta, error y no disponible | 2 h |
| LIA-1.1.3 | Crear el provider raíz de la feature sin dependencias de IA | Punto de composición sustituible para la UI | 2 h |
| LIA-1.1.4 | Añadir feature flag local de LibrerIA | La entrada puede activarse o desactivarse sin afectar ReadPp | 2 h |
| LIA-1.1.5 | Documentar límites del módulo y dependencias permitidas | Nota técnica breve dentro de la feature o docs | 1 h |

### Épica 1.2 — Navegación

| ID | Tarea técnica | Resultado esperado | Estimación |
|---|---|---|---|
| LIA-1.2.1 | Registrar la ruta principal de LibrerIA | Ruta nombrada disponible desde `MaterialApp` | 1 h |
| LIA-1.2.2 | Añadir una entrada principal detrás del feature flag | Acceso visible solo cuando LibrerIA esté habilitada | 2 h |
| LIA-1.2.3 | Definir argumentos de navegación contextuales | Contrato para `bookId`, pantalla de origen y periodo opcional | 2 h |
| LIA-1.2.4 | Implementar retorno seguro a la pantalla de origen | Back navigation consistente en Android y Web | 1 h |
| LIA-1.2.5 | Añadir tests de rutas y feature flag | La ruta no rompe la navegación existente | 2 h |

### Épica 1.3 — UI base

| ID | Tarea técnica | Resultado esperado | Estimación |
|---|---|---|---|
| LIA-1.3.1 | Crear `LibreriaScreen` con scaffold y SafeArea | Pantalla base alineada con ReadPp | 2 h |
| LIA-1.3.2 | Crear encabezado y texto de propósito especializado | La UI comunica que LibrerIA ayuda con lectura | 1 h |
| LIA-1.3.3 | Crear contenedor de insight inicial en estado placeholder | Espacio preparado para `PSC-001`, sin datos inventados | 2 h |
| LIA-1.3.4 | Crear chips de preguntas sugeridas no funcionales | Sugerencias limitadas a los intents del MVP | 2 h |
| LIA-1.3.5 | Crear campo de entrada y botón de envío deshabilitado | Base visual del chat sin simular funcionalidad | 2 h |
| LIA-1.3.6 | Crear tarjeta base de métrica | Componente accesible con valor, unidad y periodo | 2 h |
| LIA-1.3.7 | Crear tarjeta base de libro | Portada, título, autor, estado y progreso opcionales | 3 h |
| LIA-1.3.8 | Crear tarjeta base de límite/error | Mensaje, causa y acción alternativa | 2 h |
| LIA-1.3.9 | Adaptar UI a Burgundy/Forest y texto ampliado | Diseño consistente y sin overflow | 2 h |
| LIA-1.3.10 | Añadir semantics, foco y labels accesibles | Componentes base compatibles con lector de pantalla | 2 h |
| LIA-1.3.11 | Añadir widget tests de estados visuales | Inicio, disabled, error y layouts básicos cubiertos | 3 h |

### Épica 1.4 — Engine Skeleton

| ID | Tarea técnica | Resultado esperado | Estimación |
|---|---|---|---|
| LIA-1.4.1 | Definir `LibreriaRequest` | Entrada neutral con texto y metadatos contextuales | 2 h |
| LIA-1.4.2 | Definir `LibreriaResponse` y estados terminales | Salidas `answered`, `unsupported`, `tool_failed`, etc. | 2 h |
| LIA-1.4.3 | Definir enum de rutas del Engine | `localDeterministic`, `llmAssisted`, `clarification`, `unsupported`, `actionConfirmation` | 1 h |
| LIA-1.4.4 | Crear interfaz de `LibreriaEngine` | Contrato sin SDK, base de datos ni Flutter UI | 2 h |
| LIA-1.4.5 | Crear implementación skeleton con ruta `unsupported` | Respuesta segura para funciones aún no disponibles | 2 h |
| LIA-1.4.6 | Añadir guard inicial de dominio | Peticiones claramente ajenas a lectura no progresan | 2 h |
| LIA-1.4.7 | Añadir tests unitarios del skeleton | Estados y guard de dominio verificados | 3 h |

### Dependencias

- Design system, tema y navegación existentes de ReadPp.
- Convenciones de Riverpod y arquitectura por features.
- Product Design v1 aprobado.
- No depende de proveedor de IA ni red.

### Riesgos

- Convertir la UI placeholder en una falsa promesa de funcionalidad.
- Añadir demasiados componentes antes de validar la conversación.
- Alterar la navegación principal más de lo necesario.
- Introducir lógica de clasificación en widgets.

### Criterios de aceptación

- LibrerIA puede activarse y desactivarse mediante feature flag.
- La pantalla abre y vuelve correctamente en Android y Web.
- La UI comunica el propósito especializado.
- Los componentes básicos respetan tema y accesibilidad.
- El Engine existe como contrato independiente y rechaza peticiones fuera de dominio.
- No existe ninguna llamada a LLM, Drift, Supabase u Open Library desde el Engine.

### Definition of Done del sprint

- Todas las tareas aceptadas o replanificadas explícitamente.
- Tests nuevos en verde.
- `flutter analyze` sin nuevos problemas.
- QA visual básico en Android y Web.
- Sin secretos, SDKs de IA ni telemetría de contenido.
- Documentación del módulo actualizada.

---

## Sprint 2 — Context Engine

**Estimación relativa:** L

### Objetivo del sprint

Construir la infraestructura local y comprobable que permite al Engine obtener contexto mínimo y datos reales mediante contratos tipados, todavía sin proveedor real ni chat operativo.

### Épica 2.1 — ContextBuilder

| ID | Tarea técnica | Resultado esperado | Estimación |
|---|---|---|---|
| LIA-2.1.1 | Definir `ContextRequest` | Intent, entidades, origen, periodo y presupuesto | 2 h |
| LIA-2.1.2 | Definir `LibreriaContext` | Hechos, métricas, ausencias, conversación y capacidades | 3 h |
| LIA-2.1.3 | Definir interfaz `ContextBuilder` | Puerto independiente de UI y proveedor | 1 h |
| LIA-2.1.4 | Implementar selector de contexto por intent | Cada intent declara categorías permitidas | 3 h |
| LIA-2.1.5 | Implementar límites de libros, sesiones y mensajes | No se puede volcar historial completo | 2 h |
| LIA-2.1.6 | Implementar agregación antes que detalle | Métricas sustituyen listas cuando son suficientes | 3 h |
| LIA-2.1.7 | Implementar exclusión de IDs técnicos y datos de cuenta | El contexto no contiene email, tokens ni credenciales | 2 h |
| LIA-2.1.8 | Representar campos ausentes y cobertura del dato | El modelo puede distinguir ausencia de cero | 2 h |
| LIA-2.1.9 | Añadir versión de esquema y fuentes al contexto | Trazabilidad técnica sin contenido sensible | 2 h |
| LIA-2.1.10 | Añadir tests de minimización por intent | Contextos contienen solo categorías autorizadas | 3 h |
| LIA-2.1.11 | Añadir tests de límites y exclusiones | Listas acotadas y campos sensibles ausentes | 3 h |

### Épica 2.2 — Tool Manager

| ID | Tarea técnica | Resultado esperado | Estimación |
|---|---|---|---|
| LIA-2.2.1 | Definir `ToolId` y categorías de herramienta | Lectura, navegación y escritura diferenciadas | 1 h |
| LIA-2.2.2 | Definir `ToolRequest` y `ToolResult` comunes | Envoltorio tipado con éxito y error normalizados | 2 h |
| LIA-2.2.3 | Crear registro estático del Tool Manager | Solo herramientas aprobadas están disponibles | 2 h |
| LIA-2.2.4 | Implementar validación de herramienta registrada | Peticiones desconocidas se rechazan | 2 h |
| LIA-2.2.5 | Implementar límites de resultados | El Tool Manager recorta listas antes del contexto | 2 h |
| LIA-2.2.6 | Definir taxonomía común de errores | Not found, invalid input, unavailable y internal | 2 h |
| LIA-2.2.7 | Añadir telemetría técnica saneada | ID, duración y resultado sin payload personal | 2 h |
| LIA-2.2.8 | Bloquear herramientas de escritura en modo MVP | El catálogo MVP es estrictamente de solo lectura | 2 h |
| LIA-2.2.9 | Añadir tests de registro, límites y bloqueo | Políticas verificadas sin infraestructura real | 3 h |

### Épica 2.3 — Tool Contracts

| ID | Tarea técnica | Resultado esperado | Estimación |
|---|---|---|---|
| LIA-2.3.1 | Definir contrato `get_reader_snapshot` | Lecturas activas, última actividad y objetivo mínimos | 3 h |
| LIA-2.3.2 | Definir contrato `search_library` | Texto y filtros con resultados limitados | 2 h |
| LIA-2.3.3 | Definir contrato `get_book_details` | Libro identificado con progreso y metadatos | 2 h |
| LIA-2.3.4 | Definir contrato `list_books` | Filtros y ordenación determinista | 2 h |
| LIA-2.3.5 | Definir contrato `get_reading_sessions` | Libro o rango temporal obligatorio | 2 h |
| LIA-2.3.6 | Definir contrato `get_reading_statistics` | Métricas oficiales y periodo | 2 h |
| LIA-2.3.7 | Definir contrato `get_annual_goal` | Objetivo, completados, fecha de corte y ritmo | 2 h |
| LIA-2.3.8 | Adaptar snapshot a repositorios existentes | Datos reales sin acceso directo del Engine | 3 h |
| LIA-2.3.9 | Adaptar consultas de biblioteca | Reutilización de repositorio y matcher existentes | 3 h |
| LIA-2.3.10 | Adaptar sesiones y estadísticas | Reutilización de casos de uso oficiales | 3 h |
| LIA-2.3.11 | Adaptar objetivo anual | Resultado tipado desde fuente de ReadPp | 2 h |
| LIA-2.3.12 | Añadir fixtures deterministas por herramienta | Casos completos, vacíos y datos parciales | 3 h |

### Épica 2.4 — FakeAiProvider

| ID | Tarea técnica | Resultado esperado | Estimación |
|---|---|---|---|
| LIA-2.4.1 | Definir modelos comunes de `AiProvider` | Request, response, usage, error y capability | 3 h |
| LIA-2.4.2 | Definir interfaz `AiProvider` | Puerto sin tipos propietarios | 1 h |
| LIA-2.4.3 | Implementar `FakeAiProvider` configurable | Respuestas y errores deterministas | 2 h |
| LIA-2.4.4 | Añadir soporte fake para cancelación y latencia | Pruebas de estados lentos y cancelados | 2 h |
| LIA-2.4.5 | Añadir tests de contrato sobre el fake | Semántica común validada | 2 h |
| LIA-2.4.6 | Verificar imports prohibidos en Engine | Ningún SDK concreto atraviesa la frontera | 1 h |

### Épica 2.5 — Primeros tests integrados

| ID | Tarea técnica | Resultado esperado | Estimación |
|---|---|---|---|
| LIA-2.5.1 | Probar ruta local “¿qué estoy leyendo?” | Engine → Tool Manager → datos reales/fake | 3 h |
| LIA-2.5.2 | Probar cálculo de porcentaje sin LLM | Definición determinista y ausencia controlada | 2 h |
| LIA-2.5.3 | Probar racha mediante estadística oficial | No se recalcula en el modelo | 2 h |
| LIA-2.5.4 | Probar objetivo anual y fecha de corte | Resultado trazable | 2 h |
| LIA-2.5.5 | Probar biblioteca vacía | `insufficient_data` y alternativa útil | 2 h |
| LIA-2.5.6 | Probar que rutas locales no invocan `AiProvider` | Contador de llamadas igual a cero | 2 h |
| LIA-2.5.7 | Probar petición fuera de dominio | Rechazo antes de herramientas y LLM | 2 h |

### Dependencias

- Sprint 1 completado.
- Repositorios y casos de uso existentes de libros, sesiones, estadísticas y objetivo.
- Definiciones oficiales de métricas de ReadPp.
- No depende de OpenAI ni de conectividad.

### Riesgos

- Duplicar cálculos que ya existen en dominio.
- Construir un ContextBuilder genérico en exceso.
- Exponer entidades Drift en contratos.
- Diseñar `AiProvider` para capacidades todavía no requeridas.
- Confundir ausencia de datos con valor cero.

### Criterios de aceptación

- Las herramientas MVP devuelven datos reales mediante contratos propios.
- El Engine resuelve consultas deterministas sin `AiProvider`.
- ContextBuilder limita y excluye datos conforme al intent.
- Tool Manager bloquea escrituras.
- `FakeAiProvider` permite probar éxito, error, latencia y cancelación.
- No existe memoria permanente ni copia de la base de datos.
- Los fixtures permiten reproducir respuestas completas, vacías y parciales.

### Definition of Done del sprint

- Tests unitarios y de integración del alcance en verde.
- `flutter analyze` sin nuevos problemas.
- Revisión de dependencias: Engine y dominio sin SDKs ni tipos de infraestructura.
- Revisión de privacidad del contexto completada.
- Métricas deterministas trazables hasta Tool Manager.
- Documentación de contratos actualizada.

---

## Sprint 3 — Chat MVP

**Estimación relativa:** L

### Objetivo del sprint

Completar el candidato a MVP corto: permitir preguntas naturales sobre el progreso, responder consultas deterministas desde ReadPp y usar un único proveedor real para la recomendación interna acotada.

### Épica 3.1 — OpenAIProvider

OpenAI es el primer adaptador real solicitado, no una dependencia del Engine. La selección final de modelo, credenciales, retención y ubicación de la llamada sigue requiriendo decisión técnica y legal antes de producción.

| ID | Tarea técnica | Resultado esperado | Estimación |
|---|---|---|---|
| LIA-3.1.1 | Crear módulo adaptador `OpenAiProvider` | Implementación aislada de `AiProvider` | 2 h |
| LIA-3.1.2 | Mapear request común a request OpenAI | Sin filtrar tipos del SDK al Engine | 3 h |
| LIA-3.1.3 | Mapear respuesta OpenAI a respuesta común | Texto, finish reason y usage normalizados | 3 h |
| LIA-3.1.4 | Normalizar errores y timeouts | Taxonomía común consumible por Engine | 3 h |
| LIA-3.1.5 | Implementar cancelación de petición | La UI puede abandonar una respuesta lenta | 2 h |
| LIA-3.1.6 | Cargar configuración sin secretos en repositorio | Configuración inyectada y fallo seguro | 2 h |
| LIA-3.1.7 | Añadir telemetría de modelo, latencia y uso | Sin prompt ni respuesta personal | 2 h |
| LIA-3.1.8 | Ejecutar tests de contrato compartidos | Fake y OpenAI cumplen la misma semántica | 3 h |

### Épica 3.2 — Chat

| ID | Tarea técnica | Resultado esperado | Estimación |
|---|---|---|---|
| LIA-3.2.1 | Definir modelo de mensaje de presentación | User, assistant, status y timestamp local | 2 h |
| LIA-3.2.2 | Conectar input con controlador de chat | Envío validado y estado de carga | 2 h |
| LIA-3.2.3 | Renderizar mensajes de usuario y LibrerIA | UI legible y accesible | 3 h |
| LIA-3.2.4 | Renderizar respuesta local estructurada | Métricas y libros usan tarjetas, no texto libre | 3 h |
| LIA-3.2.5 | Implementar feedback visual inmediato | Cumple percepción de progreso de `PSC-004` | 2 h |
| LIA-3.2.6 | Implementar cancelar respuesta LLM | Cancelación visible y no destructiva | 2 h |
| LIA-3.2.7 | Implementar reintento seguro | No duplica mensajes ni acciones | 2 h |
| LIA-3.2.8 | Implementar estado offline | Consultas locales siguen; ruta LLM informa límite | 3 h |
| LIA-3.2.9 | Conectar chips del MVP al chat | Solo preguntas dentro de las 13 canónicas | 2 h |
| LIA-3.2.10 | Añadir widget tests del flujo de chat | Envío, carga, respuesta, error y cancelación | 3 h |

### Épica 3.3 — Prompt del sistema

| ID | Tarea técnica | Resultado esperado | Estimación |
|---|---|---|---|
| LIA-3.3.1 | Versionar el prompt base de Product Design | Prompt identificable y revisable | 2 h |
| LIA-3.3.2 | Añadir dominio especializado y rechazos | No responde como asistente generalista | 2 h |
| LIA-3.3.3 | Añadir reglas de verdad y evidencia | No presenta inferencias como datos | 2 h |
| LIA-3.3.4 | Añadir reglas anti prompt-injection | Metadatos y notas se tratan como datos | 2 h |
| LIA-3.3.5 | Definir formato de recomendación MVP | Respuesta breve con criterio y candidatos reales | 2 h |
| LIA-3.3.6 | Crear casos golden del prompt | Datos completos, parciales, vacíos y fuera de dominio | 3 h |

### Épica 3.4 — Conversation State

| ID | Tarea técnica | Resultado esperado | Estimación |
|---|---|---|---|
| LIA-3.4.1 | Definir estado efímero de conversación | Mensajes recientes y entidad referenciada | 2 h |
| LIA-3.4.2 | Implementar límite por cantidad de mensajes | Ventana acotada para ContextBuilder | 2 h |
| LIA-3.4.3 | Implementar expiración al cerrar/caducar | No queda memoria permanente del modelo | 2 h |
| LIA-3.4.4 | Resolver referencias recientes simples | “Ese libro” funciona dentro de la ventana | 3 h |
| LIA-3.4.5 | Evitar repetir datos disponibles en herramientas | ContextBuilder consulta ReadPp antes de preguntar | 3 h |
| LIA-3.4.6 | Añadir tests de aislamiento entre conversaciones | Ningún contexto cruza sesiones o usuarios | 3 h |

### Épica 3.5 — Integración Engine ↔ AI

| ID | Tarea técnica | Resultado esperado | Estimación |
|---|---|---|---|
| LIA-3.5.1 | Implementar clasificación de los 13 intents MVP | Rutas explícitas y cerradas | 3 h |
| LIA-3.5.2 | Enrutar 12 intents a resolución local | Cero llamadas LLM para consultas deterministas | 3 h |
| LIA-3.5.3 | Enrutar pregunta 36 a recomendación asistida | Única familia LLM obligatoria | 2 h |
| LIA-3.5.4 | Prefiltrar candidatos localmente | Contexto del LLM contiene pocos libros reales | 3 h |
| LIA-3.5.5 | Construir request mediante ContextBuilder | Paquete mínimo, trazable y versionado | 2 h |
| LIA-3.5.6 | Validar salida del proveedor en el Engine | Respuesta fuera de contrato se rechaza | 3 h |
| LIA-3.5.7 | Añadir reason code de enrutamiento | Cada llamada LLM tiene justificación observable | 2 h |
| LIA-3.5.8 | Integrar estados Engine con UI | Answered, insufficient, unsupported y failed | 3 h |
| LIA-3.5.9 | Medir latencia local y LLM por separado | Datos para `PSC-004` | 2 h |
| LIA-3.5.10 | Añadir pruebas end-to-end de 13 preguntas | Variantes naturales y fixtures conocidos | 3 h |
| LIA-3.5.11 | Añadir pruebas de cero invenciones | Campos ausentes nunca se completan | 3 h |
| LIA-3.5.12 | Ejecutar protocolo de ayuda real | Evidencia inicial para `PSC-001` y `PSC-007` | 3 h |

### Dependencias

- Sprint 2 completado.
- Decisión sobre ubicación segura de la llamada al proveedor.
- Modelo OpenAI y política de retención aprobados.
- Configuración segura disponible mediante el mecanismo existente.
- Conectividad solo para la ruta LLM.

### Riesgos

- Introducir la clave del proveedor en el cliente.
- Permitir que OpenAI filtre tipos o errores al Engine.
- Enviar demasiado historial para mejorar aparentemente la respuesta.
- Usar LLM en consultas deterministas por comodidad.
- Cerrar el sprint por tener chat sin demostrar utilidad.
- Latencia o coste superiores al objetivo.

### Criterios de aceptación

- Las 13 preguntas MVP funcionan con variantes naturales.
- Las 12 consultas deterministas no invocan `AiProvider`.
- La recomendación usa únicamente candidatos reales prefiltrados.
- El usuario recibe un insight útil al abrir LibrerIA cuando hay datos.
- No se inventan cifras, libros ni sesiones.
- El contexto reciente evita repeticiones sin persistirse.
- Las rutas local y LLM tienen latencia y errores observables.
- Las peticiones ajenas a lectura se rechazan antes del proveedor.

### Definition of Done del sprint

- `PSC-001` a `PSC-007` evaluados.
- `PSC-003` y `PSC-006` sin defectos abiertos.
- Tests unitarios, widget, integración y contrato en verde.
- `flutter analyze` sin nuevos problemas.
- QA Android y Web/PWA completado.
- Revisión de privacidad y secretos completada.
- Feature flag y desactivación segura verificadas.
- Product review confirma ayuda concreta; un chat funcional por sí solo no cierra el sprint.

### Gate de alcance — MVP corto

Al cerrar Sprint 3 se decide si el MVP corto cumple su Definition of Done. No se inicia Sprint 4 para “completar” métricas fallidas añadiendo funcionalidades. Los fallos del MVP se corrigen dentro de su alcance.

---

## Sprint 4 — Recommendations

**Estimación relativa:** L

**Clasificación:** post-MVP corto; evolución de la Fase 2 y descubrimiento remoto limitado.

### Objetivo del sprint

Mejorar la recomendación dentro de la biblioteca con criterios visibles e incorporar Open Library únicamente para descubrimiento solicitado, sin convertir LibrerIA en un buscador general ni guardar libros automáticamente.

### Épica 4.1 — Recommendation Engine

| ID | Tarea técnica | Resultado esperado | Estimación |
|---|---|---|---|
| LIA-4.1.1 | Definir `RecommendationRequest` | Criterios explícitos y límites | 2 h |
| LIA-4.1.2 | Definir `RecommendationCandidate` | Datos reales y razones disponibles | 2 h |
| LIA-4.1.3 | Implementar filtro local por estado | Solo libros elegibles | 2 h |
| LIA-4.1.4 | Implementar filtro por longitud conocida | Libros sin páginas se separan, no se inventan | 2 h |
| LIA-4.1.5 | Implementar filtro por autor y género | Solo metadatos existentes | 2 h |
| LIA-4.1.6 | Implementar ordenación determinista de candidatos | Resultado estable para tests | 2 h |
| LIA-4.1.7 | Implementar límite de candidatos al LLM | Contexto pequeño y predecible | 1 h |
| LIA-4.1.8 | Añadir explicación estructurada de filtros | La UI puede mostrar por qué se eligieron | 2 h |
| LIA-4.1.9 | Añadir tests de filtros y orden | Casos completos y metadatos ausentes | 3 h |

### Épica 4.2 — Open Library

| ID | Tarea técnica | Resultado esperado | Estimación |
|---|---|---|---|
| LIA-4.2.1 | Definir contrato `search_book_catalog` | Query, límite, resultados y fuente | 2 h |
| LIA-4.2.2 | Adaptar repositorio de búsqueda existente | Reutiliza Open Library y fallback vigente | 3 h |
| LIA-4.2.3 | Registrar herramienta remota como solo lectura | No crea ni modifica libros | 1 h |
| LIA-4.2.4 | Añadir timeout y error normalizado | Fallo remoto no afecta biblioteca local | 2 h |
| LIA-4.2.5 | Añadir estado sin conexión | Alternativa local clara | 2 h |
| LIA-4.2.6 | Limitar campos enviados al LLM | Solo metadatos necesarios | 2 h |
| LIA-4.2.7 | Añadir tests con datasource fake | Sin dependencia de red en suite | 3 h |

### Épica 4.3 — Recomendaciones personalizadas

| ID | Tarea técnica | Resultado esperado | Estimación |
|---|---|---|---|
| LIA-4.3.1 | Añadir intents 35–40 al clasificador | Rutas explícitas, no conversación libre | 3 h |
| LIA-4.3.2 | Definir chips de longitud, género y ánimo | Refinamiento visible y acotado | 2 h |
| LIA-4.3.3 | Construir contexto agregado de hábitos | Sin historial completo ni memoria | 3 h |
| LIA-4.3.4 | Generar comparación estructurada de dos libros | Criterios visibles y datos ausentes | 3 h |
| LIA-4.3.5 | Generar recomendación diversa | Basada en diferencias demostrables | 3 h |
| LIA-4.3.6 | Mostrar razones en tarjeta de libro | Evidencia separada de sugerencia | 2 h |
| LIA-4.3.7 | Añadir navegación a detalle | La recomendación no modifica datos | 1 h |
| LIA-4.3.8 | Implementar rechazo si no hay candidatos | `insufficient_data` útil | 2 h |

### Épica 4.4 — Tests

| ID | Tarea técnica | Resultado esperado | Estimación |
|---|---|---|---|
| LIA-4.4.1 | Crear fixtures de bibliotecas variadas | Corta, larga, géneros faltantes y vacía | 3 h |
| LIA-4.4.2 | Probar recomendación sin LLM cuando es determinista | Filtro exacto resuelto localmente | 2 h |
| LIA-4.4.3 | Probar recomendaciones LLM ancladas | Solo aparecen candidatos proporcionados | 3 h |
| LIA-4.4.4 | Probar cero invención de metadatos | Páginas y géneros ausentes se declaran | 2 h |
| LIA-4.4.5 | Probar Open Library offline/error | Biblioteca local sigue disponible | 2 h |
| LIA-4.4.6 | Probar que buscar no guarda | Cero mutaciones tras resultados | 2 h |
| LIA-4.4.7 | Evaluar preguntas 35–40 | Datos completos y parciales | 3 h |

### Dependencias

- MVP corto validado al final del Sprint 3.
- Repositorio de búsqueda de libros existente.
- Contratos y telemetría del Tool Manager.
- Ninguna dependencia de Sprint 5.

### Riesgos

- Convertir recomendaciones en un sistema de catálogo generalista.
- Confundir “personalizado” con almacenar perfil paralelo.
- Añadir embeddings o ranking avanzado sin evidencia.
- Introducir alta de libros dentro de un sprint de solo lectura.
- Enviar demasiados candidatos al proveedor.

### Criterios de aceptación

- Los filtros exactos se resuelven localmente.
- El LLM solo recibe candidatos reales y limitados.
- Las razones de recomendación son visibles.
- Los datos ausentes se reconocen.
- Open Library se usa solo cuando el usuario solicita descubrimiento.
- La búsqueda no modifica la biblioteca.
- Las preguntas 35–40 pasan evaluación.

### Definition of Done del sprint

- Tests de filtros, proveedor, herramientas y UI en verde.
- `flutter analyze` sin nuevos problemas.
- QA de recomendaciones con bibliotecas completas y parciales.
- Revisión de coste y tamaño de contexto.
- Sin memoria nueva, embeddings ni mutaciones.
- Métricas `PSC-003`, `PSC-004` y `PSC-006` preservadas.

---

## Sprint 5 — Actions

**Estimación relativa:** L

**Clasificación:** post-MVP corto; Fase 3 de acciones seguras.

### Objetivo del sprint

Permitir acciones explícitas y confirmadas sobre la biblioteca y la actividad de lectura, reutilizando casos de uso existentes y sin conceder al LLM acceso directo a persistencia.

### Épica 5.1 — Tool Calling

| ID | Tarea técnica | Resultado esperado | Estimación |
|---|---|---|---|
| LIA-5.1.1 | Definir `ToolProposal` | Herramienta, argumentos y resumen visible | 2 h |
| LIA-5.1.2 | Definir estados de propuesta | Draft, awaiting confirmation, executing, completed, failed, cancelled | 2 h |
| LIA-5.1.3 | Validar propuestas LLM en el Engine | Propuestas fuera del catálogo se rechazan | 3 h |
| LIA-5.1.4 | Separar propuesta y ejecución | Ninguna tool call escribe al generarse | 2 h |
| LIA-5.1.5 | Implementar `confirmationToken` efímero | Vinculado a herramienta y argumentos exactos | 3 h |
| LIA-5.1.6 | Invalidar token al editar o cancelar | Confirmación no reutilizable | 2 h |
| LIA-5.1.7 | Añadir idempotency key por acción | Reintentos no duplican escrituras | 3 h |
| LIA-5.1.8 | Añadir auditoría técnica saneada | Acción, estado y duración sin notas personales | 2 h |
| LIA-5.1.9 | Añadir tests de bypass de confirmación | Ejecución imposible sin token válido | 3 h |

### Épica 5.2 — Acciones sobre la biblioteca

| ID | Tarea técnica | Resultado esperado | Estimación |
|---|---|---|---|
| LIA-5.2.1 | Definir contrato `create_book` | Alta manual o resultado seleccionado | 3 h |
| LIA-5.2.2 | Definir contrato `update_book` | Campos permitidos, progreso y estado | 3 h |
| LIA-5.2.3 | Definir contrato `create_reading_session` | Libro, fecha, minutos y páginas | 3 h |
| LIA-5.2.4 | Definir contrato `update_reading_session` | Sesión inequívoca y campos editables | 2 h |
| LIA-5.2.5 | Definir contrato `delete_reading_session` | Acción destructiva explícita | 2 h |
| LIA-5.2.6 | Definir contrato `set_annual_goal` | Valor actual, nuevo y año | 2 h |
| LIA-5.2.7 | Adaptar alta de libro al caso de uso existente | Drift sigue siendo fuente de verdad | 3 h |
| LIA-5.2.8 | Adaptar actualización de libro | Tracking local y sync normal preservados | 3 h |
| LIA-5.2.9 | Adaptar alta/edición de sesión | Estadísticas y progreso se actualizan oficialmente | 3 h |
| LIA-5.2.10 | Adaptar borrado de sesión | Impacto y tracking preservados | 3 h |
| LIA-5.2.11 | Adaptar objetivo anual | Reutiliza caso de uso y sync existentes | 2 h |

### Épica 5.3 — Confirmaciones

| ID | Tarea técnica | Resultado esperado | Estimación |
|---|---|---|---|
| LIA-5.3.1 | Crear tarjeta de acción propuesta | Entidad, valores e impacto visibles | 3 h |
| LIA-5.3.2 | Añadir `Confirmar`, `Editar` y `Cancelar` | Control explícito del usuario | 2 h |
| LIA-5.3.3 | Crear confirmación reforzada de borrado | Sesión e impacto claramente identificados | 2 h |
| LIA-5.3.4 | Implementar edición de borrador | Genera argumentos nuevos y token nuevo | 3 h |
| LIA-5.3.5 | Crear tarjeta de resultado | Dato guardado y navegación posterior | 2 h |
| LIA-5.3.6 | Mostrar estado local frente a sincronizado | No confunde guardado con sync | 2 h |
| LIA-5.3.7 | Añadir foco y semantics de diálogo | Confirmación accesible | 2 h |
| LIA-5.3.8 | Añadir widget tests de confirmaciones | Éxito, edición, cancelación y borrado | 3 h |

### Épica 5.4 — Manejo de errores

| ID | Tarea técnica | Resultado esperado | Estimación |
|---|---|---|---|
| LIA-5.4.1 | Mapear errores de dominio a mensajes seguros | Sin detalles internos en UI | 2 h |
| LIA-5.4.2 | Conservar borrador tras error recuperable | El usuario no repite datos | 2 h |
| LIA-5.4.3 | Implementar reintento idempotente | No duplica libros o sesiones | 3 h |
| LIA-5.4.4 | Tratar timeout con estado desconocido | Verifica resultado antes de reintentar | 3 h |
| LIA-5.4.5 | Tratar entidad modificada o inexistente | Se invalida confirmación obsoleta | 2 h |
| LIA-5.4.6 | Tratar conflicto de sync sin resolverlo automáticamente | Prioridad local vigente preservada | 3 h |
| LIA-5.4.7 | Añadir tests de fallos por acción | Casos recuperables y definitivos | 3 h |
| LIA-5.4.8 | Añadir tests de prompt injection en argumentos | Texto de libros/notas no altera permisos | 3 h |

### Dependencias

- Sprint 4 completado o decisión explícita de ejecutar Sprint 5 sin catálogo remoto.
- Casos de uso de dominio y tracking de sync existentes.
- Política de confirmaciones aprobada.
- No requiere modificar Supabase ni Drift directamente.

### Riesgos

- Ejecutar una mutación a partir de texto sin confirmación.
- Duplicar lógica de dominio en Tool Manager.
- Confundir éxito local con sincronización remota.
- Reintentos que creen registros duplicados.
- Ampliar hacia acciones masivas.
- Resolver conflictos de sync fuera de alcance.

### Criterios de aceptación

- Toda mutación tiene propuesta, confirmación y resultado visibles.
- El token autoriza una sola acción con argumentos exactos.
- Editar o cancelar invalida la confirmación.
- Las acciones reutilizan casos de uso existentes.
- Fallos no se presentan como éxito.
- Los reintentos son seguros.
- No existen acciones masivas ni acceso directo del LLM a datos.

### Definition of Done del sprint

- Preguntas 13–21 y 34 evaluadas.
- Tests de autorización, idempotencia, errores y UI en verde.
- `flutter analyze` sin nuevos problemas.
- QA Android y Web/PWA de cada acción.
- Revisión de sync y consistencia local completada.
- Revisión de accesibilidad de confirmaciones completada.
- Cero bypasses conocidos de confirmación.

---

## Sprint 6 — Reading Coach

**Estimación relativa:** L

**Clasificación:** post-MVP corto; distribución contextual de capacidades existentes. No incluye automatizaciones, notificaciones ni memoria permanente.

### Objetivo del sprint

Presentar insights automáticos y tarjetas inteligentes en puntos relevantes de ReadPp, utilizando únicamente datos y capacidades ya aprobados. “Automático” significa calculado al abrir/refrescar una pantalla, no ejecutado en segundo plano ni enviado como notificación.

### Épica 6.1 — Insights automáticos

| ID | Tarea técnica | Resultado esperado | Estimación |
|---|---|---|---|
| LIA-6.1.1 | Definir `CoachInsight` estructurado | Tipo, evidencia, periodo, prioridad y acción | 2 h |
| LIA-6.1.2 | Definir catálogo cerrado de insights | Solo progreso, actividad, objetivo y lectura actual | 2 h |
| LIA-6.1.3 | Implementar selector determinista de insight | Una regla elige el insight más relevante | 3 h |
| LIA-6.1.4 | Implementar fallback de datos insuficientes | No simula personalización | 2 h |
| LIA-6.1.5 | Limitar a un insight principal por superficie | Evita ruido y scope creep | 1 h |
| LIA-6.1.6 | Añadir periodo y fuente a cada insight | Cumple trazabilidad | 2 h |
| LIA-6.1.7 | Añadir tests de prioridad y fallback | Resultado estable con fixtures | 3 h |

### Épica 6.2 — Tarjetas inteligentes

| ID | Tarea técnica | Resultado esperado | Estimación |
|---|---|---|---|
| LIA-6.2.1 | Crear tarjeta `CoachInsightCard` | Insight, evidencia y acción opcional | 3 h |
| LIA-6.2.2 | Añadir variantes de progreso y objetivo | Reutiliza mismo componente | 2 h |
| LIA-6.2.3 | Añadir variante de lectura actual | Libro y progreso reales | 2 h |
| LIA-6.2.4 | Añadir variante de actividad | Periodo y métrica oficiales | 2 h |
| LIA-6.2.5 | Implementar estado vacío compacto | Alternativa útil sin CTA inventada | 2 h |
| LIA-6.2.6 | Añadir navegación contextual | Abre LibrerIA con origen e intent | 2 h |
| LIA-6.2.7 | Añadir accesibilidad y texto ampliado | Semantics y layout verificados | 2 h |
| LIA-6.2.8 | Añadir widget tests de variantes | Render y acciones cubiertos | 3 h |

### Épica 6.3 — Integración en Home

| ID | Tarea técnica | Resultado esperado | Estimación |
|---|---|---|---|
| LIA-6.3.1 | Definir ubicación de la tarjeta en Home | No desplaza la acción principal de lectura | 1 h |
| LIA-6.3.2 | Conectar snapshot lector al selector | Insight real al abrir | 3 h |
| LIA-6.3.3 | Añadir navegación con origen Home | ContextBuilder recibe contexto mínimo | 1 h |
| LIA-6.3.4 | Medir impresión y acción sin contenido | Evidencia para `PSC-001` y `PSC-007` | 2 h |
| LIA-6.3.5 | Añadir tests de Home con/sin datos | UI existente no se rompe | 3 h |

### Épica 6.4 — Integración en Biblioteca

| ID | Tarea técnica | Resultado esperado | Estimación |
|---|---|---|---|
| LIA-6.4.1 | Definir insight permitido en Biblioteca | Lectura actual o selección pendiente | 1 h |
| LIA-6.4.2 | Conectar datos de biblioteca | Sin consulta LLM al cargar pantalla | 3 h |
| LIA-6.4.3 | Añadir navegación contextual | Puede abrir recomendación acotada | 2 h |
| LIA-6.4.4 | Añadir estado vacío | Invita a añadir libro mediante flujo existente | 2 h |
| LIA-6.4.5 | Añadir tests de filtros y estados | No altera listado ni rendimiento | 3 h |

### Épica 6.5 — Integración en Estadísticas

| ID | Tarea técnica | Resultado esperado | Estimación |
|---|---|---|---|
| LIA-6.5.1 | Definir insight permitido en Estadísticas | Tendencia o comparación oficial | 1 h |
| LIA-6.5.2 | Conectar resumen estadístico existente | Sin recalcular métricas en UI o LLM | 3 h |
| LIA-6.5.3 | Pasar periodo visible a LibrerIA | Contexto preciso y mínimo | 2 h |
| LIA-6.5.4 | Añadir cobertura de muestra | No concluye con datos insuficientes | 2 h |
| LIA-6.5.5 | Añadir tests de periodos parciales | Comparaciones honestas | 3 h |

### Épica 6.6 — Integración en Perfil

| ID | Tarea técnica | Resultado esperado | Estimación |
|---|---|---|---|
| LIA-6.6.1 | Definir insight permitido en Perfil/Ajustes | Resumen del objetivo o preferencias existentes | 1 h |
| LIA-6.6.2 | Conectar objetivo y perfil lector existentes | Sin crear memoria del asistente | 3 h |
| LIA-6.6.3 | Añadir acceso a privacidad de LibrerIA | Consentimiento y desactivación visibles | 2 h |
| LIA-6.6.4 | Añadir navegación contextual | Abre pregunta relacionada, no chat general | 2 h |
| LIA-6.6.5 | Añadir tests de modo local y cuenta | No obliga a autenticarse indebidamente | 3 h |

### Épica 6.7 — Validación transversal

| ID | Tarea técnica | Resultado esperado | Estimación |
|---|---|---|---|
| LIA-6.7.1 | Medir coste de cálculo por superficie | Sin regresión perceptible | 2 h |
| LIA-6.7.2 | Verificar que cargar pantallas no invoca LLM | Insights automáticos son deterministas | 2 h |
| LIA-6.7.3 | Probar consistencia del mismo dato entre pantallas | Una única definición de dominio | 3 h |
| LIA-6.7.4 | Probar navegación contextual end-to-end | Origen e intent llegan correctamente | 3 h |
| LIA-6.7.5 | Ejecutar QA accesible en cuatro superficies | Foco, semantics y texto ampliado | 3 h |
| LIA-6.7.6 | Revisar métricas de utilidad | Impresión no se confunde con insight útil | 2 h |

### Dependencias

- Capacidades de consulta estabilizadas.
- Design system y providers de cada superficie.
- Insights oficiales y estadísticas existentes.
- No requiere tareas en segundo plano ni notificaciones.

### Riesgos

- Interpretar “coach” como automatización proactiva o notificaciones.
- Sobrecargar todas las pantallas con tarjetas.
- Invocar LLM durante el render.
- Duplicar el mismo insight sin contexto.
- Crear preferencias o memoria nuevas desde Perfil.
- Medir impresiones como prueba de utilidad.

### Criterios de aceptación

- Cada superficie muestra como máximo un insight relevante.
- Todos los insights automáticos son deterministas y trazables.
- Abrir Home, Biblioteca, Estadísticas o Perfil no invoca LLM.
- Las tarjetas respetan datos insuficientes y periodos parciales.
- La navegación aporta contexto mínimo.
- Perfil no crea memoria paralela ni obliga a usar cuenta.
- No existen notificaciones ni procesos en segundo plano.

### Definition of Done del sprint

- Tests unitarios, widget e integración en verde.
- `flutter analyze` sin nuevos problemas.
- QA Android y Web/PWA en las cuatro superficies.
- Revisión de rendimiento y accesibilidad completada.
- Cero llamadas LLM provocadas por render.
- Telemetría saneada y vinculada a utilidad, no solo impresiones.
- Product review confirma que las tarjetas ayudan sin invadir la experiencia.

---

## 7. Mapa de dependencias entre sprints

```text
Sprint 1 — Experience
    │
    ▼
Sprint 2 — Context Engine
    │
    ▼
Sprint 3 — Chat MVP
    │
    ├── Gate: MVP corto / PSC-001…007
    │
    ▼
Sprint 4 — Recommendations
    │
    ▼
Sprint 5 — Actions
    │
    ▼
Sprint 6 — Reading Coach
```

El orden no implica que una métrica fallida se resuelva avanzando al siguiente sprint. Cada sprint debe cerrar su propio alcance antes de habilitar el siguiente.

---

## 8. Matriz de trazabilidad del MVP corto

| Necesidad | Sprint | Componentes | Evidencia |
|---|---|---|---|
| Insight útil al abrir | 1, 2, 3 | UI, snapshot, Engine | `PSC-001` |
| Preguntas naturales | 3 | Chat, clasificador | `PSC-002` |
| Datos reales | 2, 3 | Tool Manager, contratos | `PSC-003` |
| Pocos segundos | 3 | UI, Engine, AiProvider | `PSC-004` |
| No repetir historial | 2, 3 | ContextBuilder, conversation state | `PSC-005` |
| Cero invenciones | 2, 3 | contratos, fixtures, validación | `PSC-006` |
| Ayuda real | 3 | experiencia completa | `PSC-007` |
| Engine decide | 1–3 | LibrerIA Engine | `DA-LIA-001` |
| Dominio especializado | 1, 3 | guard y prompt | `DA-LIA-002` |
| Memoria mínima | 2, 3 | contexto y estado efímero | `DA-LIA-003` |
| Contexto dinámico | 2, 3 | ContextBuilder | `DA-LIA-004` |
| Inteligencia híbrida | 2, 3 | routing y tools | `DA-LIA-005` |
| Proveedor abstraído | 2, 3 | AiProvider, fake, adaptador | `DA-LIA-006` |

---

## 9. Reglas de mantenimiento del backlog

- Una nueva funcionalidad requiere primero actualizar Product Design.
- Una nueva herramienta requiere contrato, límites, tests y registro explícito.
- Un nuevo proveedor requiere pasar las mismas pruebas de contrato de `AiProvider`.
- Una nueva métrica personal requiere definición de dominio y trazabilidad.
- Una tarea mayor de 3 horas debe dividirse.
- Una tarea descubierta durante un sprint se añade al backlog; no se incorpora silenciosamente.
- Los sprints 4–6 no se usan para declarar completo el MVP corto.
- El backlog se considera oficial cuando producto y arquitectura aceptan la reconciliación de alcance de la sección 0.1.

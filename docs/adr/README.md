# Architecture Decision Records

Este directorio contiene los Architecture Decision Records (ADR) de ReadPp.

Los ADR documentan decisiones de arquitectura relevantes del proyecto. Son secuenciales, cronologicos y no se renumeran una vez creados.

## Politica

Los ADR documentan unicamente decisiones de arquitectura que sean relevantes, dificiles de revertir o que afecten al diseno global del sistema.

No se crean ADR para cambios menores de implementacion, UI, refactors, correcciones de errores o tareas de mantenimiento.

Un ADR debe crearse unicamente cuando exista una decision arquitectonica ya tomada y aceptada.

## Regla de decision

Crear un ADR cuando la decision responda a preguntas como:

- Por que elegimos esta arquitectura.
- Por que esta tecnologia y no otra.
- Por que este modelo de datos.
- Por que esta estrategia de sincronizacion.
- Por que este mecanismo de autenticacion.
- Por que esta separacion entre componentes o dominios.

Si la decision puede explicarse en pocos segundos y no afecta a la arquitectura del sistema, no requiere ADR.

## Ciclo de vida

Cada ADR sigue este flujo:

1. Se detecta una decision arquitectonica.
2. Se analiza el contexto.
3. Se evaluan alternativas.
4. Se aprueba una decision.
5. Se crea el ADR correspondiente.
6. Posteriormente se implementa en codigo.
7. Cuando la implementacion este finalizada, el ADR debe reflejar el sprint o version en la que quedo materializada.

## Estado

Cada ADR debe indicar uno de los siguientes estados:

- Propuesto
- Aceptado
- Sustituido
- Obsoleto

## Alcance

Los ADR deben ser documentos breves, centrados en el razonamiento de la decision y no en la implementacion.

## Regla para el indice

Este README actua como indice de ADR.

No se reservan numeros de ADR por adelantado. Solo aparecen en el indice los ADR que existen realmente.

El siguiente numero se asigna unicamente cuando se aprueba una nueva decision arquitectonica.

## Indice

| ADR | Estado | Fecha | Decision |
| --- | --- | --- | --- |
| [ADR-001 - Arquitectura Offline First / Local First](ADR-001-local-first.md) | Aceptado | 2026-06-25 | Drift se mantiene como fuente de verdad durante el uso de la app y Supabase se incorpora como backend progresivo para autenticacion, sincronizacion y catalogo futuro. |
| [ADR-002 - Authentication Strategy](ADR-002-authentication-strategy.md) | Aceptado | 2026-06-25 | Supabase Auth sera el sistema de autenticacion de ReadPp con Google OAuth y email/contrasena como metodos iniciales. |

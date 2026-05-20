# Architecture

## Estructura actual

```text
reading_tracker/lib/
  core/
    database/
    theme/
    utils/
  features/
    books/
    reading_sessions/
    stats/
```

## Capas por feature

- `domain`: entidades, enums y contratos de repositorio. No debe depender de Flutter UI ni de Drift.
- `data`: datasources, mappers e implementaciones de repositorio.
- `presentation`: screens, widgets y providers Riverpod.

## Core

- `core/database`: Drift, tablas, DAOs, conexion por plataforma y seed data.
- `core/theme`: tema visual compartido.
- `core/utils`: utilidades generales como fechas o IDs.

## Dependencias permitidas

- `presentation` puede depender de `domain` y providers/repositorios.
- `data` puede depender de Drift y convertir entre tablas y entidades.
- `domain` debe mantenerse simple y libre de infraestructura.

## Regla de oro

Antes de crear una abstraccion nueva, comprobar si el patron ya existe en `books`, `reading_sessions` o `stats`. Si el cambio es local, mantenerlo local.

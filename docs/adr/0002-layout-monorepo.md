# ADR-0002 — Monorepo pnpm con `apps/` y `packages/`

- **Estado:** aceptado
- **Fecha:** 2026-08-12

## Contexto

Dos aplicaciones (api, web) que comparten contratos, un solo desarrollador, un
solo ciclo de release. No hay razón para repos separados: el costo de sincronizar
dos repos con un contrato compartido lo paga una persona sola, en cada cambio.

## Decisión

Un solo repo con pnpm workspaces:

```
apps/api/        NestJS
apps/web/        Next.js
packages/shared/ tipos y contratos api ↔ web
```

`packages/shared` contiene **solo** tipos y contratos: interfaces, DTOs, enums,
schemas de validación. Sin lógica de negocio, sin dependencias de runtime que
arrastren peso al bundle del frontend.

`apps/web` y `apps/api` no se importan entre sí. Nunca. Si necesitan compartir
algo, sube a `packages/shared`.

## Alternativas consideradas

### Un solo `package.json` en la raíz

Más simple de arrancar, sin workspaces ni resolución de dependencias entre
paquetes.

Descartada porque mezcla las dependencias de Next con las de NestJS en un solo
árbol, y ahí es cuestión de tiempo hasta que algo del backend termine en el
bundle del cliente. La separación de workspaces hace que ese error sea un error
de resolución, no algo que se descubre mirando el tamaño del bundle.

### Repos separados

Descartada: costo de sincronización de contratos sin ningún beneficio a esta
escala. Se justificaría con equipos separados o ciclos de release independientes,
y no hay ni uno ni otro.

### Turborepo / Nx

Descartada **por ahora** (C7): resuelven caché de builds y orquestación de tareas
en grafos grandes. Con dos apps, pnpm workspaces y unos scripts alcanzan. Se
revisita si el build local empieza a doler.

## Consecuencias

### A favor

- Un commit puede cambiar contrato, backend y frontend de forma atómica.
- Separación de dependencias real entre apps.
- Un solo `verify.sh` cubre todo el sistema.

### En contra

- Workspaces de pnpm agregan una capa de resolución que hay que entender cuando
  algo falla. Los errores de hoisting son opacos.
- Sin caché de builds, `verify.sh` completo va a ser lento a medida que crezca.
- `packages/shared` es un imán de scope creep: la tentación de meter "una
  funcioncita" ahí es permanente. Es solo tipos, y eso hay que defenderlo en cada
  review.

### Qué la revertiría

- `verify.sh` completo pasando de un par de minutos → entra Turborepo.
- `packages/shared` acumulando lógica pese al review → repensar el límite.

## Nota de estado

Esta estructura está **decidida pero no materializada**: todavía no hay código.
Se crea con la primera feature, no antes. Un scaffold vacío es código que nadie
decidió tener (C7).

# ADRs — Architecture Decision Records

Decisiones estructurales, con su contexto y sus consecuencias. Numeradas y
append-only: un ADR nunca se edita para cambiar la decisión, se escribe uno nuevo
que lo supersede.

## Cuándo escribir uno

Si la decisión es costosa de revertir o alguien va a preguntar "¿por qué está
así?" en seis meses. En concreto: stack, estructura del repo, modelo de datos
central, estrategia de auth, límites entre servicios, elección de librería que
permea el código.

Si es fácil de revertir y local, no es un ADR — es una convención o simplemente
código.

## Estados

`propuesto` → `aceptado` → `supersedido por ADR-NNNN` | `descartado`

## Índice

| # | Título | Estado |
|---|---|---|
| [0001](0001-stack.md) | Stack: NestJS + Next.js + PostgreSQL | aceptado |
| [0002](0002-layout-monorepo.md) | Monorepo pnpm con apps/ y packages/ | aceptado |
| [0003](0003-harness-spec-driven.md) | Harness spec-driven propio en vez de framework existente | aceptado |

Plantilla: [`0000-template.md`](0000-template.md).

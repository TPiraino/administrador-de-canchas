---
name: Propuesta de feature
about: Fase 1 del workflow — registrar una idea antes de que exista spec
title: '[propuesta] '
labels: propuesta
---

<!--
Esto es la fase "propose" de docs/workflow.md. Proponer es gratis y no tiene
gate: la idea es capturar la intención antes de invertir en escribirla bien.

NO escribas requisitos acá. Eso va en specs/<slug>/requirements.md después de
que la propuesta se acepte.
-->

## Slug propuesto

`<kebab-case>`

## Qué problema resuelve

Para quién, y qué pasa hoy si no existe. Con un caso concreto.

## Por qué ahora

Qué lo hace prioritario frente a lo demás.

## Fuera de alcance (primera intuición)

Lo que sospechás que **no** debería incluir. Se refina en la spec, pero anotarlo
ahora evita que la feature crezca sin que nadie lo decida.

## Tamaño estimado

- [ ] Chica — una spec corta, pocos requisitos
- [ ] Mediana
- [ ] Grande — probablemente hay que partirla en varias features

## Siguiente paso

Si se acepta: crear `state/features/<slug>.json` en `proposed` y arrancar
`specs/<slug>/requirements.md`.

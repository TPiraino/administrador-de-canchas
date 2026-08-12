# Requisitos — <feature>

- **Slug:** `<slug>`
- **Estado:** spec_draft
- **Fecha:** AAAA-MM-DD

## Problema

Qué problema resuelve esta feature, para quién, y qué pasa hoy si no existe.
Dos o tres párrafos. Sin tecnología.

## Fuera de alcance

Lo que explícitamente **no** hace esta feature. Esta sección evita el 80% de las
discusiones en el review.

## Requisitos

Notación EARS. Un requisito, una obligación. IDs permanentes: no se reutilizan.

R1  El sistema deberá …

R2  Cuando <disparador>, el sistema deberá …

R3  Si <condición no deseada>, entonces el sistema deberá …

R4  Mientras <estado>, el sistema deberá …

## Criterios de aceptación

Casos de borde que hay que probar y que no son requisitos nuevos. Cada uno
colgado del requisito que lo cubre.

- **R2.a** — entrada vacía: …
- **R2.b** — concurrencia: dos solicitudes simultáneas para el mismo recurso …
- **R3.a** — usuario sin permiso: …

## Ambigüedades pendientes

Todo lo que admite dos lecturas razonables. Se pregunta antes de pasar a
`design.md`; esta sección tiene que quedar vacía para aprobar.

- [AMBIGUO: <pregunta concreta>]

<!--
Esta checklist espeja docs/verification.md. No es burocracia: es lo que el
reviewer va a chequear igual. Tildarla vos primero le ahorra un round-trip.

Si la PR no toca código de producto (harness, docs, tooling), borrá todo y dejá
solo "Qué cambia" y por qué.
-->

## Feature

- **Slug:** `<slug>`
- **Spec:** `specs/<slug>/`
- **Estado:** `in_review`
- **Requisitos que cubre:** R1, R2, …

## Qué cambia

Dos o tres líneas. Qué hace ahora el sistema que antes no hacía.

## Desvíos de la spec

Qué se enmendó durante la implementación y por qué. **Si no hubo, decilo** — que
no hubo desvíos también es información (C12).

## Checklist

- [ ] Tiene un solo propósito (C6). No mezcla refactor con feature.
- [ ] Todas las tareas de `tasks.md` tildadas
- [ ] Cada requisito `R#` tiene un test que **lo prueba de verdad**, no que solo
      lo menciona (C3)
- [ ] Los criterios de aceptación (`R#.a`, `R#.b`) están cubiertos
- [ ] `./verify.sh` corrido y verde — **con el output visto** (C13)
- [ ] `specs/<slug>/` refleja lo que quedó implementado (C12)
- [ ] `progress/current.md` actualizado
- [ ] Sin secretos, sin datos reales en fixtures (C9), sin datos mock
      persistentes (C10)
- [ ] Nada de `any`, `@ts-ignore` sin explicación, ni `catch {}` vacío (C11)

## Output de `verify.sh`

```
<pegá acá el output real, no un resumen>
```

## Para el reviewer

Contexto fresco, por favor (C5): mirá el diff, la spec y `docs/verification.md`.
No hace falta que leas cómo se llegó acá — si el diff no se explica solo, eso ya
es un finding.

Puntos donde quiero atención especial:

-

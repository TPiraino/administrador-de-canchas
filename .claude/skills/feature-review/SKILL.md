---
name: feature-review
description: 'Usar para revisar una feature implementada en este repo — despacha el agente reviewer con contexto fresco (solo diff, spec y verification.md) y escribe el veredicto binario. Disparadores: "revisá la feature X", "está lista para PR?", "pedí review". Reemplaza a reviewer-tl / requesting-code-review para este proyecto.'
---

# feature-review

Despacha el review de una feature con **contexto fresco** y registra el veredicto
en `progress/review_<slug>.md`.

## La regla que define esta skill

> Quien implementa no aprueba (C5).

Si el mismo contexto que escribió el código lo revisa, no va a encontrar nada: ya
se convenció de que está bien la primera vez. Por eso el review **siempre** corre
en un subagente aparte, aunque parezca redundante y aunque el diff sea chico.

## Precedencia

En este repo **esta skill reemplaza** a `reviewer-tl`, `requesting-code-review` y
`code-review`. La diferencia no es cosmética: el reviewer de acá valida
trazabilidad requisito → test y fidelidad a la spec, que son cosas que un review
genérico no mira porque no sabe que existen.

## Procedimiento

### 1. Precondiciones

```bash
jq '{state, owner}' state/features/<slug>.json
./verify.sh
```

- `state` tiene que ser `in_progress` (o ya `in_review`, si es una segunda vuelta).
- **`verify.sh` tiene que estar verde antes de pedir el review.** Mandar a revisar
  algo que no compila o con requisitos sin test es quemarle el tiempo al reviewer.
  Si está rojo, arreglalo primero.

### 2. Pasar a `in_review`

En `state/features/<slug>.json`: `state: "in_review"` + entrada en `history`.

### 3. Preparar el material — y nada más que el material

```bash
git diff main...HEAD
```

El agente `reviewer` recibe **exactamente** tres cosas:

1. El diff completo contra `main`
2. Las rutas de `specs/<slug>/{requirements,design,tasks}.md`
3. La ruta de `docs/verification.md`

**Lo que NO le pasás**, y esto es lo importante:

- Un resumen de cómo llegaste a la implementación
- Justificaciones de por qué algo está así
- Qué partes te parecen bien o te preocupan
- Cualquier "ojo que esto es medio raro pero es porque…"

Si el diff necesita ese contexto para entenderse, **eso ya es un finding**. Dárselo
masticado destruye el único valor del contexto fresco.

### 4. Despachar

Lanzá el agente `reviewer` (definido en `.claude/agents/reviewer.md`) con el
material del punto 3. Es de solo lectura a propósito: no puede "arreglar mientras
revisa", porque un reviewer que edita deja de ser reviewer.

Para features grandes, podés despachar **varios reviewers en paralelo** con foco
distinto (trazabilidad / fidelidad a la spec / calidad). Es más barato que una
segunda vuelta completa.

### 5. Registrar el veredicto

Escribí `progress/review_<slug>.md`:

```markdown
# Review — <slug>

- **Fecha:** AAAA-MM-DD
- **Reviewer:** <agente fresco | persona>
- **Commit:** <sha>
- **Veredicto:** APROBADO | RECHAZADO

## Trazabilidad

| Requisito | Test | ¿Lo prueba de verdad? |
|---|---|---|
| R1 | `x.spec.ts:12` | sí |

## Findings

### F1 — <título> (bloqueante | menor)

Qué está mal, dónde, y el artículo violado si aplica.

## Verificado

Output de `./verify.sh`.
```

**Veredicto binario.** No existe "aprobado con observaciones": si hay algo que
arreglar, está **rechazado**. Un finding menor que se aprueba es un finding que no
se arregla nunca.

### 6. Según el veredicto

**RECHAZADO** → `state: "in_progress"`, entrada en `history` con el motivo,
`current.md` actualizado con los findings pendientes. El mismo contexto puede
arreglar; el review siguiente vuelve a ser fresco.

**APROBADO** → queda en `in_review`. El próximo paso es `feature-close`, que
chequea el Gate 2 completo. Abrí la PR con la plantilla de
`.github/pull_request_template.md`, con el output real de `verify.sh` pegado.

## Al terminar

Reportá el veredicto, los findings ordenados por severidad, y el próximo paso.
Si rechazó, no arregles en el mismo turno sin decirlo: el humano tiene que poder
ver los findings antes de que desaparezcan.

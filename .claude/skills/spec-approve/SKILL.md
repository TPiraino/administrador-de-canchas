---
name: spec-approve
description: 'Usar para pasar el Gate 1 de una feature — preparar la decisión de aprobación de una spec para que un humano la tome, y registrarla solo con su OK explícito. Disparadores: "aprobá la spec de X", "revisá la spec", "podemos arrancar con X?". NUNCA aprueba por su cuenta.'
---

# spec-approve

Prepara el Gate 1 y lo registra. **El trabajo principal de esta skill es no
aprobar**: junta la información para que un humano decida, y se detiene.

## La regla que define esta skill

> El Gate 1 no lo puede pasar un agente (C2).

Escribir `approval` sin un OK humano explícito rompe el gate más importante del
harness. No hay excepción, tampoco si el humano dijo antes "escribila y
aprobala" — el gate existe para que alguien **lea** la spec, no para que quede el
campo lleno.

## Procedimiento

### 1. Precondiciones

```bash
jq . state/features/<slug>.json
ls specs/<slug>/
```

- El estado tiene que ser `spec_draft`. Si ya está en `spec_approved` o
  posterior, no hay nada que hacer: reportalo y pará.
- Los tres archivos tienen que existir.

### 2. Chequeos automáticos — antes de molestar al humano

Corré todo esto y **si algo falla, pará acá**. No pidas aprobación de una spec
que todavía no está lista; devolvé la lista de lo que falta.

| Chequeo | Cómo |
|---|---|
| Cero ambigüedades | `grep -c '\[AMBIGUO:' specs/<slug>/requirements.md` tiene que dar 0 |
| Requisitos con ID parseable | `grep -cE '^R[0-9]+' specs/<slug>/requirements.md` mayor a 0 |
| "Fuera de alcance" completo | la sección existe y no está vacía ni con el placeholder del template |
| Criterios de aceptación | los requisitos con casos de borde no triviales los tienen (`R#.a`) |
| Alternativa descartada | `design.md` tiene al menos una, con motivo concreto |
| Contratos verificados | los ⚠️ de `design.md` están justificados, no son pereza de no buscar en el código (C8) |
| Requisitos cubiertos por tareas | todo `R#` aparece en al menos una tarea de `tasks.md` |
| Test antes de implementación | el orden de `tasks.md` lo respeta (C3) |
| Placeholders del template | no quedó ningún `<slug>`, `AAAA-MM-DD` ni `<qué>` sin completar |

Si no corriste el agente `spec-critic` todavía, corrélo ahora y sumá sus findings
a lo de arriba.

### 3. Brief de decisión para el humano

Presentá, en este formato y sin adornos:

```
FEATURE: <slug> — <title>

PROBLEMA
  <dos líneas>

REQUISITOS (n)
  R1  <una línea>
  R2  <una línea>
  ...

FUERA DE ALCANCE
  <lo que explícitamente no hace>

DISEÑO
  Enfoque:    <una línea>
  Descartado: <alternativa> porque <motivo>

RIESGOS
  <riesgo> → se detecta con <qué>

ATENCIÓN
  <contratos ⚠️ no verificados, decisiones dudosas, findings del spec-critic>

TAREAS: n tareas, m tests
```

Y después, la pregunta explícita: **¿aprobás esta spec para implementar?**

### 4. Interpretar la respuesta

Solo estas cuentan como aprobación: una afirmación clara de que la spec queda
aprobada ("aprobada", "dale, aprobada", "sí, arrancá").

**No** cuentan: un "ok" o "bien" suelto respondiendo a otra cosa, silencio, ni
"parece bien". Ante cualquier duda, volvé a preguntar. Es más barato preguntar
dos veces que aprobar algo que nadie leyó.

Si el humano pide cambios: no aprobás. Volvé a `spec-write` con los cambios y
después volvé a este gate.

### 5. Registrar

Con el OK explícito:

```bash
date +%F                  # para approval.at
git config user.name      # candidato para approval.by, confirmalo con el humano
```

En `state/features/<slug>.json`:

- `state: "spec_approved"`
- `approval: { "by": "<quien aprobó>", "at": "<fecha>" }`
- Entrada nueva en `history`

**Autoaprobación:** si quien aprueba es la misma persona que escribió la spec
(mirá el `history`), anotalo en la nota del `history`:
`"autoaprobación — no había otro revisor disponible"`. No está prohibido, pero
tiene que quedar visible en el registro (ver `CONTRIBUTING.md`).

```bash
./verify.sh --harness
```

Verde antes de reportar. Commiteá el cambio de estado con
`docs(<slug>): spec aprobada (Gate 1)`.

## Al terminar

Decí que el Gate 1 quedó pasado, quién aprobó y con qué fecha, y que el próximo
paso es `feature-take`. No arranques a implementar en el mismo turno: tomar la
feature es un acto público y separado.

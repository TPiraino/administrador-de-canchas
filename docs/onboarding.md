# Onboarding — 15 minutos

Para un dev nuevo, o para un agente que arranca sin contexto. El orden importa.

---

## Minuto 0 — Que ande

```bash
sudo apt install jq     # o brew install jq
./verify.sh
```

Tiene que dar **VERDE**. Si da rojo recién clonado, es un bug del repo, no tuyo:
abrí un issue.

`./verify.sh` es la única definición de "verde" en este proyecto. Vas a correrlo
muchas veces.

## Minuto 1 — Leé la constitución

[`docs/constitution.md`](constitution.md). Son 13 artículos, cinco minutos.

Es lo único no negociable del repo. Todo lo demás —stack, convenciones,
herramientas, incluso este archivo— está subordinado a eso y se puede cambiar.

Los tres que más se violan por descuido:

- **C2** — nada de código de producto sin spec aprobada por un humano.
- **C3** — sin test que referencie el requisito, el requisito no está hecho.
- **C13** — no declares nada terminado sin haber corrido `verify.sh` y **visto**
  el output.

## Minuto 6 — Entendé el ciclo

[`docs/workflow.md`](workflow.md), la sección de la máquina de estados.

Lo mínimo que tenés que retener:

```
propose ──▶ spec ──▶ [GATE humano] ──▶ implement ──▶ review ──▶ [GATE verde] ──▶ done
```

No hace falta ejecutarlo de memoria: cada transición tiene su skill en el repo.

```
/spec-write  →  /spec-approve  →  /feature-take  →  /feature-implement
                                       →  /feature-review  →  /feature-close
```

**Importante:** usá estas y no las globales que puedas tener instaladas
(`planner`, `writing-plans`, `reviewer-tl`, `dev-workflow`). La tabla de
precedencia y el motivo están en [`AGENTS.md`](../AGENTS.md).

Y que hay **una sola** cosa que habilita escribir código de producto: una feature
en `in_progress`, con `approval` registrado, con spec completa. Si no está eso, un
hook te va a bloquear el Write — y si trabajás con otro editor, te va a bloquear
la PR en CI.

## Minuto 10 — Mirá dónde está el proyecto

```bash
cat progress/current.md      # el handoff: qué se está haciendo
ls state/features/           # una feature por archivo, con su estado
```

`progress/current.md` es lo primero que se lee en cada sesión. Si trabajás con
Claude Code, el hook de `SessionStart` te lo inyecta solo.

## Minuto 12 — El contrato de trabajo

[`CONTRIBUTING.md`](../CONTRIBUTING.md), sección "Reglas de convivencia entre
devs". Lo esencial:

- Una feature en vuelo por persona.
- Tomar una feature es público: se commitea antes de empezar.
- El que escribe la spec no la aprueba. El que implementa no revisa.

## Minuto 15 — Tu primera contribución

**Hacé un review antes de implementar algo.** Se aprende el estándar más rápido
revisando que escribiendo, y el costo de un review flojo es mucho menor que el de
una implementación fuera de convención.

Tomá una PR abierta, leé [`docs/verification.md`](verification.md), y revisá
contra eso. Veredicto binario: aprobado o rechazado con findings. No existe
"aprobado con observaciones".

---

## Referencia rápida

```bash
./verify.sh              # todo
./verify.sh --harness    # solo consistencia del harness (rápido, sin deps)
./verify.sh --stack      # solo typecheck/lint/tests/build
```

| Quiero… | Leo | Corro |
|---|---|---|
| escribir una spec | [`specs/README.md`](../specs/README.md) | `/spec-write` |
| aprobar una spec | [`docs/workflow.md`](workflow.md) | `/spec-approve` |
| arrancar a implementar | [`docs/conventions.md`](conventions.md) | `/feature-take` → `/feature-implement` |
| revisar una PR | [`docs/verification.md`](verification.md) | `/feature-review` |
| cerrar una feature | [`docs/verification.md`](verification.md) | `/feature-close` |
| cambiar algo ya especificado | [`changes/README.md`](../changes/README.md) | — |
| entender por qué el stack es este | [`docs/adr/0001-stack.md`](adr/0001-stack.md) | — |
| entender por qué el harness es este | [`docs/adr/0003-harness-spec-driven.md`](adr/0003-harness-spec-driven.md) | — |

## Las tres cosas que más frustran al principio

**"El hook me bloqueó el Write."** No hay feature en `in_progress`. Eso es C2
funcionando. Si es una excepción legítima (tooling, typo), corré con
`HARNESS_GATE=off` y decilo.

**"`verify.sh` dice que un requisito no tiene test."** El test tiene que
**mencionar el ID literal** en su nombre: `it('R3 — …')`. Es cómo se automatiza la
trazabilidad. Ver [`specs/README.md`](../specs/README.md).

**"Escribí la spec y no me deja implementar."** Falta el Gate 1: alguien tiene que
aprobarla y quedar registrado en `approval`. Es a propósito — es el punto más
barato del ciclo para descubrir que el problema estaba mal entendido.

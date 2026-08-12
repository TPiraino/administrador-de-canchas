# AGENTS.md

Router de contexto para agentes que trabajan en este repo. Es deliberadamente
corto: no explica el proyecto, dice **dónde está** cada cosa y **qué leer según
la tarea**.

Este es el archivo canónico. `CLAUDE.md` apunta acá.

---

## Siempre

Antes de cualquier cosa, leé [`docs/constitution.md`](docs/constitution.md).
Son 13 artículos no negociables. Todo lo demás en este repo está subordinado a
ellos, incluido este archivo.

Los dos que más se violan por descuido:

- **C2** — nada de código de producto sin spec aprobada.
- **C13** — no declares nada terminado sin haber corrido `./verify.sh`.

## Estado actual del trabajo

| Qué | Dónde |
|---|---|
| Qué se está haciendo ahora | [`progress/current.md`](progress/current.md) |
| Estado de cada feature | [`state/features/`](state/) — un archivo por feature |
| Historial de features cerradas | [`progress/history.md`](progress/history.md) |

Leé `progress/current.md` **primero** en cada sesión nueva. Es el handoff.

## Skills del proyecto

El workflow es operable: cada transición de estado tiene su skill en
`.claude/skills/`, versionada en el repo para que todos los devs trabajen igual.

| Fase | Skill | Qué muta |
|---|---|---|
| Spec | `spec-write` | crea `specs/<slug>/`, estado → `spec_draft` |
| **Gate 1** | `spec-approve` | estado → `spec_approved` + `approval` — **solo con OK humano** |
| Tomar | `feature-take` | `owner` + estado → `in_progress`, rama, handoff |
| Implementar | `feature-implement` | código, tests, tildes de `tasks.md` |
| Review | `feature-review` | estado → `in_review`, despacha el agente `reviewer` |
| **Gate 2** | `feature-close` | estado → `done`, mueve a `history.md` |

Agentes en `.claude/agents/`: **`reviewer`** (contexto fresco, solo lectura — C5) y
**`spec-critic`** (ataca la spec antes del Gate 1).

### Precedencia sobre skills globales

Las skills de este repo **reemplazan** a sus equivalentes globales. Si tenés las dos
familias disponibles, gana la del repo:

| No uses acá | Usá |
|---|---|
| `writing-plans`, `planner`, `brainstorming` | `spec-write` |
| `executing-plans`, `subagent-driven-development` | `feature-implement` |
| `reviewer-tl`, `requesting-code-review`, `code-review` | `feature-review` |
| `dev-workflow`, `intensive-workflow` | el ciclo de `docs/workflow.md` |

**Por qué:** producen artefactos que el harness no reconoce y que `verify.sh` no
puede verificar. Un plan que no es `tasks.md` es un plan que nadie puede auditar.

**Lo que sí sigue valiendo:** las skills de stack (`dev-nestjs`, `dev-nextjs`,
`dev-terraform`) dicen *cómo* escribir bien cada tecnología, y eso es
complementario. `test-driven-development` y `systematic-debugging` también — la
única diferencia acá es que el test además menciona el ID del requisito.

## Según la tarea

| Si vas a… | Leé |
|---|---|
| Escribir o revisar una spec | [`specs/README.md`](specs/README.md) |
| Proponer un cambio a algo ya especificado | [`changes/README.md`](changes/README.md) |
| Implementar código | [`docs/conventions.md`](docs/conventions.md) + la spec de la feature |
| Decidir "¿esto está listo?" | [`docs/verification.md`](docs/verification.md) |
| Entender el ciclo completo y los gates | [`docs/workflow.md`](docs/workflow.md) |
| Entender por qué el stack es el que es | [`docs/adr/`](docs/adr/) |
| Cambiar stack, estructura o una decisión estructural | escribí un ADR nuevo en [`docs/adr/`](docs/adr/) |

No cargues lo que no necesitás. El contexto que gastás en reglas irrelevantes es
contexto que no tenés para el problema.

## Verificación

```bash
./verify.sh            # todo: consistencia del harness + checks del stack
./verify.sh --harness  # solo consistencia del harness (rápido, no necesita deps)
```

`verify.sh` es la única definición de "verde" (C4). Si querés que algo se exija,
no lo escribas acá: hacelo fallar ahí.

## Límites

- No edites el campo `approval` de una feature para saltear un gate. El gate
  existe porque un humano tiene que leer la spec (C2).
- No borres tests, validaciones ni requisitos sin justificarlo en el commit.
- No inventes APIs, tipos, tablas o eventos: verificalos en el código (C8).
- Si algo del harness te está estorbando, decilo y proponé una enmienda. No lo
  evadas.

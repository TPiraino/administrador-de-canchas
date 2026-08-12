# Administrador de canchas

Gestión de clubes, canchas y reservas. En construcción — **todavía no hay código
de producto**, y eso es intencional: primero se acordó cómo se trabaja.

---

## Este repo se trabaja de una forma particular

Es un proyecto **spec-driven** desarrollado con agentes de IA. La regla central:

> Nada de código de producto sin una spec aprobada por un humano.

No es una preferencia de estilo. Es la única forma que encontramos de que un
agente produzca algo revisable a las 40 iteraciones, y no un montón de código
plausible que nadie decidió tener.

Tres principios sostienen todo lo demás:

1. **Regla en prosa = sugerencia. Regla con exit code = regla.** Todo lo que
   importa falla en `verify.sh` o en un hook. Lo que solo está escrito en un
   `.md` se ignora tarde o temprano.
2. **Estado en disco, versionado.** Specs, decisiones y progreso viven en el
   repo. El historial de chat es volátil por diseño y no es fuente de verdad.
3. **Trazabilidad de punta a punta.** Requisito `R#` → test → commit. Sin esa
   cadena no se puede responder "¿esto está terminado?" sin releer todo.

## Arrancar

```bash
git clone https://github.com/TPiraino/administrador-de-canchas.git
cd administrador-de-canchas
./verify.sh          # tiene que dar VERDE antes de que toques nada
```

Necesitás `jq` (`sudo apt install jq`). Cuando exista código, además Node 22
(`.nvmrc`), pnpm y Docker.

Si sos nuevo en el repo: **[`docs/onboarding.md`](docs/onboarding.md)**, 15
minutos. Si venís a contribuir: [`CONTRIBUTING.md`](CONTRIBUTING.md).

## Mapa

| Ruta | Qué hay |
|---|---|
| [`AGENTS.md`](AGENTS.md) | punto de entrada para agentes; `CLAUDE.md` apunta acá |
| [`docs/constitution.md`](docs/constitution.md) | 13 artículos no negociables |
| [`docs/workflow.md`](docs/workflow.md) | ciclo de vida de un cambio y sus dos gates |
| [`docs/conventions.md`](docs/conventions.md) | cómo se escribe código acá |
| [`docs/verification.md`](docs/verification.md) | qué significa "listo" |
| [`docs/adr/`](docs/adr/) | decisiones estructurales, con sus contras |
| [`specs/`](specs/) | una carpeta por feature: requirements, design, tasks |
| [`changes/`](changes/) | propuestas de cambio sobre specs ya existentes |
| [`state/`](state/) | estado de cada feature, un archivo por feature |
| [`progress/`](progress/) | handoff entre sesiones e historial |
| [`verify.sh`](verify.sh) | **la única definición de "verde"** |
| [`.claude/`](.claude/) | hooks compartidos que enforzan las reglas |

## El ciclo, en corto

```
propose ──▶ spec ──▶ [GATE humano] ──▶ implement ──▶ review ──▶ [GATE verde] ──▶ done
                          │                            │
                    aprobación de              contexto fresco,
                    la spec, no del            no vio la
                    código                     implementación
```

El detalle está en [`docs/workflow.md`](docs/workflow.md).

## Stack

NestJS + Next.js (App Router) + PostgreSQL, monorepo pnpm, Docker Compose local.
El porqué de cada elección —y qué la revertiría— está en
[`docs/adr/0001-stack.md`](docs/adr/0001-stack.md).

## De dónde salió este harness

Se evaluaron [spec-kit](https://github.com/github/spec-kit),
[ECC](https://github.com/affaan-m/ECC),
[harness-sdd](https://github.com/betta-tech/harness-sdd) y OpenSpec, y se
construyó uno propio y mínimo tomando de cada uno solo lo que aporta. El
razonamiento completo, con las alternativas descartadas, está en
[`docs/adr/0003-harness-spec-driven.md`](docs/adr/0003-harness-spec-driven.md).

La política es **crecer por dolor, no por anticipación**. Cada regla que se
agrega es contexto que compite con el trabajo real, así que se agrega cuando algo
concreto dolió — nunca "para cuando lo necesitemos" (C7).

## Estado

**V0 del harness.** Sin código de producto. Próximo paso en
[`progress/current.md`](progress/current.md).

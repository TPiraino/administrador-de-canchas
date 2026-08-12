# ADR-0003 — Harness spec-driven propio en vez de un framework existente

- **Estado:** aceptado
- **Fecha:** 2026-08-12

## Contexto

El proyecto se desarrolla con agentes, y el objetivo explícito es que sea
ordenado y AI-driven desde el arranque. Se evaluaron tres referencias concretas
más el ecosistema:

- **github/spec-kit** — el vocabulario de facto del spec-driven development:
  `constitution → specify → plan → tasks → implement`, más gates de `clarify` y
  `analyze`. Sesgado a greenfield y con una capa propia de templating
  (`templates/overrides/presets/extensions/bundles`).
- **affaan-m/ECC** — 68 agentes, 287 skills, 94 comandos. Su tesis es correcta:
  el plan no vive en el chat, quien escribe no revisa, y las reglas duras se
  enforzan con hooks fuera del contexto del modelo. Su tamaño es inauditable para
  una persona.
- **betta-tech/harness-sdd** — "el repositorio ES el sistema": estado en disco,
  requisitos EARS con IDs mapeados a tests, `feature_list.json` como máquina de
  estados, `init.sh` como único punto de verificación, gates humanos.
- **OpenSpec** — el único diseñado para brownfield: `specs/` como estado actual y
  `changes/` como propuestas, con máquina de estados de tres fases.

El ecosistema converge en el mismo loop (`specify → plan → execute → verify`), así
que copiar el loop no aporta nada. Lo que diferencia un harness que funciona de
uno decorativo es otra cosa.

## Decisión

No se instala ningún framework. Se construye un harness propio y mínimo que toma
de cada referencia solo lo que aporta, y crece por dolor observado, no por
anticipación.

| De | Se toma |
|---|---|
| spec-kit | la constitución como artefacto de primera clase; el gate de ambigüedad antes de diseñar |
| ECC | hooks como enforcement fuera del contexto; review con contexto fresco |
| harness-sdd | estado en disco versionado; EARS con IDs trazables a tests; máquina de estados de features; un único `verify.sh` |
| OpenSpec | `changes/` separado de `specs/` para modificar lo ya especificado |

Los tres principios que sostienen todo:

1. **Regla en prosa = sugerencia. Regla con exit code = regla.** Todo lo que
   importa falla en `verify.sh` o en un hook.
2. **Estado en disco, versionado.** El chat es volátil por diseño.
3. **Trazabilidad de punta a punta:** requisito `R#` → test → commit.

## Alternativas consideradas

### Instalar spec-kit

Da el vocabulario y los comandos gratis, y es lo que más gente entiende.

Descartada porque monta un framework dentro del framework: una capa de templating
con orden de resolución propio, para un proyecto de una persona que no necesita
presets ni bundles. Y su modelo de "cada feature nace de una spec nueva" no cubre
el caso dominante a mediano plazo, que es *cambiar* algo que ya existe.

### Instalar ECC

Descartada por superficie. 287 skills es más contexto y más comportamiento del
que se puede auditar, y son las preferencias acumuladas de otra persona. El
riesgo concreto no es que funcione mal: es no poder saber por qué el agente hizo
lo que hizo.

### Instalar OpenSpec

La más tentadora, y la más cercana al modelo elegido. Descartada por el mismo
motivo que spec-kit —adoptar su máquina de estados completa antes de tener una
sola feature es ceremonia sin evidencia— pero su separación `specs/` vs
`changes/` se adopta tal cual.

### No tener harness

Descartada por experiencia directa de la iteración previa del proyecto: sin
enforcement, las reglas escritas se ignoran, y sin estado en disco el trabajo se
pierde con el contexto.

## Consecuencias

### A favor

- Superficie chica: todo el harness se lee en una sentada.
- Cada regla tiene un dueño y un motivo; nada heredado sin entender.
- Enforcement real: los invariantes fallan con exit code, no con un `.md`.
- Independiente de herramienta: `AGENTS.md` es canónico, `CLAUDE.md` apunta ahí.

### En contra

- Se mantiene a mano. Las mejoras del ecosistema no llegan gratis.
- No hay comunidad ni documentación externa: los bordes se descubren usándolo.
- Riesgo de reinventar mal algo que spec-kit u OpenSpec ya resolvieron bien.
- **Riesgo de solapamiento con el harness global ya instalado** (skills de
  `superpowers` y skills propias como `dev-workflow`, `planner`, `reviewer-tl`).
  Dos definiciones de "cómo se planifica" es peor que una mala: el agente elige
  la que no corresponde. Hay que resolver la composición explícitamente.

### Qué la revertiría

- Si a las 10 features el harness propio requiere más mantenimiento que trabajo
  de producto, se migra a OpenSpec y se conserva solo la constitución.
- Si los hooks generan más falsos positivos que bloqueos útiles, se aflojan a
  advertencia antes de sacarlos.

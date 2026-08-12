# Contribuir

El contrato de trabajo del repo. Aplica igual a personas y a agentes — un agente
es un colaborador más, con las mismas reglas y los mismos gates.

Antes de nada: [`docs/constitution.md`](docs/constitution.md). Tiene precedencia
sobre este archivo y sobre cualquier otra cosa acá.

---

## El ciclo, y quién hace qué

```
propose ──▶ spec ──▶ [GATE 1] ──▶ implement ──▶ review ──▶ [GATE 2] ──▶ done
```

| Fase | Quién | Salida |
|---|---|---|
| propose | cualquiera | issue con la plantilla de propuesta + `state/features/<slug>.json` |
| spec | autor de la spec (persona o agente) | `specs/<slug>/{requirements,design,tasks}.md` |
| **GATE 1** | **un humano que no escribió la spec** | `state: spec_approved` + `approval: {by, at}` |
| implement | owner de la feature | código + tests + tildes en `tasks.md` |
| review | **otra persona, o un contexto fresco** | `progress/review_<slug>.md` |
| **GATE 2** | reviewer + CI | `verify.sh` verde + veredicto aprobado |

Detalle completo en [`docs/workflow.md`](docs/workflow.md).

## Reglas de convivencia entre devs

Estas son las que existen específicamente porque somos más de uno.

### Una feature en vuelo por persona

`verify.sh` falla si un mismo `owner` tiene dos features en `in_progress`. Podés
tener una; no dos. Si necesitás pausar algo, volvelo a `spec_approved` y liberá el
`owner`.

Varias personas en paralelo: sí, una feature cada una. El estado vive en archivos
separados (`state/features/<slug>.json`) precisamente para que sus ramas no
choquen.

### Tomar una feature es público

Cambiar `owner` y pasar a `in_progress` va en un commit a `main` (o en la primera
push de tu rama) **antes** de empezar a escribir código. Es cómo el resto sabe
que está tomada. Tomar algo en silencio y aparecer con una PR de 800 líneas es la
forma más rápida de tirar trabajo de alguien a la basura.

### El que escribe la spec no la aprueba

El Gate 1 lo pasa otra persona. Si sos el único disponible, dejá pasar tiempo real
entre escribirla y aprobarla, y anotá en el `history` que la aprobación fue
autoaprobación. Que se vea en el registro.

### El que implementa no revisa

Gate 2 igual: otra persona, o un contexto de agente completamente fresco que solo
vea el diff, la spec y `docs/verification.md` (C5). No le cuentes cómo llegaste —
si el diff necesita ese contexto para entenderse, eso ya es un finding.

### Conflictos en `state/` o `specs/`

Si dos ramas tocan el mismo archivo de feature o la misma spec, el conflicto es
señal de que dos personas están trabajando sobre lo mismo. **No se resuelve
mergeando a mano**: se habla, se decide quién sigue, y la otra rama se cierra o se
rebasa sobre la decisión.

## Ramas y PRs

```
feat/<slug>     nueva feature
fix/<slug>      corrección sobre algo existente
chore/<qué>     tooling, deps, CI
docs/<qué>      documentación, harness, ADRs
```

- Una rama por feature. Nada de ramas con dos features.
- Commits en Conventional Commits, con el slug como scope y el requisito
  referenciado: `feat(reserva-de-cancha): crear reserva en horario libre (R1)`.
- Un propósito por commit y por PR (C6). Si el título necesita un "y", partilo.
- La plantilla de PR se completa entera, incluido el output real de `verify.sh`.
  "Corrí los tests y pasan" sin output no cuenta (C13).

### `main` protegida

Configurar en GitHub → Settings → Branches:

- PR obligatoria, sin push directo.
- Checks requeridos: `harness`, `spec-gate`, `stack`.
- Al menos 1 aprobación.
- Aprobaciones obsoletas se descartan al pushear nuevos commits.

Sin esto, todo lo de arriba es voluntario. Es lo primero que hay que activar al
sumar el segundo dev.

## Cambiar el harness

El harness es código como cualquier otro, con dos diferencias:

- **Enmendar la constitución** requiere un commit dedicado que toque solo
  `docs/constitution.md`, con el dolor concreto que lo motivó. No hay enmiendas
  preventivas: hace falta un caso real donde el artículo estorbó o faltó. Si el
  artículo tenía enforcement, se actualiza en el mismo commit.
- **Cambiar una decisión estructural** (stack, layout, límites entre módulos) es
  un ADR nuevo en [`docs/adr/`](docs/adr/), no una edición del ADR viejo. Los ADRs
  son append-only: se superseden, no se reescriben.

Convenciones, hooks y `verify.sh` se cambian con un commit y una línea de por qué.

## Si el harness te está estorbando

Decilo. Un guard que da falsos positivos seguido es un bug, y la respuesta
correcta es aflojarlo a advertencia o arreglarlo — **no** evadirlo en silencio con
`HARNESS_GATE=off` permanente. Un harness que la gente evade es peor que no tener
harness, porque genera la ilusión de que las reglas se cumplen.

Anotá el roce en `progress/history.md` cuando cierres la feature. Los aprendizajes
acumulados ahí son de dónde salen las mejoras del harness.

## Sumar un dev nuevo

1. Que lea [`docs/onboarding.md`](docs/onboarding.md) — 15 minutos.
2. Que corra `./verify.sh` y le dé verde antes de tocar nada.
3. Primera contribución: un review, no una implementación. Se aprende el estándar
   más rápido revisando que escribiendo.

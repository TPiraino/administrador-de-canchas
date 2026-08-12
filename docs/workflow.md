# Workflow

El ciclo de vida de todo cambio, y los gates que no se saltean.

---

## Máquina de estados

Cada feature vive en su propio archivo `state/features/<slug>.json`, con
exactamente uno de estos estados:

```
                    ┌──────────────┐
                    │   proposed   │  idea registrada, sin spec
                    └──────┬───────┘
                           │
                           ▼
                    ┌──────────────┐
                    │  spec_draft  │  se escriben requirements → design → tasks
                    └──────┬───────┘
                           │
                    ═══════╪═══════  GATE 1 — aprobación humana (C2)
                           │
                           ▼
                    ┌──────────────┐
                    │spec_approved │  habilitada para implementar, nadie la tomó
                    └──────┬───────┘
                           │
                           ▼
                    ┌──────────────┐
                    │ in_progress  │  ← único estado que permite escribir código
                    └──────┬───────┘
                           │
                           ▼
                    ┌──────────────┐
                    │  in_review   │  contexto fresco revisa diff vs spec (C5)
                    └──────┬───────┘
                           │
                    ═══════╪═══════  GATE 2 — verify.sh verde + review aprobado
                           │
                           ▼
                    ┌──────────────┐
                    │     done     │
                    └──────────────┘

  Cualquier estado ──▶ archived   (descartada; se registra el motivo)
  in_review ──▶ in_progress       (review rechazó; vuelve con findings)
```

**Invariante que enforcea el harness:** un `owner` no puede tener más de una
feature en `in_progress`. Varios devs pueden tener una cada uno; una misma
persona, no.

**Por qué un archivo por feature:** con un único `features.json`, cada rama que
avanza una feature toca la misma línea del mismo archivo y todo merge es un
conflicto. Con un archivo por feature, dos personas en features distintas nunca
chocan — y si chocan, es porque las dos tocaron la misma feature, que es
información útil y no ruido.

## Las fases

### 1. Propose

Se crea `state/features/<slug>.json` copiando `state/_template.json`, con estado
`proposed`. Slug en kebab-case, un título de una línea. Nada más — todavía no
sabemos qué es.

No hay gate. Proponer es gratis.

### 2. Spec

Se crea `specs/<slug>/` con tres documentos, **en este orden**, y cada uno se
termina antes de empezar el siguiente:

1. **`requirements.md`** — el *qué*. Requisitos en notación EARS, numerados `R1`,
   `R2`, … Nada de tecnología acá.
2. **`design.md`** — el *cómo*, y sobre todo el *por qué de ese cómo*.
   Alternativas consideradas y descartadas, con motivo.
3. **`tasks.md`** — el plan de ejecución. Checklist de tareas chicas, cada una
   trazable a uno o más requisitos.

El formato completo está en [`specs/README.md`](../specs/README.md).

**Ambigüedad:** si al escribir requirements hay algo que admite dos lecturas
razonables, se marca `[AMBIGUO: pregunta]` y se pregunta antes de seguir. No se
resuelve por adivinanza — un requisito mal interpretado propaga el error hasta
los tests.

Estado: `proposed` → `spec_draft`.

### 3. Gate 1 — Aprobación humana

Un humano lee la spec y la aprueba explícitamente. No es una formalidad: es el
punto más barato del ciclo para descubrir que el problema estaba mal entendido.

Al aprobar se registra en el archivo de la feature: estado `spec_approved` y
`approval: { by, at }`. `verify.sh` falla si una feature está en `spec_approved` o
posterior sin ese registro — el gate no se puede saltear por olvido.

**Este gate no lo puede pasar un agente.** Si estás leyendo esto como agente y
la feature no está en `spec_approved`, no escribas código de producto (C2).

### 4. Implement

Estado: `spec_approved` → `in_progress`, y se setea `owner`. Tomar la feature es
declarar que es tuya: nadie más la avanza en paralelo.

Se ejecuta `tasks.md` en orden, tildando tareas a medida que se completan. Reglas:

- **Test primero** para cada requisito. El test menciona el ID (`R3`) y falla
  antes de existir la implementación (C3).
- Un commit por tarea o por grupo coherente de tareas. Un propósito por commit (C6).
- Si aparece algo que la spec no previó: **se para**. O se enmienda la spec, o se
  registra como feature nueva. No se improvisa fuera de spec (C12).
- `progress/current.md` se actualiza al terminar cada sesión de trabajo, aunque
  quede a medias. Es el handoff para el próximo contexto (C1).

### 5. Review

Estado: `in_progress` → `in_review`.

Lo hace un contexto fresco que **no vio la implementación** (C5). Recibe
exactamente tres cosas: el diff, la spec de la feature, y
[`docs/verification.md`](verification.md).

Verifica, en este orden:

1. ¿Cada requisito `R#` tiene un test que lo referencia y pasa?
2. ¿El código hace lo que dice la spec, sin agregados no especificados?
3. ¿Hay violaciones de la constitución? (citar artículo)
4. ¿`./verify.sh` está verde?

Escribe el resultado en `progress/review_<slug>.md`. Veredicto binario:
**aprobado** o **rechazado con findings**. Nada de "aprobado con observaciones" —
si hay algo que arreglar, está rechazado.

### 6. Gate 2 — Verde y aprobado

`./verify.sh` verde **y** review aprobado. Ambos. Estado → `done`, se mueve el
resumen a `progress/history.md`, y `progress/current.md` queda limpio.

Si el review rechazó: vuelve a `in_progress` con los findings. El mismo contexto
que implementó puede arreglar; el review siguiente vuelve a ser fresco.

---

## Cambios sobre algo ya especificado

Cuando lo que querés no es una feature nueva sino **modificar** algo que ya tiene
spec y código, no se edita la spec en el lugar. Se abre una propuesta en
`changes/`, se aprueba, se aplica, y recién entonces se actualiza la spec.

El detalle está en [`changes/README.md`](../changes/README.md).

**Por qué la distinción:** una spec editada en el lugar pierde el registro de por
qué cambió. Y una spec que cambia mientras hay código vivo contra la versión
anterior es la forma más rápida de tener divergencia silenciosa (C12).

---

## Qué está exento de todo esto

- Archivos del harness: `docs/`, `specs/`, `changes/`, `state/`, `progress/`,
  `.claude/`, `AGENTS.md`, `CLAUDE.md`, `verify.sh`.
- Configuración de tooling: linters, formatters, CI, Docker, `package.json`.
- Correcciones que no cambian comportamiento observable: typos, formato,
  comentarios.

Todo lo demás pasa por el ciclo.

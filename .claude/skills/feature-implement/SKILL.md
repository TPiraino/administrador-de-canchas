---
name: feature-implement
description: 'Usar para implementar una feature ya tomada en este repo — ejecuta tasks.md en orden, con test primero y el ID del requisito en el nombre del test. Disparadores: "implementá X", "seguí con la feature", "hacé la tarea T3". Reemplaza a executing-plans / subagent-driven-development para este proyecto.'
---

# feature-implement

Ejecuta `specs/<slug>/tasks.md` en orden. Test primero, un commit por tarea, y
**pará** si aparece algo que la spec no previó.

## Precedencia

En este repo **esta skill reemplaza** a `executing-plans` y
`subagent-driven-development`: el plan es `tasks.md` y el estado de avance son los
tildes de ese archivo, no un TODO en otro formato.

Las skills de stack (`dev-nestjs`, `dev-nextjs`, `dev-terraform`) **sí** siguen
sirviendo: dicen *cómo* escribir bien el código de cada tecnología. Esta skill
dice *qué* escribir, en qué orden, y cuándo parar. Se usan juntas.

`test-driven-development` es compatible y la refuerza; la diferencia acá es que el
test además tiene que **mencionar el ID del requisito** en su nombre.

## Precondiciones — pará si alguna falla

```bash
jq '{state, owner}' state/features/<slug>.json
git branch --show-current
```

- `state` tiene que ser `in_progress`. Si está en `spec_approved`, falta tomarla:
  usá `feature-take`. Si no, el hook `guard-spec-gate` te va a bloquear el primer
  Write.
- El `owner` tiene que ser vos (`git config user.name`). Si es otra persona,
  **pará**: está trabajando en esto. Hablá antes de tocar nada.
- Tenés que estar en `feat/<slug>`, no en `main`.

Leé la spec completa antes de escribir nada: `requirements.md`, `design.md`,
`tasks.md`. No implementes desde el título de la tarea.

## El loop, por tarea

Para cada tarea de `tasks.md`, en orden:

### 1. Test primero (C3)

El nombre del test **empieza con el ID del requisito**:

```typescript
it('R2 — rechaza con conflicto si el horario está ocupado', async () => { ... });
```

Ese string literal es lo que `verify.sh` busca para la trazabilidad. Sin él, el
requisito queda huérfano y CI falla.

### 2. Verificá que el test falla

Corré el test y **mirá que falle por el motivo correcto** — porque falta la
implementación, no porque tiene un error de sintaxis o un import roto. Un test que
nunca falló no prueba nada.

### 3. Implementá lo mínimo

Lo mínimo que hace pasar el test. Nada de "ya que estoy":

- Sin abstracciones antes del tercer caso concreto (C7)
- Sin flags de configuración "para cuando lo necesitemos"
- Sin endpoints, campos ni comportamiento que la spec no pidió — **scope no
  especificado es un rechazo en el review**, no un bonus (C6)

Seguí `docs/conventions.md`. Si hay código alrededor, la consistencia con ese
código gana sobre la página de convenciones.

### 4. Verificá que pasa

Y que los anteriores siguen pasando.

### 5. Tildá y commiteá

El tilde de la tarea va **en el mismo commit** que el trabajo. `tasks.md` es el
progreso real, no una intención.

```bash
git commit -m "feat(<slug>): <qué> (R2)"
```

Un propósito por commit (C6). Si el mensaje necesita un "y", son dos commits.

## Cuándo PARAR

Estas no son excepciones raras: son el caso normal a mitad de una feature.

| Situación | Qué hacés |
|---|---|
| Aparece algo que la spec no previó | **Pará.** O se enmienda la spec (y se dice), o es una feature nueva. No improvises fuera de spec (C12) |
| Un contrato que `design.md` daba por existente no existe | **Pará.** Verificá en el código; si no está, es un error de la spec (C8) |
| Un requisito resulta ambiguo al implementarlo | **Pará y preguntá.** No elijas la lectura más cómoda |
| Una tarea es mucho más grande de lo que parecía | **Pará.** Partila en `tasks.md` y decilo |
| Hace falta un refactor de algo existente | **Pará.** Refactor y feature no van en el mismo cambio (C6) |

Parar y preguntar no es fallar. Seguir adelante adivinando sí.

## Al cerrar la sesión de trabajo

Aunque quede a medias — **sobre todo** si queda a medias:

1. Actualizá `progress/current.md`: qué quedó hecho, en qué tarea estás, cuál es
   el próximo paso concreto, y cualquier cosa que descubriste y no está en la spec
2. `./verify.sh` y **mirá el output**
3. Commiteá y pusheá

## Al terminar todas las tareas

1. Todas las tareas tildadas
2. `./verify.sh` verde, con el output visto (C13)
3. `specs/<slug>/` refleja lo que quedó implementado, no lo que se planeó (C12).
   Si hubo desvíos, la spec se actualiza y el desvío se anota
4. `progress/current.md` al día

Reportá con evidencia: el output real de `verify.sh`, no "todo verde". Si algo no
se pudo correr, decí qué y por qué.

Próximo paso: `feature-review`. **No te revises a vos mismo** (C5) — ya te
convenciste de que está bien.

---
name: feature-take
description: 'Usar para tomar una feature aprobada antes de escribir código — setea owner e in_progress, crea la rama y actualiza el handoff, y lo commitea todo ANTES de que exista código. Disparadores: "arranco con X", "tomo la feature Y", "empecemos a implementar X".'
---

# feature-take

Tomar una feature: pasarla a `in_progress` con `owner`, crear la rama, actualizar
el handoff, y **commitear eso antes de escribir una línea de código**.

## Por qué es una skill separada de `feature-implement`

Porque lo único que importa de tomar una feature es que sea **público antes** de
que exista el código. Si esto fuera parte de implementar, el commit de "tomé
esto" llegaría junto con 400 líneas, y ahí ya no avisa nada a nadie: el resto del
equipo se enteraría cuando ya no hay vuelta atrás.

## Procedimiento

### 1. Precondiciones — pará si alguna falla

```bash
jq '{state, owner, approval}' state/features/<slug>.json
```

- `state` tiene que ser **`spec_approved`**. Si está en `spec_draft`, falta el
  Gate 1: usá `spec-approve`. Si está en `in_progress`, ya está tomada — mirá el
  `owner`.
- `approval.by` y `approval.at` tienen que estar completos. Si están vacíos, el
  gate se salteó: pará y reportalo, no lo rellenes (C2).
- `specs/<slug>/tasks.md` tiene que existir y tener tareas de verdad.

### 2. No tengas dos features en vuelo

```bash
for f in state/features/*.json; do
  jq -r 'select(.state=="in_progress") | "\(.slug) → \(.owner)"' "$f"
done
```

Si ya tenés una `in_progress` con tu `owner`, **pará**. Un dev, una feature. Para
liberarte: volvé la otra a `spec_approved` con `owner: null` y una nota en su
`history` diciendo por qué se pausó.

Que otra persona tenga una en vuelo es normal y no bloquea nada.

### 3. Rama

```bash
git switch -c feat/<slug>
```

Si la feature es una corrección sobre algo existente, `fix/<slug>`. Una rama por
feature, nunca dos features en la misma rama.

### 4. Estado

```bash
git config user.name   # este es tu owner
date +%F
```

En `state/features/<slug>.json`:

- `state: "in_progress"`
- `owner: "<tu nombre de git>"`
- Entrada nueva en `history`

### 5. Handoff

`progress/current.md` tiene que **mencionar el slug** — `verify.sh` falla si no
(C1). Reescribí la sección "Estado" con:

- Qué feature está en curso y quién la tiene
- El link a `specs/<slug>/`
- La primera tarea de `tasks.md`
- "Próximo paso" concreto

No dejes el texto de la sesión anterior. El handoff sirve si describe el presente.

### 6. Commit, antes del código

```bash
./verify.sh --harness
git add state/features/<slug>.json progress/current.md
git commit -m "chore(<slug>): tomar feature (in_progress)"
git push -u origin feat/<slug>
```

El `push` es la parte que hace público el acto. Sin eso, nadie sabe que la
tomaste.

## Qué NO hacés en esta skill

- **No escribís código ni tests.** Eso es `feature-implement`, en el turno
  siguiente.
- **No creás la estructura de directorios** de `apps/` o `packages/` "para tenerla
  lista". Cada archivo se crea cuando una tarea lo necesita (C7).

## Al terminar

Reportá: slug, owner, rama creada y pusheada, y la primera tarea de `tasks.md`.
Decí que el próximo paso es `feature-implement`.

---
name: feature-close
description: 'Usar para cerrar una feature revisada y aprobada en este repo — chequea el Gate 2 completo, corre verify.sh, mueve el resumen a history.md y pasa a done. Disparadores: "cerrá la feature X", "ya está lista, cerrala", "mergeamos X".'
---

# feature-close

Pasa el Gate 2 y cierra la feature. Es el último punto donde se puede detectar que
algo quedó a medias, así que **no se tilda de memoria**: cada ítem se verifica.

## Precondiciones — pará si alguna falla

```bash
jq '{state, owner, approval}' state/features/<slug>.json
ls progress/review_<slug>.md
```

- `state` tiene que ser **`in_review`**. Si está en `in_progress`, falta el review:
  usá `feature-review`.
- `progress/review_<slug>.md` tiene que existir y su veredicto tiene que ser
  **APROBADO**. Si dice RECHAZADO, la feature vuelve a `in_progress` con los
  findings, no se cierra.
- Si no hay archivo de review, **el review no pasó** (C5). No lo cierres porque
  "el código está bien": eso es exactamente lo que el gate impide.

## Gate 2 — verificar, no tildar de memoria

### 1. `verify.sh` completo, con el output visto

```bash
./verify.sh
```

Verde. Si algún check quedó en SKIP, **decí cuál y por qué** — un skip silencioso
es peor que una falla, porque la falla se ve (C13).

### 2. Tareas

Todas las de `tasks.md` tildadas. Si queda alguna sin tildar: o se hizo y no se
tildó (arreglalo), o no se hizo (no se cierra).

### 3. Trazabilidad real

`verify.sh` ya chequeó que cada `R#` aparece en un test. Vos chequeás lo que el
script no puede: **que el test realmente ejerza el comportamiento**. Un test que se
llama `R3` y no prueba R3 es peor que no tener test, porque miente en verde.

Mirá también los antitests de `docs/verification.md`: mocks que tapan justamente lo
que el requisito pide verificar, tests que pasarían igual si borrás la
implementación, snapshots regenerados sin mirar.

### 4. Spec al día (C12)

`specs/<slug>/` tiene que describir **lo que quedó implementado**, no lo que se
planeó. Si hubo desvíos durante la implementación y no se reflejaron, se reflejan
ahora — o el próximo que lea la spec va a creer algo falso con autoridad.

### 5. Sin residuos

- Sin datos mock persistentes, seeds de ejemplo ni usuarios ficticios (C10)
- Sin secretos ni datos reales en fixtures (C9)
- Sin `any`, `@ts-ignore` sin explicación, ni `catch {}` vacío (C11)
- Sin tests skippeados sin comentario que diga por qué y hasta cuándo
- Sin código comentado "por si acaso"

## Cerrar

### 1. Historial

Agregá la entrada arriba en `progress/history.md`, con el formato que está ahí:
requisitos, owner, spec, qué se hizo, **desvíos de la spec** (si no hubo, decilo) y
**aprendizajes**.

Los aprendizajes no son decorativos: si algo del harness estorbó, va acá, y de ahí
salen las enmiendas. Es el único mecanismo que tiene el harness para mejorar.

### 2. Limpiar el handoff

`progress/current.md` vuelve a "nada en curso", con el resumen movido a `history.md`
y el próximo paso del proyecto si se sabe.

### 3. Estado

En `state/features/<slug>.json`:

- `state: "done"`
- `owner`: dejalo — es el registro de quién la hizo
- Entrada final en `history` con fecha (`date +%F`)

### 4. Commit y merge

```bash
./verify.sh          # última vez, después de tocar el estado
git add -A
git commit -m "chore(<slug>): cerrar feature (done)"
git push
```

El merge a `main` va por PR, con los checks de CI verdes y la aprobación. **No
mergees sin eso** aunque tengas permiso técnico para hacerlo: `main` protegida es
lo que hace que el resto del harness no sea voluntario.

## Al terminar

Reportá:

1. Slug cerrado y requisitos cubiertos
2. Output real de `verify.sh`
3. Desvíos de la spec que hubo
4. Aprendizajes anotados, y si alguno amerita enmendar la constitución o ajustar
   el harness
5. Qué queda liberado: ahora podés tomar otra feature

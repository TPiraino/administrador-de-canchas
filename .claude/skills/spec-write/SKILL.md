---
name: spec-write
description: 'Usar para arrancar o continuar la spec de una feature en este repo — requirements → design → tasks, en ese orden. Disparadores: "escribí la spec de X", "arranquemos la feature Y", "proponé X", "necesito especificar Z". Reemplaza a writing-plans / planner / brainstorming para este proyecto.'
---

# spec-write

Escribe la spec de una feature: `specs/<slug>/{requirements,design,tasks}.md`, en
ese orden y sin adelantarse.

## Precedencia

En este repo **esta skill reemplaza** a `writing-plans`, `planner` y
`brainstorming`. El plan de una feature es `specs/<slug>/tasks.md`, no un plan
suelto en otro formato. No invoques esas skills acá: producen artefactos que el
harness no reconoce y que `verify.sh` no puede verificar.

## Antes de empezar

Leé, en este orden:

1. `docs/constitution.md` — sobre todo C2, C7, C8
2. `specs/README.md` — el formato EARS y las reglas de IDs
3. `docs/workflow.md`, sección "Spec"

## Procedimiento

### 1. Slug y archivo de estado

Definí el slug en kebab-case, corto y descriptivo del *problema*, no de la
solución (`reserva-de-cancha`, no `endpoint-post-reservas`).

```bash
ls state/features/<slug>.json 2>/dev/null
```

Si no existe, creá desde `state/_template.json` con `state: "proposed"`,
`created` y la entrada inicial de `history` (usá `date +%F` para la fecha, no la
adivines).

Si ya existe y está en `spec_approved` o posterior: **pará**. La spec ya fue
aprobada; para cambiarla el camino es `changes/` (ver `changes/README.md`), no
editarla en el lugar (C12).

### 2. `requirements.md` — el qué

```bash
cp -r specs/_template specs/<slug>
```

Completá `requirements.md`. Reglas que no se negocian:

- **EARS.** Las cinco formas están en `specs/README.md`. Un requisito, una
  obligación: si tiene un "y" que une dos comportamientos verificables por
  separado, son dos requisitos.
- **IDs al principio de línea** como `R1 `, `R2 `. Es lo que parsea `verify.sh`;
  si el ID no está al inicio de la línea, el requisito es invisible para la
  trazabilidad.
- **Sin tecnología.** Nada de tablas, endpoints, librerías ni nombres de clases.
- **Verificable.** Si no se te ocurre el test, el requisito está mal escrito.
- **"Fuera de alcance" completo.** Es la sección que evita la mayoría de las
  discusiones en el review.
- **Criterios de aceptación** colgados del requisito que cubren (`R2.a`, `R2.b`):
  entradas vacías, límites, concurrencia, autorización.

### 3. Gate de ambigüedad — PARÁ ACÁ

Todo lo que admita dos lecturas razonables se marca `[AMBIGUO: <pregunta
concreta>]` en la sección correspondiente.

**Si queda una sola ambigüedad, no sigas a `design.md`.** Preguntá al humano, en
una lista corta y concreta. Un requisito mal interpretado propaga el error hasta
los tests, y ahí cuesta 20 veces más.

No resuelvas ambigüedades por adivinanza ni por "lo más razonable". Si el humano
no está disponible, dejá la spec en `spec_draft` con las ambigüedades marcadas y
decilo explícitamente al reportar.

### 4. `design.md` — el cómo, y el por qué de ese cómo

Solo cuando `requirements.md` no tiene ningún `[AMBIGUO:`.

- **Enfoque** en menos de una página. Si no cabe, la feature es demasiado grande:
  proponé partirla en varias.
- **Al menos una alternativa descartada**, con motivo concreto. "Más complejo" no
  es un motivo. Sin descarte, el diseño no se puede evaluar ni revisitar.
- **Contratos verificados en el código antes de escribirlos** (C8). Todo lo que
  ya existe se busca con Grep/Read y se marca ✅. Lo que no se pudo verificar va
  con ⚠️ y se dice explícitamente. **No inventes** tablas, columnas, endpoints,
  tipos ni variables de entorno.
- **Riesgos con su forma de detección.** Un riesgo sin forma de detectarlo es un
  riesgo que vas a descubrir por el reclamo de un usuario (C11).

### 5. `tasks.md` — el plan de ejecución

- Orden de dependencia. **Test antes de implementación** (C3).
- Cada tarea referencia los requisitos que cubre: `(R1, R2)`.
- Cada tarea es de una sesión de trabajo o menos, y es verificable al terminar.
- Todo requisito `R#` tiene que aparecer en al menos una tarea. Si alguno no
  aparece, o falta una tarea o el requisito no era necesario.

### 6. Cerrar el estado

Actualizá `state/features/<slug>.json`:

- `state: "spec_draft"`
- Entrada nueva en `history` con fecha (`date +%F`), estado y una nota corta

```bash
./verify.sh --harness
```

Tiene que dar verde antes de reportar.

## Qué NO hacés en esta skill

- **No aprobás la spec.** Escribir `approval` o pasar a `spec_approved` es del
  humano, vía `spec-approve` (C2). Ni siquiera si el humano dijo "hacela y
  aprobala": el gate existe para que alguien la *lea*.
- **No escribís código de producto.** El hook te va a bloquear igual.
- **No creás scaffolding** "para que esté listo". Nada de directorios vacíos ni
  archivos placeholder en `apps/` o `packages/` (C7).

## Al terminar

Reportá al humano:

1. El slug y los archivos creados
2. La lista de requisitos con una línea cada uno
3. Las ambigüedades que quedaron abiertas, si quedaron
4. Los contratos marcados ⚠️ que no se pudieron verificar
5. Que el próximo paso es el Gate 1

Antes de pedir la aprobación, conviene pasar el agente `spec-critic`: ataca la
spec buscando ambigüedad y requisitos no verificables. Es mucho más barato que
descubrirlo implementando.

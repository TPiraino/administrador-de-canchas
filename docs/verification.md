# Verificación

Qué significa "listo", y cómo se prueba. Es la referencia que recibe el reviewer
junto con el diff y la spec.

---

## La regla

`./verify.sh` verde es condición **necesaria** y no suficiente. Necesaria porque
sin eso nada está listo. No suficiente porque `verify.sh` no puede juzgar si el
código hace lo que la spec pedía — eso lo juzga el review.

```bash
./verify.sh            # consistencia del harness + checks del stack
./verify.sh --harness  # solo harness: rápido, no necesita dependencias instaladas
```

## Qué chequea `verify.sh`

### Capa 1 — Consistencia del harness

Corre siempre, no necesita nada instalado:

| Check | Falla si… |
|---|---|
| Archivos de feature válidos | un `state/features/<slug>.json` no parsea, o su `state` no está en el conjunto permitido, o el `slug` no coincide con el nombre del archivo |
| Gate humano registrado | una feature en `spec_approved` o posterior no tiene `approval.by` y `approval.at` (C2) |
| Un `in_progress` por owner | un mismo `owner` tiene dos o más features en `in_progress` |
| Specs completas | una feature en `spec_approved` o posterior no tiene los tres archivos |
| Requisitos con ID | un `requirements.md` no tiene ningún `R<n>` |
| **IDs únicos en el proyecto** | un mismo `R<n>` está declarado en dos features — la trazabilidad no los podría distinguir |
| Skills y agentes | falta uno de los 6 skills o 2 agentes, o su frontmatter YAML es inválido |
| Ambigüedades resueltas | una feature aprobada todavía tiene `[AMBIGUO:` en sus requisitos |
| **Trazabilidad** | un requisito de una feature `in_progress`/`in_review`/`done` no está mencionado en ningún test (C3) |
| Sin secretos | un archivo trackeado matchea un patrón de credencial (C9) |
| Handoff presente | hay una feature en curso y `progress/current.md` no la menciona |

### Capa 2 — Checks del stack

Corren solo si el proyecto ya tiene código. Cada uno se saltea con aviso
explícito si la herramienta no está — nunca en silencio (C13):

1. **Typecheck** — `tsc --noEmit`. Cero errores. No se silencia con `any` ni con
   `@ts-ignore` sin comentario que explique por qué.
2. **Lint** — cero errores. Los warnings se toleran pero se cuentan.
3. **Tests** — todos verdes. Ningún test skippeado sin un comentario que diga
   por qué y hasta cuándo.
4. **Build** — compila.
5. **Migraciones** — aplican en limpio y son reversibles.

## Qué chequea el review (y `verify.sh` no puede)

En este orden, porque el primero que falla corta:

1. **Trazabilidad real.** No que el string `R3` aparezca en un test —
   `verify.sh` ya chequeó eso— sino que el test **realmente pruebe** R3. Un test
   que se llama `R3` y no ejerce el comportamiento es peor que no tener test.
2. **Fidelidad a la spec.** ¿Hace lo que la spec pedía? ¿Hace algo **más** que la
   spec no pedía? Lo segundo también es un rechazo: scope no especificado es
   código que nadie decidió tener (C6).
3. **Casos de borde.** ¿Están los criterios de aceptación cubiertos?
4. **Violaciones de constitución.** Citando artículo.
5. **Calidad.** Legibilidad, consistencia con el código de alrededor,
   duplicación. Última prioridad: importante, pero no bloquea si todo lo de
   arriba está bien y el código es entendible.

## Definición de "listo"

Una feature está `done` cuando **todo** esto es cierto:

- [ ] Todas las tareas de `tasks.md` tildadas
- [ ] Cada requisito `R#` con al menos un test que lo prueba de verdad
- [ ] `./verify.sh` verde, con el output visto (no asumido)
- [ ] Review con contexto fresco: veredicto **aprobado**
- [ ] `specs/<slug>/` refleja lo que quedó implementado (C12)
- [ ] `progress/current.md` limpio, resumen movido a `progress/history.md`

## Cómo se reporta

Con evidencia, no con adjetivos (C13). El output del comando, no "todo bien".

Si algo no se pudo correr —falta una dependencia, no hay base de datos, el
entorno no está— se dice explícitamente qué no se verificó y por qué. Un check
salteado en silencio es peor que un check que falla, porque el que falla se ve.

## Antitest

Cosas que **no** cuentan como verificación:

- "Lo probé y funciona" sin output.
- Un test que mockea justamente la cosa que el requisito pide verificar.
- Un test que pasaría igual si borrás la implementación.
- `expect(true).toBe(true)` en cualquiera de sus formas.
- Un snapshot regenerado sin mirarlo.

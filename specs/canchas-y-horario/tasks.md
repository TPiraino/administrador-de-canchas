# Tareas — Canchas y su horario habitual

- **Slug:** `canchas-y-horario`
- **Diseño:** [`design.md`](design.md)

El orden de ejecución es el orden del archivo. Test antes de implementación (C3).
Cada tarea referencia los requisitos que cubre. Los tildes se actualizan **en el
mismo commit** que el trabajo: este archivo es el progreso real, no una intención.

> Los IDs `T#` son locales a esta feature. Los `R#` son globales del proyecto — ver
> [`specs/README.md`](../README.md).

## Cimientos

- [ ] **T1** — Spike: verificar contra Postgres real que `EXCLUDE USING gist` con
      `int4range` + `btree_gist`, y los `CHECK` sobre `lower()`/`upper()`/
      `isempty()`, funcionan como dice `design.md`. **Es lo primero porque todo el
      modelo se apoya en eso**; si falla hay que rediseñar antes de escribir código.
      Documentar el resultado en `design.md` (⚠️ → ✅, o registrar el fallback).
- [ ] **T2** — Andamiaje: monorepo pnpm (`apps/api`, `packages/shared`), NestJS con
      `strict: true`, Docker Compose con Postgres, `.env.example`. Scripts
      `typecheck`, `lint`, `test`, `build` para que `./verify.sh --stack` deje de
      saltear. **Ojo:** `.pnpm-store/` en la raíz quedó root-owned de la iteración
      previa; hay que borrarlo o cambiarle el owner o `pnpm install` falla con
      EACCES.
- [ ] **T3** — Migración inicial: extensión `btree_gist`, tablas `cancha` y
      `horario_cancha` con sus `CHECK`, `UNIQUE` y `EXCLUDE`. Reversible.
      (R2, R9, R10, R21)

## Resolución — la función pura

Antes que la API a propósito: es lo único con lógica real, no necesita HTTP ni base,
y se testea con tabla de casos. **Se escribe para que la feature siguiente la
extienda, no la duplique.**

- [ ] **T4** — Test: una fecha devuelve las franjas del horario habitual de su día
      de la semana; un día sin franjas devuelve vacío. (R11, R16)
- [ ] **T5** — Test: consultar una fecha a cinco años vista devuelve el horario
      habitual aplicado, sin ninguna carga previa. Es el test que distingue
      «configurado una vez» de «cargado hasta una fecha». (R22)
- [ ] **T6** — Implementación de `resolver()`: función pura, sin DB y sin reloj, con
      la firma preparada para recibir capas adicionales. (R11, R16, R22)

## Canchas

- [ ] **T7** — Test: crear una cancha con nombre, deporte, superficie, techada,
      iluminación y duración de turno; se persiste y se devuelve con id. (R1, R20,
      R21)
- [ ] **T8** — Test: nombre en uso devuelve 409 y no crea nada; la colisión ignora
      mayúsculas y espacios al borde; una cancha inactiva sigue ocupando su nombre.
      (R2)
- [ ] **T9** — Test: nombre vacío, deporte no reconocido y duración de turno ≤ 0
      devuelven 422. Dos canchas con duraciones distintas conviven. (R1, R21)
- [ ] **T10** — Implementación de `CanchasModule`: DTOs con `class-validator`,
      servicio sin HTTP, excepciones de dominio mapeadas en un filtro. (R1, R2, R20,
      R21)
- [ ] **T11** — Test + implementación: listar canchas incluyendo inactivas; sin
      canchas devuelve lista vacía, no error. (R4)
- [ ] **T12** — Test + implementación: modificar atributos de una cancha existente.
      (R3)
- [ ] **T13** — Test + implementación: desactivar sin borrar el registro ni la
      configuración; desactivar dos veces es idempotente. (R5)
- [ ] **T14** — Test: una cancha inactiva no aparece en disponibilidad, pero
      conserva su horario y reaparece con él al reactivarla. (R6)

## Horario habitual

- [ ] **T15** — Test: `PUT /canchas/:id/horario` acepta varias franjas por día;
      franjas que se tocan en el borde (12–14 y 14–18) se aceptan. (R7, R8)
- [ ] **T16** — Test: franja con fin ≤ inicio devuelve 422; franja solapada devuelve
      409 informando con cuál. Solapamiento parcial, contención e idéntica: los tres
      se rechazan. La misma franja en otra cancha u otro día no es solapamiento.
      Franja que cruzaría medianoche: se rechaza con error claro. (R9, R10)
- [ ] **T17** — Implementación del horario habitual: `PUT` reemplaza la semana
      completa en una transacción, para no dejar la mitad cargada si una franja
      falla. (R7, R8, R9, R10)
- [ ] **T18** — Test: copiar el horario a otra cancha lo **reemplaza completo**, no
      lo fusiona; a varias es atómico (si una falla, ninguna cambia); sobre sí misma
      no falla y no cambia nada; a una inactiva se acepta; destino inexistente
      devuelve 404 sin modificar nada. (R29)
- [ ] **T19** — Implementación de copiar horario, en una sola transacción. Existe
      porque la cantidad de canchas es variable: cargar seis canchas de pádel
      idénticas de a una es donde la herramienta se abandona. (R29)

## Consulta de disponibilidad

- [ ] **T20** — Test: la respuesta incluye **todas** las fechas del rango, con lista
      vacía las que no tienen franjas; nunca se omite una fecha. Rango de un solo
      día. (R16)
- [ ] **T21** — Test: cancha inexistente devuelve 404. (R17)
- [ ] **T22** — Test: rango invertido devuelve 422; rango de exactamente 92 días se
      acepta y de 93 se rechaza informando el límite. (R18, R28)
- [ ] **T23** — Test: el resultado es idéntico consultando desde cualquier zona
      horaria; los horarios se devuelven en la del club. Incluye un rango que cruza
      el cambio de horario de verano. (R19)
- [ ] **T24** — Implementación del endpoint por cancha: trae el horario, llama a
      `resolver()`, serializa a `"HH:MM"`. (R16, R17, R18, R19, R28)
- [ ] **T25** — Test: `GET /disponibilidad` sin id devuelve todas las canchas
      activas; excluye inactivas aunque tengan horario; sin activas devuelve lista
      vacía y no error. **Y el resultado por cancha es idéntico al de la consulta
      individual** — es el test que impide que los dos caminos se separen. (R30)
- [ ] **T26** — Test: la consulta de todas acepta 31 días y rechaza 32 informando el
      límite. Medir el tamaño de la respuesta en el máximo, para tener el número
      documentado antes de que sea un problema. (R31)
- [ ] **T27** — Implementación del endpoint de todas, **reusando la misma
      `resolver()`** de T6. Una segunda implementación del cálculo es un rechazo de
      review. (R30, R31)

## Cierre

- [ ] **T28** — Guard de arranque: la aplicación **falla al arrancar** si
      `NODE_ENV=production` y no hay autenticación configurada. Mitiga el riesgo más
      serio de la feature haciéndolo ruidoso en vez de silencioso (C11). Con su test.

- [ ] Todos los requisitos de esta feature referenciados en al menos un test
- [ ] `./verify.sh` verde, **capa 2 incluida** — ya hay código, así que typecheck,
      lint, tests y build tienen que correr de verdad
- [ ] `design.md` actualizado con el resultado de T1 (⚠️ → ✅ o el fallback)
- [ ] La spec refleja lo implementado, no lo planeado (C12)
- [ ] `progress/current.md` actualizado
- [ ] Review con contexto fresco aprobado (C5)

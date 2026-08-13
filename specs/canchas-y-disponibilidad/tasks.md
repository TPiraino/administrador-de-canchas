# Tareas — Definir canchas y su disponibilidad horaria

- **Slug:** `canchas-y-disponibilidad`
- **Diseño:** [`design.md`](design.md)

**El orden de ejecución es el orden del archivo.** Los números `T#` son etiquetas
estables y no se reutilizan, así que una tarea agregada después puede aparecer con
un número fuera de secuencia. Test antes de implementación (C3). Cada tarea
referencia los requisitos que cubre. Los tildes se actualizan **en el mismo commit**
que el trabajo: este archivo es el progreso real, no una intención.

> ⚠️ **Nota de tamaño para el Gate 1 — cada vez más fuerte.** Son **39 tareas y 31
> requisitos**. Creció al confirmarse que la cantidad de canchas es variable, que
> agregó copiar horario y la consulta de todas. Costura natural para partirla:
> **hasta T18** (andamiaje + canchas + resolución) y **desde T19** (las tres capas +
> consultas). Partirla da dos features revisables y un primer merge más temprano;
> dejarla junta evita definir una API de canchas sin saber qué necesita la
> disponibilidad. **Lo decide el humano al aprobar** — recomiendo partirla, y con 39
> tareas lo recomiendo más que antes.

## Cimientos

- [ ] **T1** — Spike: verificar contra Postgres real que `EXCLUDE USING gist` con
      `int4range` + `btree_gist`, y los `CHECK` sobre `lower()`/`upper()`/`isempty()`,
      funcionan como dice `design.md`. **Es lo primero porque todo el modelo se apoya
      en eso**, y si falla hay que rediseñar antes de escribir código. Documentar el
      resultado en `design.md` (cambiar ⚠️ por ✅, o registrar el fallback).
- [ ] **T2** — Andamiaje: monorepo pnpm (`apps/api`, `packages/shared`), NestJS con
      `strict: true`, Docker Compose con Postgres, `.env.example`. Scripts
      `typecheck`, `lint`, `test`, `build` para que `./verify.sh --stack` deje de
      saltear.
- [ ] **T3** — Migración inicial: extensión `btree_gist`, tablas `cancha`,
      `horario_cancha`, `disponibilidad_especial`, `excepcion`, con sus `CHECK`,
      `UNIQUE` y `EXCLUDE`. Reversible. (R2, R9, R10, R21, R24, R25)

## Resolución — la función pura, el corazón de la feature

Se hace antes que la API a propósito: es lo único difícil, no necesita HTTP ni base,
y se testea con tabla de casos.

- [ ] **T4** — Test: una fecha sin disponibilidad especial ni excepciones devuelve
      el horario semanal de ese día de la semana; un día sin franjas devuelve vacío.
      (R11, R27)
- [ ] **T5** — Test: una fecha con disponibilidad especial **ignora por completo**
      el horario semanal de ese día — no lo suma ni lo intersecta. Incluye el caso
      de abrir *más* de lo habitual (torneo hasta 02:00). (R23, R27)
- [ ] **T6** — Test: una excepción resta de la base. Incluye excepción parcial que
      **parte** la franja en dos, excepción que cubre todo, y excepción que cae
      fuera de toda franja. (R13, R27)
- [ ] **T7** — Test: dos excepciones solapadas en la misma fecha cierran la unión de
      ambas, sin contar el solapamiento dos veces. (R13)
- [ ] **T8** — Test: consultar una fecha a cinco años vista devuelve el horario
      semanal aplicado, sin ninguna carga previa. Es el test que distingue
      "configurado una vez" de "cargado hasta una fecha". (R22)
- [ ] **T9** — Test: fecha con disponibilidad especial **y** excepción — la
      excepción resta de la especial, no del horario semanal. **Este es el test que
      detecta el orden de resolución invertido**, el riesgo principal del diseño.
      (R27)
- [ ] **T10** — Implementación de `resolver()`: función pura, sin DB y sin reloj.
      Normaliza excepciones a unión de intervalos antes de restar. (R11, R13, R22,
      R23, R27)

## Canchas

- [ ] **T11** — Test: crear una cancha con nombre, deporte, superficie, techada,
      iluminación y duración de turno; se persiste y se devuelve con id. (R1, R20,
      R21)
- [ ] **T12** — Test: nombre en uso devuelve 409 y no crea nada; la colisión ignora
      mayúsculas y espacios al borde; una cancha inactiva sigue ocupando su nombre.
      (R2)
- [ ] **T13** — Test: nombre vacío, deporte no reconocido y duración de turno ≤ 0
      devuelven 422. Dos canchas con duraciones distintas conviven. (R1, R21)
- [ ] **T14** — Implementación de `CanchasModule`: DTOs con `class-validator`,
      servicio sin HTTP, excepciones de dominio mapeadas en un filtro. (R1, R2, R20,
      R21)
- [ ] **T15** — Test + implementación: listar canchas, incluyendo inactivas; sin
      canchas devuelve lista vacía, no error. (R4)
- [ ] **T16** — Test + implementación: modificar atributos de una cancha existente.
      (R3)
- [ ] **T17** — Test + implementación: desactivar una cancha sin borrar su registro
      ni su configuración; desactivar dos veces es idempotente. (R5)
- [ ] **T18** — Test: una cancha inactiva no aparece en disponibilidad, pero
      conserva horario y disponibilidad especial, y ambos reaparecen al reactivarla.
      (R6)

## Horario semanal

- [ ] **T19** — Test: `PUT /canchas/:id/horario` acepta varias franjas por día;
      franjas que se tocan en el borde (12–14 y 14–18) se aceptan. (R7, R8)
- [ ] **T20** — Test: franja con fin ≤ inicio devuelve 422; franja solapada devuelve
      409 informando con cuál. Solapamiento parcial, contención e idéntica: los tres
      se rechazan. La misma franja en otra cancha u otro día no es solapamiento.
      (R9, R10)
- [ ] **T21** — Implementación del horario semanal: `PUT` reemplaza la semana
      completa en una transacción, para no dejar la mitad cargada si una franja
      falla. (R7, R8, R9, R10)
- [ ] **T35** — Test: copiar el horario de una cancha a otra lo **reemplaza
      completo**, no lo fusiona; a varias canchas es atómico (si una falla, ninguna
      cambia); no arrastra disponibilidad especial ni excepciones; sobre sí misma no
      falla y no cambia nada; a una cancha inactiva se acepta. Cancha destino
      inexistente devuelve 404. (R29)
- [ ] **T36** — Implementación de copiar horario, en una sola transacción. Existe
      porque la cantidad de canchas es variable: cargar seis canchas de pádel
      idénticas de a una es donde la herramienta se abandona. (R29)

## Disponibilidad especial

- [ ] **T22** — Test: `PUT /canchas/:id/especial/:fecha` define franjas para esa
      fecha; una lista vacía deja la cancha cerrada ese día, distinto de no tener
      disponibilidad especial. (R23)
- [ ] **T23** — Test: validaciones de franja en especial — fin ≤ inicio devuelve
      422, solapada devuelve 409. (R24, R25)
- [ ] **T24** — Test: `DELETE` de la disponibilidad especial devuelve la fecha a
      exactamente lo que dicta el horario semanal. (R26)
- [ ] **T25** — Implementación de disponibilidad especial. (R23, R24, R25, R26)

## Excepciones

- [ ] **T26** — Test: registrar una excepción de cierre con motivo, total o parcial.
      Excepción sobre una fecha ya cerrada se acepta y no cambia nada observable.
      (R12, R14)
- [ ] **T27** — Test: eliminar una excepción devuelve el tramo a disponible. (R15)
- [ ] **T28** — Implementación de excepciones. Sin `EXCLUDE`: pueden solaparse entre
      sí a propósito. (R12, R14, R15)

## Consulta de disponibilidad

- [ ] **T29** — Test: la respuesta incluye **todas** las fechas del rango, con lista
      vacía las que no tienen franjas; nunca se omite una fecha. Rango de un solo
      día. (R16)
- [ ] **T30** — Test: cancha inexistente devuelve 404. (R17)
- [ ] **T31** — Test: rango invertido devuelve 422; rango de exactamente 92 días se
      acepta y de 93 se rechaza informando el límite. (R18, R28)
- [ ] **T32** — Test: el resultado es idéntico consultando desde cualquier zona
      horaria; los horarios se devuelven en la del club. Incluye un rango que cruza
      el cambio de horario de verano. (R19)
- [ ] **T33** — Implementación del endpoint de consulta por cancha: trae las filas
      de las tres capas, llama a `resolver()`, serializa a `"HH:MM"`. (R16, R17, R18,
      R19, R28)
- [ ] **T37** — Test: `GET /disponibilidad` sin id devuelve todas las canchas
      activas; excluye las inactivas aunque tengan horario; sin ninguna activa
      devuelve lista vacía y no error. **Y el resultado por cancha es idéntico al de
      la consulta individual de esa cancha para el mismo rango** — es el test que
      impide que los dos caminos se separen. (R30)
- [ ] **T38** — Test: la consulta de todas acepta 31 días y rechaza 32 informando el
      límite. Medir el tamaño de la respuesta en el máximo, para tener el número
      documentado antes de que sea un problema. (R31)
- [ ] **T39** — Implementación del endpoint de todas las canchas, **reusando la misma
      `resolver()`** de T10. Una segunda implementación del cálculo es un rechazo de
      review. (R30, R31)

## Cierre

- [ ] **T34** — Guard de arranque: la aplicación **falla al arrancar** si
      `NODE_ENV=production` y no hay autenticación configurada. Mitiga el riesgo más
      serio de la feature (A6: sin auth en alcance) haciéndolo ruidoso en vez de
      silencioso (C11). Con su test.

- [ ] Todos los requisitos `R1`–`R31` referenciados en al menos un test
- [ ] `./verify.sh` verde, capa 2 incluida (ya hay código: typecheck, lint, tests,
      build tienen que correr de verdad)
- [ ] `design.md` actualizado con el resultado de T1 (⚠️ → ✅ o el fallback)
- [ ] `specs/canchas-y-disponibilidad/` refleja lo implementado, no lo planeado (C12)
- [ ] `progress/current.md` actualizado
- [ ] Review con contexto fresco aprobado (C5)

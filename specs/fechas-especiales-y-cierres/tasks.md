# Tareas — Fechas especiales y cierres

- **Slug:** `fechas-especiales-y-cierres`
- **Diseño:** [`design.md`](design.md)

El orden de ejecución es el orden del archivo. Test antes de implementación (C3).
Los tildes se actualizan **en el mismo commit** que el trabajo.

> **Precondición:** [`canchas-y-horario`](../canchas-y-horario/tasks.md) tiene que
> estar `done`. Esta feature extiende su `resolver()` y sus tablas.

> Los IDs `T#` son locales a esta feature. Los `R#` son globales del proyecto — ver
> [`specs/README.md`](../README.md).

## Reconciliar con lo que quedó implementado

- [ ] **T1** — Leer lo que `canchas-y-horario` dejó realmente en el código: la firma
      de `resolver()`, las tablas, el patrón de `EXCLUDE`, el resultado del spike de
      Postgres. **Corregir `design.md` donde difiera de lo que asumió** (C8, C12).
      Va primero porque va a diferir en algo, y descubrirlo a mitad de la
      implementación cuesta veinte veces más.

## Operaciones de conjuntos — donde están los errores de borde

Antes que las tablas y antes que la API: son puras, no necesitan nada, y es donde
esta feature se rompe si se rompe.

- [ ] **T2** — Test de `unir(intervalos)`: dos solapados dan uno; dos que se tocan
      en el borde dan uno; dos disjuntos quedan dos; uno contenido en otro da uno;
      lista vacía da vacía. (R13)
- [ ] **T3** — Test de `restar(base, cortes)`: corte al inicio exacto, al fin
      exacto, y en un punto interior que **parte la franja en dos**; corte que cubre
      todo devuelve vacío; corte que cae afuera no cambia nada. Sin bordes corridos
      por un minuto. (R13)
- [ ] **T4** — Implementación de `unir` y `restar`, con rangos semiabiertos igual
      que en la base. (R13)

## Extender la resolución

- [ ] **T5** — Test: una fecha con disponibilidad especial **ignora por completo**
      el horario habitual de ese día — no lo suma ni lo intersecta. Incluye el caso
      de abrir *más* de lo habitual (torneo hasta 23:30 con sábado que cierra 22:00).
      (R23, R27)
- [ ] **T6** — Test: una excepción resta de la base. Incluye la parcial que parte la
      franja en dos, la que cubre todo, y la que cae fuera de toda franja. (R13, R27)
- [ ] **T7** — Test: dos excepciones solapadas cierran la unión de ambas, sin contar
      el solapamiento dos veces. (R13)
- [ ] **T8** — Test: fecha con disponibilidad especial **y** excepción — la excepción
      resta de la especial, no del horario habitual. **Es el test que detecta el
      orden de resolución invertido, el riesgo principal de la feature.** (R27)
- [ ] **T9** — Test de **no regresión**: una fecha sin especial y sin excepción
      devuelve el horario habitual tal cual, idéntico a lo que devolvía antes de esta
      feature. (R27)
- [ ] **T10** — Test: excepción sobre un día que el horario habitual tiene cerrado
      devuelve vacío, no error. (R27)
- [ ] **T11** — **Extender** `resolver()` con los dos parámetros nuevos, sin
      duplicarla. Si la firma existente no lo admite, se refactoriza — no se copia.
      Una segunda implementación del cálculo es un rechazo de review. (R13, R23, R27)

## Migración

- [ ] **T12** — Migración: tablas `disponibilidad_especial` y `excepcion` con sus
      `CHECK` y, solo en la primera, el `EXCLUDE`. **Comentario en la migración
      explicando por qué `excepcion` NO lo tiene** (R12.b), para que nadie lo agregue
      después «por coherencia». Reversible. (R24, R25, R14)

## Disponibilidad especial

- [ ] **T13** — Test: `PUT /canchas/:id/especial/:fecha` define las franjas de esa
      fecha; una lista vacía deja la cancha cerrada ese día, distinto de no tener
      disponibilidad especial; no afecta a ninguna otra fecha. (R23)
- [ ] **T14** — Test: franja con fin ≤ inicio devuelve 422; solapada devuelve 409
      informando con cuál. Solapamiento parcial, contención e idéntica se rechazan;
      la misma franja en dos fechas distintas no es solapamiento. (R24, R25)
- [ ] **T15** — Test: `DELETE` de la disponibilidad especial devuelve la fecha a
      exactamente lo que dicta el horario habitual. (R26)
- [ ] **T16** — Implementación de disponibilidad especial. `PUT` reemplaza la fecha
      completa en una transacción. (R23, R24, R25, R26)

## Excepciones

- [ ] **T17** — Test: registrar una excepción con motivo, total o parcial. Sobre una
      fecha ya cerrada se acepta y no cambia nada observable. **Dos excepciones
      solapadas se aceptan** — a diferencia de las otras dos capas. (R12, R14)
- [ ] **T18** — Test: motivo vacío o solo espacios devuelve 422. Una excepción sin
      motivo es exactamente lo que esta capa vino a evitar. (R14)
- [ ] **T19** — Test: eliminar una excepción devuelve el tramo a disponible;
      eliminar una inexistente devuelve 404. (R15)
- [ ] **T20** — Implementación de excepciones. (R12, R14, R15)

## Integración con la consulta existente

- [ ] **T21** — Test: la consulta de disponibilidad por cancha y la de todas
      devuelven las tres capas resueltas, **sin que cambie el contrato de la API**.
      Una cancha inactiva sigue excluida aunque tenga disponibilidad especial, y la
      conserva al reactivarla. (R27)
- [ ] **T22** — Conectar las dos consultas existentes a la `resolver()` extendida,
      pasándole las capas nuevas. **Sin tocar la forma de la respuesta.** (R27)

## Cierre

- [ ] Todos los requisitos de esta feature referenciados en al menos un test
- [ ] **La suite completa de `canchas-y-horario` sigue verde** — es una feature que
      cambia comportamiento existente, así que la no regresión no es opcional
- [ ] `./verify.sh` verde, capa 2 incluida
- [ ] `design.md` actualizado con lo que T1 encontró
- [ ] La spec refleja lo implementado, no lo planeado (C12)
- [ ] `progress/current.md` actualizado
- [ ] Review con contexto fresco aprobado (C5)

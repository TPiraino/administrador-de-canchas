# Diseño — Fechas especiales y cierres

- **Slug:** `fechas-especiales-y-cierres`
- **Requisitos:** [`requirements.md`](requirements.md)

## Estado de verificación de contratos (C8)

Al escribirse esta spec (2026-08-13) no existía código en el repo, así que **todos
los contratos están marcados 🆕 o 🔗**:

- 🆕 lo que crea esta feature.
- 🔗 lo que hereda de [`canchas-y-horario`](../canchas-y-horario/design.md) y
  **hay que verificar en el código antes de tocarlo** (C8). Cuando esa feature esté
  `done`, la primera tarea de acá es leer lo que quedó realmente implementado y
  corregir este documento si difiere de lo que asumió — porque va a diferir en
  algo.

## Enfoque

Dos tablas nuevas y **una extensión de la función `resolver()` existente**, no una
segunda implementación. Ese es el punto central del diseño: `canchas-y-horario` dejó
`resolver()` como función pura con la firma preparada para recibir capas
adicionales, y esta feature le agrega dos parámetros.

```
resolver(horarioSemanal, especiales, excepciones, rango) → Map<fecha, Franja[]>

por cada fecha del rango:
  base   = especiales[fecha] ?? horarioSemanal[diaSemana(fecha)]
  cortes = unir(excepciones[fecha])        // unión, no suma (R13.b)
  return restar(base, cortes)              // puede partir una franja en dos (R13.a)
```

Sigue siendo pura: sin base de datos y sin reloj. Todo lo difícil de esta feature
—la precedencia, la resta, el partido de una franja— vive ahí y se testea con tablas
de casos.

**Dos operaciones de conjuntos son el corazón:** `unir` normaliza las excepciones
solapadas a intervalos disjuntos (R13.b), y `restar` saca esos intervalos de la
base, que es lo que puede convertir una franja en dos (R13.a). Se testean por
separado de la resolución, porque son donde están los errores de borde.

## Alternativas descartadas

### Solo excepciones, sin la capa de disponibilidad especial

Dos capas en lugar de tres: horario habitual y excepciones que restan. Resolución de
una línea, la mitad de tablas y la mitad de tests.

**Descartada** porque no puede expresar una fecha que abre **más** que lo habitual.
Un torneo hasta las 23:30 cuando el sábado cierra a las 22:00 no se puede
representar restando: no hay nada de donde restar por encima del horario habitual.
R23.b es exactamente ese caso.

### Solo disponibilidad especial, sin excepciones

También dos capas: para cerrar un tramo, se redefine la fecha completa con las
franjas que quedan.

**Descartada** porque pierde el **motivo** y la reversibilidad. Con este modelo,
«cerrado el 15 por feriado» se vuelve indistinguible de «ese día abre distinto», y
al querer restaurar hay que reconstruir a mano lo que decía el horario habitual.
R14 y R15 existen justamente para eso.

### Excepciones con constraint de exclusión, como las otras dos capas

Coherente con `horario_cancha` y `disponibilidad_especial`.

**Descartada a propósito**: las excepciones **sí** pueden solaparse (R12.b), porque
dos cierres que se pisan son un caso real —un feriado y un mantenimiento el mismo
día— y el resultado correcto es la unión, no un error. Es la única de las tres capas
sin `EXCLUDE`, y el comentario tiene que quedar en la migración para que nadie lo
«arregle» después.

### Cierres a nivel club, además de por cancha

Un feriado cierra todas las canchas, así que registrarlo seis veces es tedioso.

**Descartada por ahora** (C7): agrega un segundo nivel de resolución —club sobre
cancha— que duplica la complejidad de R27 justo donde está el riesgo principal. Se
resuelve en la interfaz, aplicando el cierre a las canchas seleccionadas en una sola
acción. Si el modelo resulta insuficiente, entra por `changes/`.

## Contratos

### Datos 🆕

```sql
disponibilidad_especial                      -- reemplaza el horario de esa fecha
  id          uuid pk
  cancha_id   uuid fk → cancha on delete cascade      -- 🔗
  fecha       date not null
  franja      int4range not null              -- minutos desde medianoche, [desde,hasta)

  CHECK  (lower(franja) >= 0 and upper(franja) <= 1440 and not isempty(franja))  -- R24
  EXCLUDE USING gist (cancha_id WITH =, fecha WITH =, franja WITH &&)            -- R25

excepcion                                    -- resta, con motivo
  id          uuid pk
  cancha_id   uuid fk → cancha on delete cascade      -- 🔗
  fecha       date not null
  franja      int4range not null
  motivo      text not null                   -- R14, no vacío
  created_at  timestamptz not null default now()

  CHECK  (lower(franja) >= 0 and upper(franja) <= 1440 and not isempty(franja))
  CHECK  (length(btrim(motivo)) > 0)          -- R14.a
  -- SIN EXCLUDE, A PROPÓSITO: las excepciones pueden solaparse entre sí (R12.b).
  -- El resultado correcto es la unión, no un error. No agregar la constraint
  -- "por coherencia" con las otras dos tablas.
```

Mismo criterio que la feature anterior: `int4range` semiabierto `[desde, hasta)` y
`btree_gist` para el `EXCLUDE`. 🔗 Verificar que la extensión y el patrón quedaron
como dice `canchas-y-horario/design.md` — T1 de esa feature era justamente
comprobarlo.

### API 🆕

```
PUT    /canchas/:id/especial/:fecha              R23, R24, R25  (reemplaza la fecha completa)
DELETE /canchas/:id/especial/:fecha              R26
GET    /canchas/:id/especial?desde=&hasta=

POST   /canchas/:id/excepciones                  R12, R14
DELETE /canchas/:id/excepciones/:excepcionId     R15
GET    /canchas/:id/excepciones?desde=&hasta=
```

`PUT` para la disponibilidad especial: reemplaza el conjunto completo de franjas de
esa fecha, igual que el horario semanal. `POST` para las excepciones: son entidades
individuales con identidad propia, porque se eliminan de a una (R15) y pueden
coexistir solapadas.

**Sin endpoints nuevos de consulta.** Los de `canchas-y-horario` (🔗
`GET /canchas/:id/disponibilidad` y `GET /disponibilidad`) empiezan a devolver las
tres capas sin cambiar su contrato. R16 no cambia de enunciado; cambia cómo se
calcula «disponible».

### Errores

| Situación | HTTP | Requisito |
|---|---|---|
| Franja de especial inválida (fin ≤ inicio) | 422 | R24 |
| Franja de especial solapada | 409 | R25 |
| Motivo de excepción vacío | 422 | R14.a |
| Cancha inexistente | 404 | 🔗 R17 |
| Excepción inexistente al eliminar | 404 | R15 |

## Impacto

- **Migraciones:** dos tablas nuevas. No toca `cancha` ni `horario_cancha`.
  Reversible.
- **Breaking changes:** ninguno en el contrato de la API. **Sí cambia el
  comportamiento observable** de las consultas de disponibilidad, que empiezan a
  descontar cierres. Es el objetivo de la feature, y R27.b es el test de no
  regresión que garantiza que una fecha sin desviaciones sigue devolviendo lo mismo.
- **Comportamiento visible:** el club puede registrar feriados, mantenimientos y
  días especiales, y la disponibilidad los refleja.
- **Módulos que se tocan:** `DisponibilidadModule` nuevo; se **extiende**
  `resolver()`, que vive en el dominio. La consulta existente pasa a pasarle las dos
  capas nuevas.
- **Deuda que deja:** un feriado se registra cancha por cancha. Con seis canchas son
  seis registros para el mismo feriado.

## Riesgos

| Riesgo | Detección | Mitigación |
|---|---|---|
| **Orden de resolución invertido**: la excepción resta del horario habitual en vez de la disponibilidad especial | Test **R27.a**, que es exactamente ese caso. Es el riesgo principal de la feature | `resolver()` es pura: se testea con tabla de casos, sin DB. La precedencia está escrita en un solo lugar |
| Se **duplica** `resolver()` en vez de extenderla, y las dos versiones se separan | Review: si aparece una segunda implementación del cálculo, es rechazo. Y **R30.c** de `canchas-y-horario` sigue exigiendo que las dos consultas coincidan | La firma quedó preparada para recibir capas. Si no alcanza, se refactoriza — no se copia |
| Excepciones solapadas contadas dos veces al restar | Test **R13.b** | Normalizar a unión de intervalos disjuntos **antes** de restar. `unir` se testea aparte de `resolver` |
| Restar parte mal una franja y deja bordes corridos por un minuto | Tests de borde de `restar`: corte al inicio exacto, al fin exacto, y en un punto interior | Rangos semiabiertos en todo el cálculo, igual que en la base |
| Regresión sobre `canchas-y-horario`: una fecha sin desviaciones deja de devolver lo mismo | Test **R27.b**, explícitamente de no regresión | Correr la suite de la feature anterior completa antes de cerrar |
| Alguien agrega un `EXCLUDE` a `excepcion` «por coherencia» y rompe R12.b | Test **R12.b**: dos excepciones solapadas se aceptan | Comentario en la migración explicando por qué no está |
| Un feriado hay que cargarlo seis veces, una por cancha | Si al segundo feriado el operador se queja, sobra fricción | Se resuelve en la interfaz aplicando el cierre a varias canchas en una acción. Modelo sin cambios (C7) |

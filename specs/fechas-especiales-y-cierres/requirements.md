# Requisitos — Fechas especiales y cierres

- **Slug:** `fechas-especiales-y-cierres`
- **Estado:** spec_approved
- **Fecha:** 2026-08-13
- **Depende de:** [`canchas-y-horario`](../canchas-y-horario/requirements.md), que
  tiene que estar `done`. Esta feature extiende su `resolver()`.

## Problema

Con [`canchas-y-horario`](../canchas-y-horario/requirements.md) el club ya puede
configurar el horario habitual de cada cancha y consultarlo. Pero la realidad no
respeta el horario habitual: hay feriados, mantenimientos, torneos que se extienden
hasta más tarde de lo normal.

Hoy esas desviaciones no se pueden representar. Las opciones son mentir —dejar el
horario habitual y que alguien se presente a una cancha cerrada— o romper la
configuración permanente para tapar un día, y después acordarse de restaurarla.
Ninguna de las dos sirve.

Esta feature agrega **dos capas encima del horario habitual**: una que lo reemplaza
para una fecha concreta, y otra que resta con un motivo registrado. Y define el
orden en que se resuelven, que es lo único difícil acá.

## Fuera de alcance

- **Todo lo de `canchas-y-horario`.** El alta de canchas, el horario habitual, la
  consulta y sus límites de rango ya están especificados y aprobados ahí.
- **Reservar.** Ocupar una franja, anti-doble-booking.
- **Precios y pagos.**
- **Autenticación, usuarios y roles.**
- **Feriados automáticos.** No hay calendario de feriados nacional: cada cierre se
  registra a mano. Si duele, entra por `changes/`.
- **Cierres que aplican a todo el club de una vez.** Un feriado se registra cancha
  por cancha. Es una limitación consciente — ver `design.md`.
- **Interfaz visual.**

## El modelo de tres capas

Con esta feature, la disponibilidad de una fecha se resuelve así:

| Capa | Qué representa | De qué feature |
|---|---|---|
| **Horario habitual** | el horario de la cancha, por día de la semana | `canchas-y-horario` |
| **Disponibilidad especial** | una fecha que abre distinto de lo habitual | esta |
| **Excepción** | un tramo cerrado, con motivo | esta |

```
base   = disponibilidad especial de esa fecha, si existe
         horario habitual del día de la semana, si no
result = base − excepciones de esa fecha
```

El requisito `R16` de `canchas-y-horario` **no cambia de enunciado**: sigue diciendo
que la consulta devuelve las franjas disponibles. Lo que cambia es cómo se calcula
«disponible».

> Cuidado al editar: un ID al principio de línea es una **declaración** de requisito
> para `verify.sh`. Para mencionar uno ajeno, escribilo entre backticks y nunca al
> comienzo del renglón.

## Requisitos

Notación EARS. **Los IDs son únicos en todo el proyecto y no se reutilizan** — los
que faltan en la numeración están en
[`canchas-y-horario`](../canchas-y-horario/requirements.md).

### Disponibilidad especial — cuando una fecha es distinta

R23 El sistema deberá permitir definir, para una cancha y una fecha concreta, las
franjas horarias que reemplazan al horario habitual de esa fecha.

R24 Si una franja de disponibilidad especial tiene una hora de fin anterior o igual
a su hora de inicio, entonces el sistema deberá rechazarla e informar el motivo.

R25 Si una franja de disponibilidad especial se solapa con otra ya definida para la
misma cancha y la misma fecha, entonces el sistema deberá rechazarla e informar con
cuál se solapa.

R26 El sistema deberá permitir eliminar la disponibilidad especial de una fecha, de
modo que esa fecha vuelva a regirse por el horario habitual.

### Excepciones — lo que se cierra, con motivo

R12 El sistema deberá permitir registrar una excepción de cierre para una cancha en
una fecha concreta.

R14 El sistema deberá permitir registrar el motivo de una excepción de cierre.

R15 El sistema deberá permitir eliminar una excepción de cierre ya registrada, de
modo que el tramo vuelva a estar disponible.

R13 Cuando se consulta la disponibilidad de una fecha que tiene una excepción de
cierre, el sistema deberá excluir de la respuesta el tramo cubierto por la
excepción.

### Orden de resolución

R27 El sistema deberá resolver la disponibilidad de una fecha tomando como base la
disponibilidad especial de esa fecha si existe, o el horario habitual del día de la
semana si no, y restándole después las excepciones de esa fecha.

## Criterios de aceptación

### Disponibilidad especial

- **R23.a** — una fecha con disponibilidad especial **ignora por completo** el
  horario habitual de ese día: no lo suma ni lo intersecta.
- **R23.b** — disponibilidad especial que abre **más** que lo habitual (un torneo
  hasta las 23:30 cuando el sábado cierra 22:00): se acepta y se devuelve. **Este
  es el caso que justifica que esta capa exista y no alcance con las excepciones.**
- **R23.c** — disponibilidad especial vacía para una fecha: la cancha queda cerrada
  ese día, y eso es distinto de no tener disponibilidad especial.
- **R23.d** — la disponibilidad especial de una fecha no afecta a ninguna otra
  fecha, ni al horario habitual.
- **R25.a** — solapamiento parcial, contención e idéntica: los tres se rechazan.
- **R25.b** — la misma franja en dos fechas distintas no es solapamiento.
- **R26.a** — al eliminar la disponibilidad especial, la fecha vuelve a devolver
  exactamente lo que dicta el horario habitual.

### Excepciones

- **R12.a** — excepción sobre una fecha en la que la cancha ya está cerrada: se
  acepta y no cambia nada observable.
- **R12.b** — dos excepciones **pueden solaparse** entre sí. A diferencia de las
  otras dos capas, acá el solapamiento no se rechaza.
- **R13.a** — excepción parcial (mantenimiento 18:00–20:00) **parte** la franja
  disponible en dos (08:00–18:00 y 20:00–23:00), no la elimina entera.
- **R13.b** — dos excepciones solapadas en la misma fecha cierran la **unión** de
  las dos, sin contar el solapamiento dos veces.
- **R13.c** — excepción que cubre la franja completa: la fecha queda sin
  disponibilidad.
- **R13.d** — excepción cuyo tramo cae fuera de toda franja disponible: no cambia
  nada y no falla.
- **R14.a** — motivo vacío o solo espacios: se rechaza. Una excepción sin motivo es
  exactamente lo que esta capa vino a evitar.
- **R15.a** — al eliminar la excepción, el tramo vuelve a estar disponible.

### Orden de resolución

- **R27.a** — fecha con disponibilidad especial **y** excepción: la excepción resta
  de la disponibilidad especial, no del horario habitual. **Es el caso que
  distingue un orden de resolución correcto de uno invertido, y el riesgo principal
  de la feature.**
- **R27.b** — fecha sin especial y sin excepción: devuelve el horario habitual tal
  cual, idéntico a lo que devolvía antes de esta feature. Es el test de no
  regresión sobre `canchas-y-horario`.
- **R27.c** — excepción sobre un día que el horario habitual tiene cerrado:
  devuelve vacío, no error.
- **R27.d** — una cancha inactiva sigue excluida de la consulta aunque tenga
  disponibilidad especial (R6 de `canchas-y-horario`), y la conserva al reactivarla.

## Ambigüedades pendientes

Ninguna. Las que aplicaban a esta mitad se resolvieron el 2026-08-13:

| # | Resolución |
|---|---|
| A1 | Tres capas: horario habitual permanente + disponibilidad especial por fecha + excepciones que restan, con el orden de R27 |
| A3 | Excepciones parciales soportadas (R13, R13.a) |

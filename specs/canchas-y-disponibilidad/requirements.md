# Requisitos — Definir canchas y su disponibilidad horaria

- **Slug:** `canchas-y-disponibilidad`
- **Estado:** spec_draft
- **Fecha:** 2026-08-13

## Problema

El club no tiene forma de registrar qué canchas tiene ni cuándo cada una está
disponible. Hoy eso vive en la cabeza de quien atiende y en un cuaderno: no se
puede consultar desde ningún lado, no se puede mostrar a un cliente, y cada
cambio de horario (una cancha en mantenimiento, un feriado, un torneo que se
extiende) se comunica de boca en boca y se pierde.

Esta feature es el cimiento de todo el resto del sistema. Una reserva es una
franja de disponibilidad ocupada; sin disponibilidad definida no hay nada que
reservar. Sin esto tampoco se puede mostrar una agenda, ni calcular ocupación, ni
saber cuánta capacidad tiene el club.

El resultado esperado es que alguien del club **configure cada cancha una sola
vez** —su horario habitual, que no vence ni hay que renovar— y después solo
registre las desviaciones: un día que abre distinto, un feriado, un mantenimiento.

## Fuera de alcance

Explícitamente **no** hace esta feature:

- **Reservar.** Ocupar una franja, anti-doble-booking, concurrencia, estados de
  reserva. Es la feature siguiente y tiene sus propias invariantes.
- **Precios y pagos.** Ni tarifa por franja, ni horario pico, ni cobro.
- **Autenticación, usuarios y roles.** Ver el riesgo asociado en `design.md`: el
  servicio no se publica hasta que exista la feature de autenticación.
- **Multi-club / multi-tenancy.** Esta aplicación es de **un solo club**
  (decisión explícita del 2026-08-13). No hay entidad "club" ni `club_id`.
- **Agenda por temporada.** El cambio de horario de verano se hace editando el
  horario semanal.
- **Notificaciones**, sincronización con Google Calendar, reportes de ocupación.
- **Gestión de clientes** del club.
- **Interfaz visual.** Esta spec define comportamiento. Las pantallas se
  especifican por separado, sobre este modelo ya cerrado.

## Modelo de disponibilidad — las tres capas

Contexto necesario para leer los requisitos. La decisión y sus alternativas
descartadas están en `design.md`.

| Capa | Qué representa | Vence |
|---|---|---|
| **Horario semanal** | el horario habitual de la cancha, por día de la semana | **no** |
| **Disponibilidad especial** | una fecha concreta que abre distinto de lo habitual | por fecha |
| **Excepción** | un tramo cerrado, con motivo | por fecha |

Orden de resolución para una fecha dada:

```
base   = disponibilidad especial de esa fecha, si existe
         horario semanal del día de la semana, si no
result = base − excepciones de esa fecha
```

## Requisitos

Notación EARS. Un requisito, una obligación. IDs permanentes: no se reutilizan.

### Canchas

R1  El sistema deberá permitir registrar una cancha con un nombre y un deporte.

R2  Si se intenta registrar una cancha con un nombre que ya está en uso, entonces
el sistema deberá rechazar la operación e informar el conflicto, sin registrar la
cancha.

R3  El sistema deberá permitir modificar los atributos de una cancha ya
registrada.

R4  El sistema deberá permitir listar todas las canchas registradas, incluyendo
las inactivas.

R5  El sistema deberá permitir desactivar una cancha sin eliminar su registro ni
su configuración horaria.

R6  Mientras una cancha está inactiva, el sistema deberá excluirla de los
resultados de las consultas de disponibilidad.

R20 El sistema deberá permitir registrar, para cada cancha, su superficie, si es
techada y si tiene iluminación.

R21 El sistema deberá permitir definir una duración de turno por cancha,
independiente de la de las demás canchas.

### Horario semanal — la configuración permanente

R7  El sistema deberá permitir definir, para cada cancha y cada día de la semana,
las franjas horarias en las que la cancha abre habitualmente.

R8  El sistema deberá permitir definir más de una franja horaria para el mismo
día de la semana en la misma cancha, siempre que no se solapen entre sí.

R9  Si una franja horaria tiene una hora de fin anterior o igual a su hora de
inicio, entonces el sistema deberá rechazarla e informar el motivo.

R10 Si una franja horaria se solapa con otra ya definida para la misma cancha y
el mismo día de la semana, entonces el sistema deberá rechazarla e informar con
cuál se solapa.

R11 Mientras una cancha no tiene ninguna franja definida para un día de la
semana, el sistema deberá considerarla cerrada ese día.

R22 El sistema deberá aplicar el horario semanal de una cancha a cualquier fecha
futura consultada, sin vencimiento y sin requerir ninguna reconfiguración
periódica.

### Disponibilidad especial — cuando una fecha es distinta

R23 El sistema deberá permitir definir, para una cancha y una fecha concreta, las
franjas horarias que reemplazan al horario semanal de esa fecha.

R24 Si una franja de disponibilidad especial tiene una hora de fin anterior o
igual a su hora de inicio, entonces el sistema deberá rechazarla e informar el
motivo.

R25 Si una franja de disponibilidad especial se solapa con otra ya definida para
la misma cancha y la misma fecha, entonces el sistema deberá rechazarla e
informar con cuál se solapa.

R26 El sistema deberá permitir eliminar la disponibilidad especial de una fecha,
de modo que esa fecha vuelva a regirse por el horario semanal.

### Excepciones — lo que se cierra, con motivo

R12 El sistema deberá permitir registrar una excepción de cierre para una cancha
en una fecha concreta.

R14 El sistema deberá permitir registrar el motivo de una excepción de cierre.

R15 El sistema deberá permitir eliminar una excepción de cierre ya registrada, de
modo que el tramo vuelva a estar disponible.

R13 Cuando se consulta la disponibilidad de una fecha que tiene una excepción de
cierre, el sistema deberá excluir de la respuesta el tramo cubierto por la
excepción.

### Consulta de disponibilidad

R27 El sistema deberá resolver la disponibilidad de una fecha tomando como base
la disponibilidad especial de esa fecha si existe, o el horario semanal del día de
la semana si no, y restándole después las excepciones de esa fecha.

R16 Cuando se consulta la disponibilidad de una cancha para un rango de fechas,
el sistema deberá devolver, para cada fecha del rango, las franjas disponibles
resultantes de aplicar R27.

R17 Si se consulta la disponibilidad de una cancha que no existe, entonces el
sistema deberá responder con un error de recurso no encontrado.

R18 Si el rango de fechas consultado tiene una fecha de fin anterior a su fecha
de inicio, entonces el sistema deberá rechazar la consulta e informar el motivo.

R28 Si el rango de fechas consultado abarca más de 92 días, entonces el sistema
deberá rechazar la consulta e informar el límite.

R19 El sistema deberá interpretar y devolver todos los horarios en la zona
horaria del club, con independencia de la zona horaria de quien consulta.

## Criterios de aceptación

Casos de borde que hay que probar y que no son requisitos nuevos.

### Canchas

- **R1.a** — nombre vacío o solo espacios: se rechaza.
- **R1.b** — deporte fuera del conjunto reconocido (pádel, tenis, fútbol 5,
  fútbol 7): se rechaza.
- **R2.a** — el conflicto de nombre es insensible a mayúsculas y a espacios al
  borde: «Cancha 1» y «cancha 1 » colisionan.
- **R2.b** — una cancha inactiva sigue ocupando su nombre.
- **R4.a** — sin canchas registradas: devuelve lista vacía, no error.
- **R5.a** — desactivar una cancha ya inactiva es idempotente: no falla.
- **R6.a** — una cancha inactiva conserva su horario y su disponibilidad
  especial, y ambos reaparecen al reactivarla.
- **R21.a** — duración de turno cero o negativa: se rechaza.
- **R21.b** — dos canchas con duraciones distintas (90 y 60) conviven sin
  interferirse.

### Horario semanal

- **R8.a** — dos franjas que se tocan en el borde (12:00–14:00 y 14:00–18:00)
  **no** se consideran solapadas y se aceptan.
- **R9.a** — franja de duración cero (10:00–10:00): se rechaza.
- **R10.a** — solapamiento parcial, contención total e idéntica: los tres se
  rechazan.
- **R10.b** — la misma franja en dos canchas distintas no es solapamiento.
- **R10.c** — la misma franja en dos días de la semana distintos no es
  solapamiento.
- **R22.a** — consultar una fecha a cinco años vista devuelve el horario semanal
  aplicado, sin haber hecho ninguna carga adicional. **Este es el criterio que
  distingue «configurado una vez» de «cargado hasta una fecha».**

### Disponibilidad especial

- **R23.a** — una fecha con disponibilidad especial **ignora por completo** el
  horario semanal de ese día, no lo suma ni lo intersecta.
- **R23.b** — disponibilidad especial que abre **más** que lo habitual (torneo
  hasta las 02:00): se acepta y se devuelve.
- **R23.c** — disponibilidad especial vacía para una fecha: la cancha queda
  cerrada ese día, distinto de no tener disponibilidad especial.
- **R26.a** — al eliminar la disponibilidad especial, la fecha vuelve a devolver
  exactamente lo que dicta el horario semanal.

### Excepciones

- **R12.a** — excepción sobre una fecha en la que la cancha ya está cerrada: se
  acepta y no cambia nada observable.
- **R13.a** — excepción parcial (mantenimiento 14:00–16:00) parte la franja
  disponible en dos (08:00–14:00 y 16:00–22:00), no la elimina entera.
- **R13.b** — dos excepciones que se solapan en la misma fecha: el tramo cerrado
  es la unión de las dos, no se cuenta doble.
- **R13.c** — excepción que cubre la franja completa: la fecha queda sin
  disponibilidad.
- **R13.d** — excepción cuyo tramo cae fuera de toda franja disponible: no
  cambia nada y no falla.
- **R15.a** — al eliminar la excepción, el tramo vuelve a estar disponible.

### Orden de resolución

- **R27.a** — fecha con disponibilidad especial **y** excepción: la excepción
  resta de la disponibilidad especial, no del horario semanal. Es el caso que
  distingue un orden de resolución correcto de uno invertido.
- **R27.b** — fecha sin especial y sin excepción: devuelve el horario semanal
  tal cual.
- **R27.c** — fecha con excepción sobre un día que el horario semanal tiene
  cerrado: devuelve vacío, no error.

### Consulta

- **R16.a** — rango de un solo día.
- **R16.b** — rango que cruza el cambio de horario de verano, si la zona horaria
  del club lo tiene.
- **R16.c** — rango de exactamente 92 días: se acepta. De 93: se rechaza (R28).
- **R16.d** — fecha del rango sin ninguna disponibilidad: aparece en la respuesta
  con lista vacía, no se omite.
- **R19.a** — el resultado es idéntico consultando desde cualquier zona horaria.

## Ambigüedades pendientes

Ninguna. Las siete que había se resolvieron el 2026-08-13:

| # | Resolución |
|---|---|
| A1 | Tres capas: horario semanal permanente + disponibilidad especial por fecha + excepciones que restan |
| A2 | Atributos: nombre, deporte, superficie, techada, iluminación, duración de turno (R1, R20, R21) |
| A3 | Excepciones parciales soportadas (R13, R13.a) |
| A4 | Duración de turno por cancha (R21) |
| A5 | Sin agenda por temporada: se edita el horario semanal |
| A6 | Sin autenticación, y el servicio no se publica hasta que exista esa feature |
| A7 | Rango máximo de consulta: 92 días (R28) |

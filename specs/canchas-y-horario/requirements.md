# Requisitos — Canchas y su horario habitual

- **Slug:** `canchas-y-horario`
- **Estado:** spec_approved
- **Fecha:** 2026-08-13
- **Origen:** mitad de `canchas-y-disponibilidad`, dividida el 2026-08-13. La otra
  mitad es [`fechas-especiales-y-cierres`](../fechas-especiales-y-cierres/requirements.md).

## Problema

El club no tiene forma de registrar qué canchas tiene ni cuándo abre cada una. Hoy
eso vive en la cabeza de quien atiende y en un cuaderno: no se puede consultar
desde ningún lado, no se puede mostrar a un cliente, y cada cambio se comunica de
boca en boca y se pierde.

Esta feature es el cimiento del sistema y **la rebanada más chica que ya sirve para
algo**: dar de alta las canchas, configurar el horario habitual de cada una una
sola vez, y consultar la disponibilidad que resulta. Con esto un cliente ya puede
saber si hay cancha el jueves a las 20.

El club es de pádel y tiene seis canchas, pero **la cantidad no es fija**: tiene
que poder crear canchas nuevas y configurarlas cuando quiera. Configurar N canchas
desde cero es trabajo manual proporcional a N, y seis canchas de pádel tienen seis
horarios casi idénticos — de ahí R29.

## Fuera de alcance

- **Fechas que no siguen el horario habitual.** Un feriado, un mantenimiento, un
  torneo que se extiende. Es la feature siguiente
  ([`fechas-especiales-y-cierres`](../fechas-especiales-y-cierres/requirements.md)),
  y hasta que exista, la disponibilidad es exactamente el horario semanal.
- **Reservar.** Ocupar una franja, anti-doble-booking, concurrencia.
- **Precios y pagos.**
- **Autenticación, usuarios y roles.** Ver el riesgo en `design.md`: el servicio no
  se publica hasta que exista esa feature.
- **Multi-club.** Esta aplicación es de un solo club. No hay entidad «club».
- **Interfaz visual.** Esta spec define comportamiento.
- **Franjas que cruzan la medianoche.** Un horario de 22:00 a 02:00 se carga como
  dos franjas en dos días. Limitación asumida, documentada en `design.md`.

## Requisitos

Notación EARS. Un requisito, una obligación. **Los IDs son únicos en todo el
proyecto y no se reutilizan** — los que faltan en la numeración están en
`fechas-especiales-y-cierres`.

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

### Horario habitual

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

R22 El sistema deberá aplicar el horario habitual de una cancha a cualquier fecha
futura consultada, sin vencimiento y sin requerir ninguna reconfiguración
periódica.

R29 El sistema deberá permitir copiar el horario habitual completo de una cancha a
una o más canchas.

### Consulta de disponibilidad

R16 Cuando se consulta la disponibilidad de una cancha para un rango de fechas, el
sistema deberá devolver, para cada fecha del rango, las franjas horarias en las que
la cancha está disponible.

> Mientras esta sea la única feature implementada, «disponible» equivale al horario
> habitual del día de la semana correspondiente.
> [`fechas-especiales-y-cierres`](../fechas-especiales-y-cierres/requirements.md)
> agrega capas que lo modifican, sin cambiar el enunciado de R16.

R17 Si se consulta la disponibilidad de una cancha que no existe, entonces el
sistema deberá responder con un error de recurso no encontrado.

R18 Si el rango de fechas consultado tiene una fecha de fin anterior a su fecha de
inicio, entonces el sistema deberá rechazar la consulta e informar el motivo.

R28 Si el rango de fechas consultado abarca más de 92 días, entonces el sistema
deberá rechazar la consulta e informar el límite.

R30 Cuando se consulta la disponibilidad sin indicar una cancha, el sistema deberá
devolver la disponibilidad de todas las canchas activas para el rango pedido.

R31 Si una consulta de disponibilidad de todas las canchas abarca más de 31 días,
entonces el sistema deberá rechazarla e informar el límite.

R19 El sistema deberá interpretar y devolver todos los horarios en la zona horaria
del club, con independencia de la zona horaria de quien consulta.

## Criterios de aceptación

### Canchas

- **R1.a** — nombre vacío o solo espacios: se rechaza.
- **R1.b** — deporte fuera del conjunto reconocido: se rechaza.
- **R2.a** — la colisión de nombre es insensible a mayúsculas y a espacios al
  borde: «Cancha 1» y «cancha 1 » colisionan.
- **R2.b** — una cancha inactiva sigue ocupando su nombre.
- **R4.a** — sin canchas registradas: devuelve lista vacía, no error.
- **R5.a** — desactivar una cancha ya inactiva es idempotente: no falla.
- **R6.a** — una cancha inactiva conserva su horario habitual, y reaparece con él
  al reactivarla.
- **R21.a** — duración de turno cero o negativa: se rechaza.
- **R21.b** — dos canchas con duraciones distintas (90 y 60) conviven sin
  interferirse.

### Horario habitual

- **R8.a** — dos franjas que se tocan en el borde (12:00–14:00 y 14:00–18:00)
  **no** se consideran solapadas y se aceptan.
- **R9.a** — franja de duración cero (10:00–10:00): se rechaza.
- **R10.a** — solapamiento parcial, contención total e idéntica: los tres se
  rechazan.
- **R10.b** — la misma franja en dos canchas distintas no es solapamiento.
- **R10.c** — la misma franja en dos días de la semana distintos no es
  solapamiento.
- **R22.a** — consultar una fecha a cinco años vista devuelve el horario habitual
  aplicado, sin haber hecho ninguna carga adicional. **Este es el criterio que
  distingue «configurado una vez» de «cargado hasta una fecha».**
- **R29.a** — copiar a una cancha que ya tenía horario lo **reemplaza completo**,
  no lo fusiona ni lo suma.
- **R29.b** — copiar una cancha sobre sí misma no falla y no cambia nada.
- **R29.c** — copiar a una cancha inactiva se acepta: el horario queda guardado y
  rige cuando se reactive.
- **R29.d** — copiar a varias canchas a la vez es atómico: si una falla, ninguna
  queda modificada.
- **R29.e** — copiar una cancha inexistente como destino devuelve error de recurso
  no encontrado, y ninguna otra queda modificada.

### Consulta

- **R16.a** — rango de un solo día.
- **R16.b** — rango que cruza el cambio de horario de verano, si la zona horaria
  del club lo tiene.
- **R16.c** — rango de exactamente 92 días se acepta; de 93 se rechaza (R28).
- **R16.d** — una fecha del rango sin disponibilidad aparece en la respuesta con
  lista vacía, no se omite.
- **R19.a** — el resultado es idéntico consultando desde cualquier zona horaria.
- **R30.a** — sin ninguna cancha activa: devuelve lista vacía, no error.
- **R30.b** — una cancha inactiva no aparece en la consulta de todas (R6), aunque
  tenga horario configurado.
- **R30.c** — el resultado por cancha es idéntico al que devuelve la consulta
  individual de esa misma cancha para el mismo rango. Es lo que impide que las dos
  consultas divergan.
- **R31.a** — 31 días se acepta; 32 se rechaza informando el límite.

## Ambigüedades pendientes

Ninguna. Las ocho que hubo se resolvieron el 2026-08-13 y están registradas en el
`history` de la feature original y en
[`fechas-especiales-y-cierres`](../fechas-especiales-y-cierres/requirements.md).

| # | Resolución |
|---|---|
| A2 | Atributos: nombre, deporte, superficie, techada, iluminación, duración de turno (R1, R20, R21) |
| A4 | Duración de turno por cancha (R21) |
| A5 | Sin agenda por temporada: se edita el horario habitual |
| A6 | Sin autenticación, y el servicio no se publica hasta que exista esa feature |
| A7 | Rango máximo: 92 días por cancha (R28), 31 días para todas (R31) |
| A8 | La cantidad de canchas es variable y crece: de ahí R29, R30 y R31 |

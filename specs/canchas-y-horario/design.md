# Diseño — Canchas y su horario habitual

- **Slug:** `canchas-y-horario`
- **Requisitos:** [`requirements.md`](requirements.md)

## Estado de verificación de contratos (C8)

Verificado el 2026-08-13 con `git ls-files` y `ls`: **no existe nada de código en
el repo.** Cero archivos `.ts`, sin `package.json`, sin workspace, sin migraciones,
sin schema. Los archivos versionados son todos del harness.

Por lo tanto **todos los contratos son nuevos** y están marcados 🆕. No hay ningún
✅, porque no hay nada preexistente que verificar. Los ⚠️ marcan lo que hay que
comprobar contra Postgres real antes de darlo por bueno.

## Enfoque

Primer servicio del proyecto. Un módulo NestJS `canchas` sobre PostgreSQL, con dos
tablas: la cancha y su horario habitual.

La pieza central es una **función pura de resolución**, sin base de datos y sin
reloj:

```
resolver(horarioSemanal, rango) → Map<fecha, Franja[]>
```

En esta feature resuelve una sola capa, y **está diseñada para que
`fechas-especiales-y-cierres` la extienda en vez de duplicarla**. Al ser pura se
testea con tablas de casos sin levantar nada.

**Los horarios se guardan como hora de pared, no como instantes.** «La cancha abre
a las 8» no es un momento en el tiempo, es una regla local; convertirlo a UTC lo
rompe en cada cambio de horario de verano. Las fechas van en `date` y las horas en
minutos desde medianoche.

> **Nota para el reviewer:** `docs/conventions.md` dice «timestamps en UTC». Eso
> aplica a *instantes* (`created_at`, `updated_at`), y se respeta. Una ventana de
> disponibilidad no es un instante. No es una violación de la convención.

## Alternativas descartadas

### A — Slots fijos materializados

Generar y persistir cada turno individual: `(cancha, fecha, 09:30, 11:00, estado)`.
Consultar sería un `SELECT` trivial y, cuando entren reservas, reservar sería
marcar una fila.

**Descartada** porque conflaciona dos cosas con ciclos de vida distintos en la
misma fila: «el club abre a esta hora» (lo decide el club una vez) y «alguien lo
tomó» (cambia todo el día). De ahí salen los bugs de «edité el horario y se
borraron las reservas». Además obliga a un job que genere turnos hacia adelante
para siempre.

### C — Rangos libres por fecha, sin recurrencia

Guardar solo `disponibilidad(cancha, fecha, desde, hasta)`.

**Descartada** por R22: la cancha se configura una vez y queda, sin vencimiento.
Toda carga masiva tiene fecha de fin — cargás dos años y en dos años hay que volver
a cargar. Lo que sí se conservó de este modelo es la libertad por fecha, que
sobrevive como la capa de disponibilidad especial de la feature siguiente.

### Guardar las horas como `time` en lugar de minutos

Más legible al mirar la tabla en crudo.

**Descartada** porque la constraint de exclusión que enforcea el no-solapamiento en
la base necesita un tipo de rango, y `int4range` es built-in y funciona con `gist`
sin ceremonia, mientras que un rango de `time` requiere crear un tipo propio o una
expresión inmutable poco legible. Se prioriza la constraint en la base — que no se
puede evadir — sobre la legibilidad de una fila cruda, y se compensa con una vista
que muestre `HH:MM`.

### `PUT` por cancha destino en lugar de un `POST` de copia

**Descartada** porque copiar a varias canchas tiene que ser atómico (R29.d). Con un
`PUT` por destino, un fallo a mitad deja unas canchas con el horario nuevo y otras
con el viejo, y nadie sabe cuáles.

## Contratos

### Datos 🆕

Extensión requerida: `btree_gist` (necesaria para combinar `=` con `&&` en un
`EXCLUDE`).

```sql
cancha
  id                 uuid pk
  nombre             text not null
  nombre_norm        text not null           -- lower(trim(nombre)), generado
  deporte            text not null           -- enum: padel|tenis|futbol5|futbol7
  superficie         text null
  techada            boolean not null default false
  iluminacion        boolean not null default false
  duracion_turno_min int not null
  activa             boolean not null default true
  created_at         timestamptz not null default now()
  updated_at         timestamptz not null

  UNIQUE (nombre_norm)                        -- R2, R2.a
  CHECK  (duracion_turno_min > 0)             -- R21.a

horario_cancha                                -- permanente, no vence (R22)
  id          uuid pk
  cancha_id   uuid fk → cancha on delete cascade
  dia_semana  smallint not null               -- 1=lunes … 7=domingo (ISO-8601)
  franja      int4range not null              -- minutos desde medianoche, [desde,hasta)

  CHECK  (dia_semana between 1 and 7)
  CHECK  (lower(franja) >= 0 and upper(franja) <= 1440 and not isempty(franja))  -- R9
  EXCLUDE USING gist (cancha_id WITH =, dia_semana WITH =, franja WITH &&)       -- R10
```

**Rangos semiabiertos `[desde, hasta)`.** Es lo que hace que 12:00–14:00 y
14:00–18:00 no se consideren solapadas (R8.a) sin ninguna lógica especial: `&&`
sobre `int4range` semiabierto ya da falso.

⚠️ **A verificar antes de dar el diseño por bueno:** que `EXCLUDE USING gist` con
`int4range` y `btree_gist` funcione tal como está escrito, y que el `CHECK` sobre
`lower()`/`upper()`/`isempty()` sea aceptado. Es estándar de Postgres, pero no lo
corrí. Es la primera tarea de `tasks.md`.

### API 🆕

```
POST   /canchas                                  R1, R20, R21
GET    /canchas                                  R4
GET    /canchas/:id
PATCH  /canchas/:id                              R3
POST   /canchas/:id/desactivar                   R5

PUT    /canchas/:id/horario                      R7, R8  (reemplaza la semana completa)
GET    /canchas/:id/horario
POST   /canchas/:id/horario/copiar               R29     { "aCanchas": ["uuid", …] }

GET    /canchas/:id/disponibilidad?desde=&hasta= R16, R17, R18, R19, R28
GET    /disponibilidad?desde=&hasta=             R30, R31  (todas las activas)
```

`PUT` y no `POST` para el horario: reemplaza el conjunto completo de franjas de la
semana. Evita el estado intermedio inconsistente de agregar franjas de a una y que
una validación de solapamiento deje la mitad cargada.

**`/disponibilidad` sin id existe porque la cantidad de canchas es variable.** Con
seis canchas, N llamadas es seis veces la latencia y seis veces la chance de una
respuesta parcial e inconsistente. La consulta individual se conserva porque admite
el rango largo (92 días contra 31).

Las dos consultas comparten la misma `resolver()`, y **R30.c exige que devuelvan lo
mismo para la misma cancha y el mismo rango**. Es lo que impide que se vayan
separando — el modo de falla clásico de tener dos caminos para el mismo cálculo.

Horas en la API como `"HH:MM"`. El `int4range` es representación interna.

Respuesta de disponibilidad:

```json
{
  "canchaId": "…",
  "zonaHoraria": "America/Argentina/Buenos_Aires",
  "dias": [
    { "fecha": "2026-09-16", "franjas": [ { "desde": "08:00", "hasta": "23:00" } ] },
    { "fecha": "2026-09-17", "franjas": [] }
  ]
}
```

Toda fecha del rango aparece, incluso sin franjas (R16.d). Que una fecha esté
ausente y que esté cerrada son cosas distintas.

### Errores 🆕

| Situación | HTTP | Requisito |
|---|---|---|
| Nombre de cancha en uso | 409 | R2 |
| Franja inválida (fin ≤ inicio) | 422 | R9 |
| Franja solapada | 409 | R10 |
| Cancha inexistente | 404 | R17 |
| Cancha destino de una copia inexistente | 404 | R29.e |
| Rango invertido | 422 | R18 |
| Rango > 92 días (una cancha) | 422 | R28 |
| Rango > 31 días (todas) | 422 | R31 |
| Deporte no reconocido | 422 | R1.b |
| Duración de turno ≤ 0 | 422 | R21.a |

Excepciones de dominio propias en el servicio, mapeadas a HTTP en un filtro. El
servicio no conoce códigos de estado (`docs/conventions.md`).

### Configuración 🆕

```
DATABASE_URL          conexión a Postgres
CLUB_TIMEZONE         IANA, default America/Argentina/Buenos_Aires
CLUB_NOMBRE           para mostrar
MAX_RANGO_DIAS        default 92 (R28)
MAX_RANGO_DIAS_TODAS  default 31 (R31)
```

Sin valores reales en el repo: solo `.env.example` con las claves (C9).

## Impacto

- **Migraciones:** primera del proyecto. Crea `btree_gist`, `cancha`,
  `horario_cancha` y sus constraints. Reversible.
- **Breaking changes:** ninguno posible, no hay nada desplegado.
- **Comportamiento visible:** primer servicio del proyecto. Un operador configura
  sus canchas y cualquiera consulta disponibilidad. Sin interfaz visual y sin
  reservas.
- **Módulos que se tocan:** todos nuevos. Se crea el andamiaje del monorepo
  (`apps/api`, `packages/shared`) por primera vez, según
  [ADR-0002](../../docs/adr/0002-layout-monorepo.md).
- **Deuda que deja:** `resolver()` con una sola capa. La feature siguiente la
  extiende; si en vez de eso la duplica, es un rechazo de review.

## Riesgos

| Riesgo | Detección | Mitigación |
|---|---|---|
| La constraint `EXCLUDE`/`CHECK` no funciona como está escrita | **T1**: probarla contra Postgres real antes de construir encima | Fallback: enforcement en aplicación + índice parcial. Se documenta el downgrade si pasa |
| **El servicio queda expuesto sin autenticación** | Ninguna automática hoy — es el riesgo más serio | El servicio **falla al arrancar** si `NODE_ENV=production` y no hay auth configurada (C11: fallar ruidoso). No se publica hasta la feature de auth |
| Las dos consultas de disponibilidad se separan y devuelven resultados distintos | Test **R30.c**: el resultado por cancha tiene que ser idéntico al de la consulta individual | Una sola `resolver()` compartida. Una segunda implementación es un rechazo de review |
| Copiar horario pisa sin aviso el de la cancha destino | Test **R29.a**: reemplaza, no fusiona — está especificado, no es accidente | Es responsabilidad de la interfaz confirmar antes de pisar. Anotado para la spec de UI |
| Franja que cruza medianoche (22:00–02:00) no es representable con minutos 0–1440 | Test explícito: se rechaza con error claro | **Limitación asumida**: una franja no cruza el día. Un horario nocturno se carga como dos franjas en dos días. Si duele, entra por `changes/` |
| `resolver()` se escribe de forma que no admite extenderse, y la feature siguiente la duplica | Review de `fechas-especiales-y-cierres` | Firma y estructura pensadas para recibir capas adicionales desde el arranque |
| Sin multi-tenancy: si mañana hay un segundo club hay que migrar todas las tablas y queries | No detectable por test; es una decisión tomada | Ninguna. **Deuda asumida explícitamente** el 2026-08-13 por decisión del owner, con el costo advertido |

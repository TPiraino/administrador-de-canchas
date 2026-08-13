# Diseño — Definir canchas y su disponibilidad horaria

- **Slug:** `canchas-y-disponibilidad`
- **Requisitos:** [`requirements.md`](requirements.md)

## Estado de verificación de contratos (C8)

Verificado el 2026-08-13 con `git ls-files` y `ls`: **no existe nada de código en
el repo.** Cero archivos `.ts`, sin `package.json`, sin workspace, sin migraciones,
sin schema. Los 45 archivos versionados son todos del harness.

Por lo tanto **todos los contratos de este documento son nuevos** y están marcados
🆕. No hay ningún ✅, porque no hay nada preexistente que verificar. Los ⚠️ marcan
lo que hay que comprobar contra Postgres real antes de darlo por bueno.

## Enfoque

Primer servicio del proyecto. Dos módulos NestJS sobre una base PostgreSQL:
`CanchasModule` (el CRUD de la cancha y sus atributos) y `DisponibilidadModule`
(las tres capas y la resolución).

La pieza central es una **función pura de resolución**, sin base de datos y sin
reloj:

```
resolver(horarioSemanal, especiales, excepciones, rango) → Map<fecha, Franja[]>
```

Todo lo difícil de esta feature está ahí —la precedencia de las tres capas, la
resta de excepciones, el partido de una franja en dos— y al ser pura se puede
testear con tablas de casos, sin levantar nada. El servicio que la rodea solo trae
filas de la base, llama a la función y serializa.

**Los horarios se guardan como hora de pared, no como instantes.** "La cancha abre
a las 8" no es un momento en el tiempo, es una regla local; convertirlo a UTC lo
rompe en cada cambio de horario de verano. Las fechas van en `date` y las horas en
minutos-desde-medianoche. La zona horaria del club es una constante de
configuración y solo se usará para convertir a instantes cuando existan reservas.

> **Nota para el reviewer:** `docs/conventions.md` dice "timestamps en UTC". Eso
> aplica a *instantes* (`created_at`, `updated_at`), y se respeta. Una ventana de
> disponibilidad no es un instante. No es una violación de la convención.

## Alternativas descartadas

### A — Slots fijos materializados

Generar y persistir cada turno individual: `(cancha, fecha, 09:30, 11:00, estado)`.
Consultar sería un `SELECT` trivial y, cuando entren reservas, reservar sería
marcar una fila, con el anti-doble-booking saliendo gratis de un `UNIQUE`.

**Descartada** porque conflaciona dos cosas con ciclos de vida distintos en la
misma fila: "el club abre a esta hora" (lo decide el club una vez) y "alguien lo
tomó" (cambia todo el día). De ahí salen los bugs de "edité el horario y se
borraron las reservas". Además obliga a un job que genere turnos hacia adelante
para siempre, y a regenerar cada vez que cambia un horario o una duración de turno.

### C puro — Rangos libres por fecha, sin recurrencia

Guardar solo `disponibilidad(cancha, fecha, desde, hasta)`, sin ninguna regla
recurrente. Es el modelo más simple de entender y el que da más libertad por día.

**Descartada** por un requisito explícito: R22 pide que la cancha se configure una
vez y quede, sin vencimiento. Toda carga masiva tiene fecha de fin —cargás dos
años y en dos años hay que volver a cargar— así que C puro no puede cumplir R22.
Lo que sí se conservó de C es la libertad por fecha, que sobrevive como la capa de
disponibilidad especial.

### B puro — Horario semanal + excepciones, sin override por fecha

Solo la regla recurrente y las excepciones que restan. Dos capas en lugar de tres,
con una resolución trivial de una línea.

**Descartada** porque no puede expresar una fecha que abre **más** que lo habitual.
Un torneo que se extiende hasta las 02:00, o un sábado especial de horario
extendido, solo se pueden representar restando — y no hay nada de donde restar por
encima del horario semanal. R23.b es exactamente ese caso.

### Guardar las horas como `time` en lugar de minutos

Más legible al mirar la tabla en crudo.

**Descartada** porque la constraint de exclusión que enforcea el no-solapamiento en
la base necesita un tipo de rango, y `int4range` es built-in y funciona con `gist`
sin ceremonia, mientras que un rango de `time` requiere crear un tipo propio o una
expresión inmutable poco legible. Se prioriza la constraint en la base (que no se
puede evadir) sobre la legibilidad de una fila cruda, y se compensa con una vista
que muestre `HH:MM`.

## Contratos

### Datos 🆕

Extensión requerida: `btree_gist` (necesaria para combinar `=` con `&&` en un
`EXCLUDE`).

```sql
cancha
  id                uuid pk
  nombre            text not null           -- único, normalizado (R2.a)
  nombre_norm       text not null           -- lower(trim(nombre)), generado
  deporte           text not null           -- enum: padel|tenis|futbol5|futbol7
  superficie        text null
  techada           boolean not null default false
  iluminacion       boolean not null default false
  duracion_turno_min int not null            -- > 0 (R21.a)
  activa            boolean not null default true
  created_at        timestamptz not null default now()
  updated_at        timestamptz not null

  UNIQUE (nombre_norm)                       -- R2, R2.a
  CHECK  (duracion_turno_min > 0)            -- R21.a

horario_cancha                               -- capa 1: permanente, no vence (R22)
  id          uuid pk
  cancha_id   uuid fk → cancha on delete cascade
  dia_semana  smallint not null              -- 1=lunes … 7=domingo (ISO-8601)
  franja      int4range not null             -- minutos desde medianoche, [desde,hasta)

  CHECK  (dia_semana between 1 and 7)
  CHECK  (lower(franja) >= 0 and upper(franja) <= 1440 and not isempty(franja))  -- R9
  EXCLUDE USING gist (cancha_id WITH =, dia_semana WITH =, franja WITH &&)       -- R10

disponibilidad_especial                      -- capa 2: reemplaza el horario de esa fecha
  id          uuid pk
  cancha_id   uuid fk → cancha on delete cascade
  fecha       date not null
  franja      int4range not null

  CHECK  (lower(franja) >= 0 and upper(franja) <= 1440 and not isempty(franja))  -- R24
  EXCLUDE USING gist (cancha_id WITH =, fecha WITH =, franja WITH &&)            -- R25

excepcion                                    -- capa 3: resta, con motivo
  id          uuid pk
  cancha_id   uuid fk → cancha on delete cascade
  fecha       date not null
  franja      int4range not null
  motivo      text not null                  -- R14
  created_at  timestamptz not null default now()

  CHECK  (lower(franja) >= 0 and upper(franja) <= 1440 and not isempty(franja))
  -- SIN exclude: las excepciones SÍ pueden solaparse entre sí (R13.b),
  --              el resultado es la unión
```

**Rangos semiabiertos `[desde, hasta)`** en las tres capas. Es lo que hace que
12:00–14:00 y 14:00–18:00 no se consideren solapadas (R8.a) sin ninguna lógica
especial: `&&` sobre `int4range` semiabierto ya da falso.

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

PUT    /canchas/:id/especial/:fecha              R23     (reemplaza la fecha completa)
DELETE /canchas/:id/especial/:fecha              R26
GET    /canchas/:id/especial?desde=&hasta=

POST   /canchas/:id/excepciones                  R12, R14
DELETE /canchas/:id/excepciones/:excepcionId     R15
GET    /canchas/:id/excepciones?desde=&hasta=

GET    /canchas/:id/disponibilidad?desde=&hasta= R16, R17, R18, R19, R27, R28
```

`PUT` y no `POST` para horario y especial: reemplazan el conjunto completo de
franjas de esa semana o esa fecha. Evita el estado intermedio inconsistente de ir
agregando franjas de a una y que una validación de solapamiento deje la mitad
cargada.

Horas en la API como `"HH:MM"`, no como minutos. El int4range es representación
interna; nadie de afuera debería tener que saberlo.

Respuesta de disponibilidad:

```json
{
  "canchaId": "…",
  "zonaHoraria": "America/Argentina/Buenos_Aires",
  "dias": [
    { "fecha": "2026-09-20", "franjas": [
        { "desde": "08:00", "hasta": "14:00" },
        { "desde": "16:00", "hasta": "22:00" } ] },
    { "fecha": "2026-09-21", "franjas": [] }
  ]
}
```

Toda fecha del rango aparece, incluso sin franjas (R16.d). Que una fecha esté
ausente y que esté cerrada son cosas distintas, y omitirla obliga al cliente a
reconstruir el calendario.

### Errores 🆕

| Situación | HTTP | Requisito |
|---|---|---|
| Nombre de cancha en uso | 409 | R2 |
| Franja inválida (fin ≤ inicio) | 422 | R9, R24 |
| Franja solapada | 409 | R10, R25 |
| Cancha inexistente | 404 | R17 |
| Rango invertido | 422 | R18 |
| Rango > 92 días | 422 | R28 |
| Deporte no reconocido | 422 | R1.b |

Excepciones de dominio propias en el servicio, mapeadas a HTTP en un filtro. El
servicio no conoce códigos de estado (`docs/conventions.md`).

### Configuración 🆕

```
DATABASE_URL          conexión a Postgres
CLUB_TIMEZONE         IANA, default America/Argentina/Buenos_Aires
CLUB_NOMBRE           para mostrar
MAX_RANGO_DIAS        default 92, configurable (R28)
```

Sin valores reales en el repo: solo `.env.example` con las claves (C9).

## Impacto

- **Migraciones:** es la primera del proyecto. Crea `btree_gist`, las 4 tablas y
  sus constraints. Reversible: el `down` las borra en orden inverso.
- **Breaking changes:** ninguno posible, no hay nada desplegado.
- **Comportamiento visible:** primer servicio del proyecto. Un operador del club
  puede configurar sus canchas y consultar disponibilidad. Todavía sin interfaz
  visual y sin poder reservar.
- **Módulos que se tocan:** todos nuevos. También se crea el andamiaje del
  monorepo (`apps/api`, `packages/shared`) por primera vez, según
  [ADR-0002](../../docs/adr/0002-layout-monorepo.md).
- **Costos / performance:** una consulta de 92 días sobre N canchas resuelve en
  memoria a partir de ~pocas decenas de filas. No hay riesgo de volumen en esta
  escala.

## Riesgos

| Riesgo | Detección | Mitigación |
|---|---|---|
| Orden de resolución invertido: la excepción resta del horario semanal en vez de la disponibilidad especial | Test **R27.a**, que es exactamente ese caso | La función de resolución es pura: se testea con tabla de casos, sin DB |
| La constraint `EXCLUDE`/`CHECK` no funciona como está escrita | Primera tarea de `tasks.md`: probarla contra Postgres real antes de construir encima | Fallback: enforcement en aplicación + índice parcial. Se documenta el downgrade si pasa |
| **El servicio queda expuesto sin autenticación** (A6) | Ninguna automática hoy — es el riesgo más serio de la feature | El servicio **falla al arrancar** si `NODE_ENV=production` y no hay auth configurada (C11: fallar ruidoso). No se publica hasta la feature de auth |
| Excepciones solapadas contadas dos veces al restar | Test **R13.b** | Normalizar a unión de intervalos antes de restar |
| Franja que cruza medianoche (22:00–02:00) no es representable con minutos 0–1440 | Test explícito: se rechaza con error claro | **Limitación asumida**: una franja no cruza el día. Un horario nocturno se carga como dos franjas en dos fechas. Si duele, entra por `changes/` |
| Sin multi-tenancy: si mañana hay un segundo club hay que migrar todas las tablas y todas las queries | No detectable por test; es una decisión tomada | Ninguna. **Deuda asumida explícitamente** el 2026-08-13 por decisión del owner, con el costo advertido. Registrada acá para que quede el rastro |
| Tres capas es más superficie de la que necesitaría un club con horario fijo | Si a la tercera feature nadie usó `disponibilidad_especial`, sobra | Revisitar y colapsar a dos capas por `changes/` |

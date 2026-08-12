# Convenciones

Cómo se escribe código en este repo. A diferencia de la constitución, esto es
negociable: si una convención estorba, se cambia con un commit y una línea de
explicación.

> **Estado:** todavía no hay código. Estas convenciones son el objetivo
> acordado, no una descripción de algo existente. Cuando exista código, la regla
> que gana es **la consistencia con el código de alrededor** — si esta página y
> el repo se contradicen, gana el repo y esta página se corrige.

---

## Stack

Decidido en [ADR-0001](adr/0001-stack.md):

| Capa | Elección |
|---|---|
| Backend | NestJS + TypeScript |
| Frontend | Next.js (App Router) + TypeScript |
| Base de datos | PostgreSQL |
| Orquestación local | Docker Compose |
| Gestor de paquetes | pnpm (workspaces) |

## Estructura

Provisional hasta la primera feature — ver [ADR-0002](adr/0002-layout-monorepo.md).

```
apps/
  api/        NestJS
  web/        Next.js
packages/
  shared/     tipos y contratos compartidos api ↔ web
```

**Límite de módulos:** `web` no importa de `api` ni al revés. Lo que comparten
vive en `packages/shared` y es solo tipos y contratos — sin lógica de negocio,
sin dependencias de runtime.

## Nombres

| Qué | Convención | Ejemplo |
|---|---|---|
| Archivos | kebab-case | `reservas.service.ts` |
| Clases, tipos, interfaces | PascalCase | `ReservasService`, `CrearReservaDto` |
| Variables, funciones | camelCase | `crearReserva` |
| Constantes de módulo | SCREAMING_SNAKE | `MAX_RESERVAS_POR_DIA` |
| Tablas y columnas | snake_case, tabla en plural | `reservas`, `cancha_id` |
| Rutas de API | kebab-case, recurso en plural | `/api/reservas`, `/api/canchas/:id` |
| Slugs de feature | kebab-case | `reserva-de-cancha` |

**Idioma:** el dominio se nombra en español (`Reserva`, `Cancha`, `Club`,
`reservas`), porque es el idioma en el que se piensa el problema y traducirlo
introduce ambigüedad. Todo lo técnico va en inglés (`Service`, `Repository`,
`Controller`, `createdAt`). No se mezcla dentro de un mismo identificador:
`ReservasService`, nunca `ReservaServicio`.

## Backend (NestJS)

- **Un módulo por dominio.** `ReservasModule`, `CanchasModule`, `ClubesModule`.
  Un módulo no importa el servicio de otro directamente: expone lo que ofrece.
- **DTOs con validación en el borde.** Todo input externo se valida con
  `class-validator` antes de tocar lógica. Sin `any` en el borde.
- **Servicios sin HTTP.** El servicio no conoce `Request`, `Response` ni
  códigos de estado. Eso es del controller.
- **Errores tipados.** Excepciones de dominio propias, mapeadas a HTTP en un
  filtro. Nada de `throw new HttpException` desde un servicio.
- **Nada de lógica en el controller.** Valida, delega, mapea la respuesta.

## Frontend (Next.js)

- **Server Components por defecto.** `'use client'` solo cuando hace falta
  estado, efecto o evento — y lo más abajo posible en el árbol.
- **Fetching en el servidor** cuando se puede. Los datos bajan ya resueltos.
- **Sin lógica de negocio duplicada.** Si una regla vive en el backend, el
  frontend no la reimplementa: la consulta. Validación de UX sí puede duplicarse
  (feedback inmediato), pero la decisión la toma el backend.

## Base de datos

- **Migraciones siempre**, nunca sync automático. Cada migración es reversible.
- **Constraints en la base**, no solo en la aplicación. Unicidad, foreign keys y
  checks se declaran donde no se pueden evadir.
- **Sin borrado físico** de entidades con historia (reservas, pagos): baja
  lógica con `deleted_at`.
- **Timestamps en UTC.** La zona horaria se resuelve en presentación. Un horario
  de cancha guardado en hora local es un bug esperando el cambio de horario.

## Tests

- **Los IDs de requisito van en el nombre del test** (C3): `it('R2 — rechaza …')`.
  Es lo que hace posible la trazabilidad automática.
- **Unitarios** para lógica de dominio: sin base de datos, sin red.
- **De integración** para todo lo que cruza un borde: DB, HTTP, cola. Contra una
  Postgres real en Docker, no contra un mock.
- **Mockear solo el borde externo.** Si mockeás justo lo que el requisito pide
  verificar, el test no prueba nada (ver antitests en
  [`verification.md`](verification.md)).
- **Sin datos mock persistentes** (C10). Los fixtures viven en el test y se
  limpian.

## Commits y ramas

**Conventional Commits**, con el slug de la feature como scope:

```
feat(reserva-de-cancha): crear reserva en horario libre (R1)
fix(reserva-de-cancha): conflicto no liberaba el bloqueo (R3)
test(reserva-de-cancha): concurrencia en el mismo horario (R2.b)
docs(harness): enmienda C7 — tercer caso antes de abstraer
chore: actualizar deps
```

- Referenciá el requisito `(R#)` cuando el commit implementa uno. Cierra la
  cadena requisito → test → commit.
- Un propósito por commit (C6). Si el mensaje necesita un "y", son dos commits.
- Ramas: `feat/<slug>`, `fix/<slug>`. Una rama por feature, igual que el
  `in_progress` único del workflow.

## TypeScript

- `strict: true`. No se negocia.
- Sin `any`. Si de verdad no hay tipo, `unknown` y se estrecha.
- `@ts-ignore` / `@ts-expect-error` requieren comentario que explique por qué y
  qué habría que arreglar para sacarlo.
- Sin `export default` salvo donde el framework lo exija (páginas de Next).
  Los nombrados se refactorizan y se buscan mejor.

## Comentarios

Se comenta el **por qué**, nunca el qué. Si hace falta explicar qué hace el
código, el problema es el código.

Excepción legítima: una decisión no obvia que alguien va a querer "simplificar"
en seis meses. Ahí el comentario evita el rollback silencioso de algo
intencional.

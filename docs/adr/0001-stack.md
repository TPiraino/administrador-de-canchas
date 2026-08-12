# ADR-0001 — Stack: NestJS + Next.js + PostgreSQL

- **Estado:** aceptado
- **Fecha:** 2026-08-12

## Contexto

Proyecto personal de gestión de canchas: clubes, canchas, reservas, usuarios con
roles. Un solo desarrollador, trabajando con agentes. Se arrancó de cero, pero
existe una iteración previa del proyecto con este mismo stack, de la que hay
conocimiento acumulado y decisiones ya validadas (auth con JWT/Passport, backend
modular, config por club en `jsonb`).

Restricciones que pesan:

- **Un solo desarrollador.** Cualquier cosa que necesite un equipo para
  sostenerse está descartada.
- **Trabajo con agentes.** El stack tiene que ser uno donde los agentes se
  equivoquen poco: convenciones fuertes, tipado estricto, estructura predecible.
  Un framework sin opinión obliga a que cada decisión chica sea explícita, y ahí
  es donde un agente improvisa.
- **Dominio con invariantes reales.** Una reserva no puede solaparse con otra. Eso
  es una restricción de integridad, no una regla de aplicación.

## Decisión

Backend NestJS + TypeScript, frontend Next.js con App Router + TypeScript, base
PostgreSQL, orquestación local con Docker Compose, pnpm workspaces.

## Alternativas consideradas

### Next.js solo, fullstack (sin backend separado)

Menos piezas, un solo deploy, sin contratos que sincronizar. Atractivo para un
proyecto de una persona.

Descartada porque el dominio tiene lógica que no es de presentación —
disponibilidad, solapamientos, precios, estados de pago— y en un fullstack de
Next esa lógica termina desparramada entre server actions y route handlers sin un
lugar canónico. Con agentes eso es peor que con humanos: sin un lugar obvio, cada
sesión elige uno distinto. NestJS impone el lugar.

### Express o Fastify en vez de NestJS

Más liviano, menos ceremonia, menos magia de decoradores.

Descartada precisamente por eso: la ceremonia de NestJS —módulos, DTOs con
validación declarativa, inyección de dependencias— es estructura que un agente
sigue sin que haya que recordársela. Con Express hay que documentar y enforzar a
mano lo que NestJS da por convención. La ceremonia acá es una feature.

### MySQL o SQLite

Descartadas por las invariantes del dominio. Postgres da constraints de exclusión
(`EXCLUDE USING gist` con rangos de tiempo), que resuelven el solapamiento de
reservas **en la base**, donde no se puede evadir por una race condition. SQLite
además no sirve para el modo de despliegue eventual.

> ⚠️ No verificado todavía: la forma exacta de la constraint de exclusión se
> define en la spec de reservas (C8).

## Consecuencias

### A favor

- Estructura predecible: los agentes aciertan más y hay que corregir menos.
- Tipado end-to-end con contratos compartidos en `packages/shared`.
- Invariantes de integridad en la base, no confiadas a la aplicación.
- Conocimiento acumulado de la iteración previa que se puede reusar.

### En contra

- Dos apps que hay que levantar, buildear y deployar. Más setup, más CI.
- Contratos api ↔ web que se pueden desincronizar. Se mitiga con
  `packages/shared`, pero es trabajo real y recurrente.
- NestJS tiene curva y verbosidad. Para las features más chicas, el boilerplate
  va a pesar más que la lógica.
- Docker Compose local: la iteración previa dejó archivos root-owned que
  rompieron permisos. Hay que resolver ownership desde el arranque, no después.

### Qué la revertiría

- Si a las 10 features el `packages/shared` es una fuente constante de bugs de
  desincronización, el fullstack de Next vuelve a la mesa.
- Si el boilerplate de NestJS resulta ser la mayoría del diff de cada feature.

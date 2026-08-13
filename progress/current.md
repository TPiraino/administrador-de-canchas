# Trabajo en curso

> Este archivo es el **handoff**. Es lo primero que lee un contexto nuevo (agente
> o humano) al arrancar una sesión. Se actualiza al terminar cada sesión de
> trabajo, aunque quede a medias — sobre todo si queda a medias.

## Estado

**Nada en curso.** Dos features aprobadas y esperando que alguien las tome; ninguna
en `in_progress`.

| Feature | Estado | Requisitos | Tareas |
|---|---|---|---|
| `canchas-y-horario` | `spec_approved` | 22 | 28 |
| `fechas-especiales-y-cierres` | `spec_approved` | 9 | 22 |
| `canchas-y-disponibilidad` | `archived` | — | dividida en las dos de arriba |

## Próximo paso

**Tomar `canchas-y-horario` con `/feature-take`.** Es la que no depende de nada y la
que desbloquea todo: incluye el andamiaje del monorepo, la primera migración y la
activación de la capa 2 de `verify.sh`.

`fechas-especiales-y-cierres` **no se puede empezar** hasta que la primera esté
`done`: extiende su `resolver()` y sus tablas.

Dentro de `canchas-y-horario`, la primera tarea es **T1, un spike**: verificar contra
Postgres real que `EXCLUDE USING gist` con `int4range` + `btree_gist` funciona como
dice el diseño. Va primero porque todo el modelo se apoya en eso, y si falla hay que
rediseñar antes de escribir una línea.

## Última sesión

**2026-08-13 — Spec aprobada y dividida en dos**

- Se corrieron los 9 chequeos previos al Gate 1: todos pasan (0 ambigüedades, 42
  criterios de aceptación, 8 alternativas descartadas, sin placeholders).
- **Gate 1 pasado por el owner** sobre las dos mitades. La spec la escribió el
  agente y la aprobó un humano, así que no es autoaprobación — queda registrado en
  el `history` de cada feature.
- La feature original quedó `archived` con una nota que apunta a sus dos mitades. Se
  borró `specs/canchas-y-disponibilidad/` para no tener los mismos requisitos
  definidos en dos lugares (C12); el contenido vive en git y en las hijas.
- Los 31 IDs de requisito **se repartieron sin renumerar**. Cada feature tiene
  huecos en su numeración y eso es correcto.

**Bug del harness encontrado y cerrado.** Dividir la feature destapó que
`verify_traceability` busca los IDs como texto plano, así que dos features con `R3`
se satisfarían con un solo test. Ahora `verify.sh` falla si un ID está declarado en
dos features. El primer caso real apareció al escribir la spec: una línea de prosa
que arrancaba con `R16` quedó leída como declaración.

Y el chequeo nuevo tuvo su propio bug: `awk` con separador `" "` descarta el espacio
inicial, así que el conteo estaba corrido en uno y nunca detectaba nada. Se arregló y
se probó con uno y con dos IDs duplicados.

## Pendientes conocidos

- `.pnpm-store/` en la raíz está root-owned de la iteración previa. Hay que borrarlo
  o cambiarle el owner antes de `pnpm install`, o falla con EACCES. Está anotado en
  T2 de `canchas-y-horario`.
- La interfaz visual **no tiene spec**. Hay mockups aprobados de palabra (tablero de
  4 vistas: día, semana, tabla, gestión) que todavía no entraron al ciclo.
- Las aprobaciones requeridas en GitHub están en **0** porque nadie puede aprobar su
  propia PR. Subir a 1 al sumar el segundo dev — comando en `CONTRIBUTING.md`.
- Resolver la composición entre este harness y el harness global de skills (contras
  de [ADR-0003](../docs/adr/0003-harness-spec-driven.md)).

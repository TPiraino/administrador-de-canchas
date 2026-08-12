# Trabajo en curso

> Este archivo es el **handoff**. Es lo primero que lee un contexto nuevo (agente
> o humano) al arrancar una sesión. Se actualiza al terminar cada sesión de
> trabajo, aunque quede a medias — sobre todo si queda a medias.

## Estado

**Nada en curso.** No hay features en `in_progress`.

## Última sesión

**2026-08-12 — Harness V0 + capa operable**

Se construyó el andamiaje del proyecto desde cero. Todavía no hay código de
producto y eso es intencional (C7: no hay scaffold vacío).

Qué quedó:

- Constitución de 13 artículos (`docs/constitution.md`)
- Workflow con máquina de estados y dos gates (`docs/workflow.md`)
- Formato de specs con EARS + IDs trazables (`specs/README.md`)
- Flujo de cambios sobre specs existentes (`changes/README.md`)
- Convenciones de código (`docs/conventions.md`)
- Definición de "listo" (`docs/verification.md`)
- ADRs 0001–0003: stack, layout, y por qué harness propio
- `verify.sh` con enforcement de los invariantes
- Hooks de Claude Code: gate de spec, guard de secretos, handoff en session start
- **6 skills** (`spec-write`, `spec-approve`, `feature-take`,
  `feature-implement`, `feature-review`, `feature-close`) y **2 agentes**
  (`reviewer` de solo lectura, `spec-critic`), versionados para que el workflow
  sea el mismo para cualquier dev que clone
- CI, PR template, `CONTRIBUTING.md` y `docs/onboarding.md` para varios devs

Bugs encontrados y arreglados probando el enforcement, no leyéndolo:

- El patrón de clave privada empieza con `-`, así que `grep` lo tomaba como
  opciones y el guard de secretos nunca matcheaba claves privadas.
- Las 6 skills tenían frontmatter YAML inválido (`Disparadores: "…"` mete un
  `: ` en un escalar sin quotear) y no habrían cargado. `verify.sh` ahora valida
  el frontmatter de verdad en vez de grepear el nombre.

## Próximo paso

Proponer la primera feature con `/spec-write`. El candidato natural es el modelo
de dominio mínimo — club, cancha, disponibilidad — pero eso se decide al
proponer, no acá.

La primera feature además ejercita lo que todavía no corrió nunca: el job
`spec-gate` de CI (solo dispara en PRs), la capa 2 de `verify.sh`, y las 6 skills
contra un caso real.

## Pendientes conocidos

- `.pnpm-store/` en la raíz quedó root-owned de la iteración previa. Hay que
  borrarlo o cambiarle el owner antes de instalar dependencias, o pnpm va a
  fallar con EACCES.
- Resolver la composición entre este harness y el harness global de skills ya
  instalado (ver contras de [ADR-0003](../docs/adr/0003-harness-spec-driven.md)).
- `verify.sh` capa 2 (typecheck, lint, tests, build) está escrita pero sin nada
  que verificar todavía. Se ejercita con la primera feature.

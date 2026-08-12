# Trabajo en curso

> Este archivo es el **handoff**. Es lo primero que lee un contexto nuevo (agente
> o humano) al arrancar una sesión. Se actualiza al terminar cada sesión de
> trabajo, aunque quede a medias — sobre todo si queda a medias.

## Estado

**Nada en curso.** No hay features en `in_progress`.

## Última sesión

**2026-08-12 — Harness V0**

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

## Próximo paso

Proponer la primera feature. El candidato natural es el modelo de dominio
mínimo — club, cancha, disponibilidad — pero eso se decide al proponer, no acá.

Cuando arranque: `state/features/<slug>.json` en `proposed`, copiar
`specs/_template/` y escribir `requirements.md`.

## Pendientes conocidos

- `.pnpm-store/` en la raíz quedó root-owned de la iteración previa. Hay que
  borrarlo o cambiarle el owner antes de instalar dependencias, o pnpm va a
  fallar con EACCES.
- Resolver la composición entre este harness y el harness global de skills ya
  instalado (ver contras de [ADR-0003](../docs/adr/0003-harness-spec-driven.md)).
- `verify.sh` capa 2 (typecheck, lint, tests, build) está escrita pero sin nada
  que verificar todavía. Se ejercita con la primera feature.

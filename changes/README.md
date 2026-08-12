# Changes

Propuestas de cambio sobre algo **que ya tiene spec y código**. Una feature nueva
va a `specs/`; modificar una existente va acá primero.

```
changes/
  2026-08-20-cancelacion-con-reembolso/
    proposal.md
```

## Por qué no editar la spec directamente

Dos razones:

1. Una spec editada en el lugar pierde el registro de por qué cambió. En seis
   meses vas a leer un requisito raro sin poder saber si es intencional o un
   descuido.
2. Mientras la propuesta está abierta hay código vivo contra la versión anterior
   de la spec. Si editás la spec primero, todo ese código queda "divergente" sin
   que nadie lo haya decidido (C12).

## Ciclo

```
  proposal.md escrito ──▶ GATE humano ──▶ aplicado ──▶ specs/ actualizado ──▶ archivado
```

1. Se crea `changes/<AAAA-MM-DD>-<slug>/proposal.md`.
2. Un humano aprueba (mismo peso que el Gate 1 de una spec nueva).
3. Se implementa, con el ciclo normal de tests y review.
4. **Recién entonces** se actualiza `specs/<feature>/` para reflejar el nuevo
   estado. La spec siempre describe el presente, no el pasado ni el futuro.
5. La propuesta se marca `estado: aplicado` y queda como registro histórico. No
   se borra.

## Formato de `proposal.md`

```markdown
# <título>

- **Estado:** propuesto | aprobado | aplicado | descartado
- **Afecta:** specs/<feature>/ (requisitos R2, R5)
- **Fecha:** AAAA-MM-DD

## Qué está mal hoy

El comportamiento actual, y el problema concreto que causa. Con un caso real —
no hipotético.

## Qué se propone

El cambio, en prosa.

## Diff de requisitos

Requisitos que se agregan, modifican o eliminan. Los IDs eliminados no se
reutilizan (quedan tachados en requirements.md).

- **R2** (modificado): antes «…» → ahora «…»
- **R7** (nuevo): …
- ~~**R5**~~ (eliminado): motivo.

## Impacto

Migraciones, breaking changes, código que hay que tocar, comportamiento visible
que cambia. Qué se rompe si esto sale mal.

## Alternativas descartadas

Al menos una, con motivo.
```

# .claude/

Configuración de Claude Code **compartida** por todo el equipo. Está versionada a
propósito: es la parte del harness que hace que las reglas no sean opcionales.

```
.claude/
  settings.json          compartido — versionado
  settings.local.json    personal — ignorado por git
  hooks/                 enforcement fuera del contexto del modelo
```

## Compartido vs. personal

| Archivo | Alcance | Git |
|---|---|---|
| `settings.json` | reglas del proyecto, iguales para todos | versionado |
| `settings.local.json` | tus permisos, tu modelo, tus preferencias | ignorado |

Si querés cambiar algo solo para vos, va en `settings.local.json`. Si tocás
`settings.json`, estás cambiando cómo trabaja el equipo: va con explicación en el
commit.

## Hooks

| Hook | Evento | Qué hace |
|---|---|---|
| `session-start.sh` | SessionStart | Inyecta el handoff (`progress/current.md` + features activas) para que un contexto nuevo arranque sabiendo dónde está |
| `guard-secrets.sh` | PreToolUse Write/Edit | Bloquea escrituras con forma de credencial (C9) |
| `guard-spec-gate.sh` | PreToolUse Write/Edit | Bloquea código de producto sin feature en `in_progress` (C2) |
| `verify-on-stop.sh` | Stop | Corre `verify.sh --harness` antes de cerrar el turno (C4) |

**Por qué hooks y no reglas escritas:** un `.md` es contexto que compite con el
trabajo y que el modelo puede olvidar en la iteración 40. Un exit code no se
olvida. Las reglas que importan viven acá y en `verify.sh`; el resto es
documentación.

## Escapes

Existen a propósito, porque un guard sin escape se termina desactivando entero:

- `HARNESS_GATE=off` — desactiva el gate de spec. Para excepciones legítimas
  (config de tooling, corrección trivial). **Decilo cuando lo uses**; no lo dejes
  exportado en tu shell.
- `stop_hook_active` — el hook de Stop se autodesactiva en el segundo intento de
  la misma cadena, así un fallo que el modelo no puede arreglar no bloquea para
  siempre.

Si un guard te bloquea seguido y de forma injusta, eso es un bug del harness. Se
reporta y se afloja a advertencia antes de sacarlo.

## Alcance de los hooks

Los `PreToolUse` de acá solo corren en Claude Code. **No son la última línea de
defensa** — un dev con otro agente, u otro editor, no los tiene. Por eso todo
invariante que importe está *también* en `verify.sh`, y `verify.sh` corre en CI
(`.github/workflows/verify.yml`). Los hooks dan feedback temprano; CI da la
garantía.

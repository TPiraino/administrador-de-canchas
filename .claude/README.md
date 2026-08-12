# .claude/

Configuración de Claude Code **compartida** por todo el equipo. Está versionada a
propósito: es la parte del harness que hace que las reglas no sean opcionales.

```
.claude/
  settings.json          compartido — versionado
  settings.local.json    personal — ignorado por git
  hooks/                 enforcement fuera del contexto del modelo
  skills/                el workflow, operable
  agents/                roles con contexto aislado
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

## Skills

Una por cada transición que muta `state/` o `specs/`. Están versionadas para que un
dev nuevo clone y tenga el mismo workflow — no dependiente del `~/.claude` de cada
máquina.

| Skill | Fase | Nota |
|---|---|---|
| `spec-write` | spec | requirements → design → tasks, en orden; corta ante ambigüedad |
| `spec-approve` | **Gate 1** | su trabajo principal es **no aprobar**: prepara la decisión y se detiene |
| `feature-take` | tomar | separada de `implement` a propósito: tomar una feature es público **antes** del código |
| `feature-implement` | implementar | test primero con el `R#` en el nombre; para si aparece algo fuera de spec |
| `feature-review` | review | despacha subagente fresco; nunca revisa en línea (C5) |
| `feature-close` | **Gate 2** | verifica en vez de tildar de memoria |

**Lo que a propósito NO es skill:** verificar (ya es `./verify.sh`), las convenciones
de código (`docs/conventions.md`), cómo escribir EARS (`specs/README.md`) y
orientarse al arrancar (el hook de `SessionStart`). Envolver eso en skills agrega una
capa que puede divergir de la fuente.

## Agentes

| Agente | Herramientas | Para qué |
|---|---|---|
| `reviewer` | solo lectura | Review de contexto fresco. Sin herramientas de escritura **a propósito**: un reviewer que arregla mientras revisa termina aprobando su propio trabajo (C5) |
| `spec-critic` | solo lectura | Ataca la spec antes del Gate 1 buscando ambigüedad, requisitos no verificables y contratos inventados. Es el punto más barato del ciclo para encontrar un malentendido |

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

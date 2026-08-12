#!/usr/bin/env bash
#
# PreToolUse (Write|Edit|NotebookEdit) — enforcea C2: nada de código de producto
# sin una spec aprobada y tomada.
#
# Solo aplica a código de producto: apps/, packages/, src/. Todo lo demás —el
# harness, la config de tooling, la documentación— pasa sin preguntar.
#
# Escape: HARNESS_GATE=off ./claude   (usalo y decilo, no lo dejes puesto)

set -uo pipefail

[[ "${HARNESS_GATE:-on}" == "off" ]] && exit 0

ROOT="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
INPUT="$(cat)"

command -v jq >/dev/null 2>&1 || exit 0   # sin jq no bloqueamos; verify.sh ya avisa

FILE="$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // .tool_input.notebook_path // ""')"
[[ -n "$FILE" ]] || exit 0

# Path relativo al repo
REL="${FILE#"$ROOT"/}"

# ¿Es código de producto?
case "$REL" in
  apps/*|packages/*|src/*) ;;
  *) exit 0 ;;
esac

# Config de tooling dentro de esos directorios: exenta.
BASE="$(basename "$REL")"
case "$BASE" in
  package.json|pnpm-lock.yaml|tsconfig*.json|*.config.js|*.config.ts|*.config.mjs|\
  Dockerfile|.dockerignore|.eslintrc*|.prettierrc*|.env.example|README.md)
    exit 0 ;;
esac

# ¿Hay una feature tomada?
shopt -s nullglob
IN_PROGRESS=()
for f in "$ROOT"/state/features/*.json; do
  [[ "$(jq -r '.state // ""' "$f" 2>/dev/null)" == "in_progress" ]] || continue
  IN_PROGRESS+=("$(basename "$f" .json)")
done
shopt -u nullglob

if ((${#IN_PROGRESS[@]} == 0)); then
  cat >&2 <<EOF
BLOQUEADO por el harness (C2): no hay ninguna feature en estado in_progress.

Querés escribir código de producto en:
  $REL

Antes de eso hace falta:
  1. state/features/<slug>.json en estado proposed
  2. specs/<slug>/{requirements,design,tasks}.md completos
  3. Aprobación humana → state spec_approved con approval.by y approval.at
  4. Tomar la feature → state in_progress con owner

Ver docs/workflow.md. Si esto es una excepción legítima (config de tooling,
corrección trivial sin cambio de comportamiento), decilo y corré con
HARNESS_GATE=off.
EOF
  exit 2
fi

# Feature tomada: verificar que la spec siga siendo coherente.
SLUG="${IN_PROGRESS[0]}"
if [[ ! -f "$ROOT/specs/$SLUG/tasks.md" ]]; then
  cat >&2 <<EOF
BLOQUEADO por el harness (C2): la feature «$SLUG» está in_progress pero no tiene
specs/$SLUG/tasks.md. No hay plan que ejecutar.
EOF
  exit 2
fi

exit 0

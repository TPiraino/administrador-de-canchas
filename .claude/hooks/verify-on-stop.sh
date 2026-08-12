#!/usr/bin/env bash
#
# Stop — corre la capa 1 de verify.sh antes de dar por terminado el turno.
#
# Solo la capa de harness: es rápida y no necesita dependencias. La capa de stack
# es responsabilidad explícita de quien cierra la feature — no queremos correr
# builds en cada Stop.
#
# Anti-loop: si stop_hook_active viene en true, ya bloqueamos una vez en esta
# cadena y dejamos pasar. Sin esto, un fallo que el modelo no puede arreglar
# bloquearía para siempre.

set -uo pipefail

ROOT="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
INPUT="$(cat)"

if command -v jq >/dev/null 2>&1; then
  [[ "$(printf '%s' "$INPUT" | jq -r '.stop_hook_active // false')" == "true" ]] && exit 0
fi

cd "$ROOT" || exit 0
[[ -x ./verify.sh ]] || exit 0

if OUT="$(./verify.sh --harness 2>&1)"; then
  exit 0
fi

{
  echo "El harness quedó inconsistente (verify.sh --harness en rojo). Arreglalo antes de terminar:"
  echo
  echo "$OUT"
} >&2
exit 2

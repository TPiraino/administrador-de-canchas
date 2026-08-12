#!/usr/bin/env bash
#
# SessionStart — inyecta el handoff al arrancar.
#
# El punto es que un contexto nuevo no tenga que acordarse de leer
# progress/current.md: lo recibe puesto. C1 sirve solo si el estado en disco
# efectivamente llega al contexto.

set -uo pipefail

ROOT="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
cd "$ROOT" || exit 0

echo "=== Harness gestión de canchas ==="
echo
echo "Leé AGENTS.md y docs/constitution.md antes de actuar."
echo "Ningún código de producto sin spec aprobada (C2). Nada terminado sin ./verify.sh (C13)."
echo

if command -v jq >/dev/null 2>&1; then
  shopt -s nullglob
  found=0
  for f in state/features/*.json; do
    slug="$(basename "$f" .json)"
    state="$(jq -r '.state // "?"' "$f" 2>/dev/null)"
    owner="$(jq -r '.owner // "—"' "$f" 2>/dev/null)"
    [[ "$state" == "done" || "$state" == "archived" ]] && continue
    ((found == 0)) && echo "--- Features activas ---"
    printf '  %-32s %-14s owner: %s\n' "$slug" "$state" "$owner"
    found=1
  done
  shopt -u nullglob
  ((found == 0)) && echo "--- Sin features activas ---"
  echo
fi

if [[ -f progress/current.md ]]; then
  echo "--- progress/current.md ---"
  cat progress/current.md
fi

exit 0

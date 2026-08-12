#!/usr/bin/env bash
#
# PreToolUse (Write|Edit) — enforcea C9: los secretos no entran al repo.
#
# Bloquea antes de escribir, no después de commitear: un secreto que llegó al
# working tree ya está en riesgo de terminar en un commit.
#
# Patrones conservadores a propósito. Un falso positivo bloquea trabajo real, así
# que solo matcheamos credenciales con forma reconocible.

set -uo pipefail

INPUT="$(cat)"
command -v jq >/dev/null 2>&1 || exit 0

CONTENT="$(printf '%s' "$INPUT" | jq -r '
  .tool_input.content
  // .tool_input.new_string
  // (.tool_input.edits // [] | map(.new_string) | join("\n"))
  // ""')"
[[ -n "$CONTENT" ]] || exit 0

FILE="$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // ""')"
case "$FILE" in
  *.example|*/guard-secrets.sh|*/verify.sh) exit 0 ;;
esac

PATTERNS=(
  'AKIA[0-9A-Z]{16}'
  '-----BEGIN [A-Z ]*PRIVATE KEY-----'
  'gh[pousr]_[A-Za-z0-9]{30,}'
  'sk-[A-Za-z0-9_-]{24,}'
  'eyJ[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}'
  '(postgres|postgresql|mysql|mongodb(\+srv)?)://[^:[:space:]]+:[^@[:space:]]+@'
)

HITS=""
for pat in "${PATTERNS[@]}"; do
  # `--` es obligatorio: hay patrones que empiezan con «-» (claves privadas) y
  # grep los tomaría como opciones.
  found="$(printf '%s' "$CONTENT" | grep -nE -- "$pat" 2>/dev/null \
    | grep -viE 'example|changeme|placeholder|your[-_]|xxx|<[^>]+>|user:pass|foo:bar' || true)"
  [[ -n "$found" ]] && HITS+="$found"$'\n'
done

if [[ -n "${HITS//[$'\n']/}" ]]; then
  {
    echo "BLOQUEADO por el harness (C9): el contenido a escribir contiene algo con"
    echo "forma de credencial."
    echo
    echo "Archivo: ${FILE:-«sin path»}"
    echo "Coincidencias:"
    echo "$HITS" | sed '/^$/d' | sed 's/^/  /'
    echo
    echo "Config sensible va por variable de entorno, con .env.example documentando"
    echo "las claves sin los valores. Si es un valor de ejemplo, hacelo evidente"
    echo "(<placeholder>, CHANGEME, user:pass)."
  } >&2
  exit 2
fi

exit 0

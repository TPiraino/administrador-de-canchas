#!/usr/bin/env bash
#
# verify.sh — la única definición de "verde" (C4).
#
#   ./verify.sh            capa 1 (harness) + capa 2 (stack)
#   ./verify.sh --harness   solo capa 1: rápido, no necesita dependencias
#   ./verify.sh --stack     solo capa 2
#
# Exit 0 = verde. Exit 1 = algo falló. Nada se saltea en silencio (C13):
# lo que no se pudo correr se reporta como SKIP con el motivo.

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

RUN_HARNESS=1
RUN_STACK=1
case "${1:-}" in
  --harness) RUN_STACK=0 ;;
  --stack)   RUN_HARNESS=0 ;;
  "")        ;;
  -h|--help) sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
  *)         echo "opción desconocida: $1" >&2; exit 2 ;;
esac

if [[ -t 1 ]]; then
  R=$'\e[31m'; G=$'\e[32m'; Y=$'\e[33m'; B=$'\e[1m'; N=$'\e[0m'
else
  R=""; G=""; Y=""; B=""; N=""
fi

FAILURES=0
SKIPS=0

pass() { printf '  %s✓%s %s\n' "$G" "$N" "$1"; }
fail() { printf '  %s✗%s %s\n' "$R" "$N" "$1"; FAILURES=$((FAILURES + 1)); }
skip() { printf '  %s—%s %s\n' "$Y" "$N" "$1"; SKIPS=$((SKIPS + 1)); }
head1() { printf '\n%s%s%s\n' "$B" "$1" "$N"; }

VALID_STATES=(proposed spec_draft spec_approved in_progress in_review done archived)
POST_APPROVAL=(spec_approved in_progress in_review done)
NEEDS_TRACEABILITY=(in_progress in_review done)

in_list() {
  local needle="$1"; shift
  local item
  for item in "$@"; do [[ "$item" == "$needle" ]] && return 0; done
  return 1
}

# ---------------------------------------------------------------------------
# Capa 1 — consistencia del harness
# ---------------------------------------------------------------------------

verify_harness() {
  head1 "Capa 1 — consistencia del harness"

  if ! command -v jq >/dev/null 2>&1; then
    fail "jq no está instalado y es necesario para validar state/. Instalá jq y volvé a correr."
    return
  fi

  # --- Archivos del harness presentes ---
  local required=(
    AGENTS.md
    docs/constitution.md
    docs/workflow.md
    docs/conventions.md
    docs/verification.md
    specs/README.md
    changes/README.md
    state/README.md
    progress/current.md
  )
  local missing=()
  local f
  for f in "${required[@]}"; do [[ -f "$f" ]] || missing+=("$f"); done
  if ((${#missing[@]})); then
    fail "faltan archivos del harness: ${missing[*]}"
  else
    pass "archivos del harness presentes (${#required[@]})"
  fi

  # --- Features ---
  shopt -s nullglob
  local feature_files=(state/features/*.json)
  shopt -u nullglob

  if ((${#feature_files[@]} == 0)); then
    skip "no hay features en state/features/ — nada que validar todavía"
  else
    verify_features "${feature_files[@]}"
  fi

  verify_no_secrets
}

verify_features() {
  local files=("$@")
  local file slug state owner approval_by title
  local bad_json=() bad_state=() bad_slug=() no_approval=() no_spec=() no_reqs=() ambiguous=()
  local -a in_progress_owners=()
  local -a traceability_targets=()

  for file in "${files[@]}"; do
    if ! jq -e . "$file" >/dev/null 2>&1; then
      bad_json+=("$file")
      continue
    fi

    slug="$(jq -r '.slug // ""' "$file")"
    state="$(jq -r '.state // ""' "$file")"
    owner="$(jq -r '.owner // "«sin owner»"' "$file")"
    approval_by="$(jq -r '.approval.by // ""' "$file")"
    title="$(jq -r '.title // ""' "$file")"

    local expected_slug
    expected_slug="$(basename "$file" .json)"
    [[ "$slug" == "$expected_slug" ]] || bad_slug+=("$file (slug=«$slug»)")

    if ! in_list "$state" "${VALID_STATES[@]}"; then
      bad_state+=("$expected_slug (state=«$state»)")
      continue
    fi

    [[ -n "$title" ]] || fail "$expected_slug: falta title"

    if in_list "$state" "${POST_APPROVAL[@]}"; then
      [[ -n "$approval_by" ]] || no_approval+=("$expected_slug ($state)")

      local spec_dir="specs/$expected_slug"
      local spec_missing=()
      local doc
      for doc in requirements.md design.md tasks.md; do
        [[ -f "$spec_dir/$doc" ]] || spec_missing+=("$doc")
      done
      if ((${#spec_missing[@]})); then
        no_spec+=("$expected_slug (falta: ${spec_missing[*]})")
      else
        # IDs de requisito: declarados al principio de línea como «R<n> »
        local ids
        ids="$(grep -oE '^R[0-9]+' "$spec_dir/requirements.md" 2>/dev/null | sort -u -V || true)"
        if [[ -z "$ids" ]]; then
          no_reqs+=("$expected_slug")
        elif in_list "$state" "${NEEDS_TRACEABILITY[@]}"; then
          traceability_targets+=("$expected_slug")
        fi

        if grep -q '\[AMBIGUO:' "$spec_dir/requirements.md" 2>/dev/null; then
          ambiguous+=("$expected_slug")
        fi
      fi
    fi

    if [[ "$state" == "in_progress" ]]; then
      in_progress_owners+=("$owner")
    fi
  done

  ((${#bad_json[@]}))    && fail "JSON inválido: ${bad_json[*]}"        || pass "state/features/: ${#files[@]} archivo(s), JSON válido"
  ((${#bad_slug[@]}))    && fail "slug ≠ nombre de archivo: ${bad_slug[*]}"      || true
  ((${#bad_state[@]}))   && fail "estado no permitido: ${bad_state[*]}"          || pass "estados dentro del conjunto permitido"
  ((${#no_approval[@]})) && fail "aprobada sin registro de aprobación humana (C2): ${no_approval[*]}" || true
  ((${#no_spec[@]}))     && fail "aprobada sin spec completa: ${no_spec[*]}"     || true
  ((${#no_reqs[@]}))     && fail "requirements.md sin ningún ID R<n>: ${no_reqs[*]}" || true
  ((${#ambiguous[@]}))   && fail "aprobada con ambigüedades sin resolver: ${ambiguous[*]}" || true

  # Un in_progress por owner
  if ((${#in_progress_owners[@]})); then
    local dupes
    dupes="$(printf '%s\n' "${in_progress_owners[@]}" | sort | uniq -d)"
    if [[ -n "$dupes" ]]; then
      fail "más de una feature en in_progress para el mismo owner: $(echo "$dupes" | tr '\n' ' ')"
    else
      pass "un in_progress por owner (${#in_progress_owners[@]} en vuelo)"
    fi
  fi

  # Handoff: current.md tiene que mencionar lo que está en vuelo
  local slug_ip
  shopt -s nullglob
  for file in state/features/*.json; do
    [[ "$(jq -r '.state // ""' "$file")" == "in_progress" ]] || continue
    slug_ip="$(basename "$file" .json)"
    if grep -q "$slug_ip" progress/current.md 2>/dev/null; then
      pass "handoff menciona $slug_ip"
    else
      fail "progress/current.md no menciona la feature en curso «$slug_ip» (C1)"
    fi
  done
  shopt -u nullglob

  if ((${#traceability_targets[@]})); then
    verify_traceability "${traceability_targets[@]}"
  fi
}

# Cada requisito de una feature implementada tiene que estar mencionado en un
# test. Es C3 con exit code.
verify_traceability() {
  local slugs=("$@")
  local test_files
  test_files="$(git ls-files 2>/dev/null \
    | grep -E '(\.spec\.[jt]sx?|\.test\.[jt]sx?|^tests?/|^e2e/)' || true)"

  if [[ -z "$test_files" ]]; then
    fail "hay features implementadas (${slugs[*]}) y no existe ningún archivo de test (C3)"
    return
  fi

  local slug id orphans
  for slug in "${slugs[@]}"; do
    orphans=""
    while read -r id; do
      [[ -n "$id" ]] || continue
      if ! echo "$test_files" | xargs -r grep -lE "\b${id}\b" >/dev/null 2>&1; then
        orphans+="$id "
      fi
    done < <(grep -oE '^R[0-9]+' "specs/$slug/requirements.md" | sort -u -V)

    if [[ -n "$orphans" ]]; then
      fail "$slug: requisitos sin test que los referencie (C3): $orphans"
    else
      pass "$slug: todos los requisitos trazados a tests"
    fi
  done
}

# Patrones conservadores: buscamos credenciales con forma reconocible, no
# cualquier string que parezca sospechoso. Un falso positivo acá bloquea trabajo
# real, así que preferimos precisión sobre recall.
verify_no_secrets() {
  local files
  files="$(git ls-files 2>/dev/null || true)"
  if [[ -z "$files" ]]; then
    skip "sin archivos trackeados por git — no se pudo chequear secretos"
    return
  fi

  # El propio harness contiene los patrones; excluirlo evita autodetección.
  files="$(echo "$files" | grep -vE '^(verify\.sh|\.claude/hooks/|\.github/workflows/)' || true)"
  files="$(echo "$files" | grep -vE '\.example$' || true)"
  [[ -n "$files" ]] || { pass "sin secretos detectados (nada que revisar)"; return; }

  local patterns=(
    'AKIA[0-9A-Z]{16}'
    '-----BEGIN [A-Z ]*PRIVATE KEY-----'
    'gh[pousr]_[A-Za-z0-9]{30,}'
    'sk-[A-Za-z0-9_-]{24,}'
    'eyJ[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}'
    '(postgres|postgresql|mysql|mongodb(\+srv)?)://[^:[:space:]]+:[^@[:space:]]+@'
  )

  local hits="" pat found
  for pat in "${patterns[@]}"; do
    # `--` es obligatorio: hay patrones que empiezan con «-» (claves privadas) y
    # grep los tomaría como opciones.
    found="$(echo "$files" | xargs -r grep -InE -- "$pat" 2>/dev/null \
      | grep -viE 'example|changeme|placeholder|your[-_]|xxx|<[^>]+>|user:pass|foo:bar' || true)"
    [[ -n "$found" ]] && hits+="$found"$'\n'
  done

  if [[ -n "${hits//[$'\n']/}" ]]; then
    fail "posible secreto en archivos trackeados (C9):"
    echo "$hits" | sed '/^$/d' | sed 's/^/      /' >&2
  else
    pass "sin secretos detectados en archivos trackeados"
  fi
}

# ---------------------------------------------------------------------------
# Capa 2 — checks del stack
# ---------------------------------------------------------------------------

# Corre un script de package.json si existe. Reporta SKIP explícito si no.
run_script() {
  local name="$1" label="$2"
  if [[ ! -f package.json ]]; then
    skip "$label — todavía no hay package.json"
    return
  fi
  if ! jq -e --arg s "$name" '.scripts[$s]' package.json >/dev/null 2>&1; then
    skip "$label — no hay script «$name» en package.json"
    return
  fi
  if [[ ! -d node_modules ]]; then
    skip "$label — dependencias no instaladas (corré pnpm install)"
    return
  fi
  local out
  if out="$(pnpm run "$name" 2>&1)"; then
    pass "$label"
  else
    fail "$label"
    echo "$out" | tail -40 | sed 's/^/      /' >&2
  fi
}

verify_stack() {
  head1 "Capa 2 — checks del stack"

  if [[ ! -f package.json ]]; then
    skip "sin código todavía — capa 2 completa salteada"
    return
  fi
  if ! command -v pnpm >/dev/null 2>&1; then
    fail "package.json existe pero pnpm no está instalado"
    return
  fi

  run_script typecheck "typecheck"
  run_script lint      "lint"
  run_script test      "tests"
  run_script build     "build"
}

# ---------------------------------------------------------------------------

printf '%sverify.sh%s — %s\n' "$B" "$N" "$(pwd)"
((RUN_HARNESS)) && verify_harness
((RUN_STACK))   && verify_stack

head1 "Resultado"
if ((FAILURES == 0)); then
  if ((SKIPS > 0)); then
    printf '  %sVERDE%s — 0 fallas, %d check(s) salteado(s) y reportado(s)\n' "$G" "$N" "$SKIPS"
  else
    printf '  %sVERDE%s — 0 fallas\n' "$G" "$N"
  fi
  exit 0
fi
printf '  %sROJO%s — %d falla(s), %d salteado(s)\n' "$R" "$N" "$FAILURES" "$SKIPS"
exit 1

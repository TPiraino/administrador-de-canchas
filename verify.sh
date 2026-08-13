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

  verify_ids_unicos
  verify_skills
  verify_no_secrets
}

# Los IDs de requisito tienen que ser únicos en TODO el proyecto, no por feature.
# Motivo: verify_traceability busca el ID como texto plano en los tests. Si dos
# features declaran R3, un solo test que diga «R3» satisface a las dos y la
# trazabilidad miente en verde. Apareció de verdad al dividir una feature en dos.
verify_ids_unicos() {
  shopt -s nullglob
  local reqs=(specs/*/requirements.md)
  shopt -u nullglob

  # el template no declara requisitos reales
  local files=()
  local f
  for f in "${reqs[@]}"; do
    [[ "$f" == specs/_template/* ]] || files+=("$f")
  done

  if ((${#files[@]} < 2)); then
    pass "IDs de requisito únicos (${#files[@]} feature(s), nada que cruzar)"
    return
  fi

  # «ID<TAB>slug» por cada declaración, y buscamos IDs presentes en más de un slug.
  # Ojo: awk con separador " " hace split por whitespace y descarta el espacio
  # inicial, así que el conteo es la cantidad real de slugs (no hay off-by-one).
  local dupes
  dupes="$(
    for f in "${files[@]}"; do
      local slug; slug="$(basename "$(dirname "$f")")"
      grep -oE '^R[0-9]+' "$f" | sort -u | sed "s|\$|\t$slug|"
    done | awk -F'\t' '
      { seen[$1] = seen[$1] " " $2 }
      END { for (id in seen) if (split(seen[id], a, " ") > 1) print id " →" seen[id] }
    ' | sort -V
  )"

  if [[ -n "$dupes" ]]; then
    fail "IDs de requisito declarados en más de una feature — la trazabilidad no los puede distinguir:"
    while IFS= read -r line; do printf '      %s\n' "$line" >&2; done <<< "$dupes"
    echo "      Un ID al principio de línea es una declaración. Para mencionar uno ajeno, usá backticks y no lo pongas al comienzo del renglón." >&2
  else
    local total
    total="$(for f in "${files[@]}"; do grep -oE '^R[0-9]+' "$f"; done | sort -u | wc -l)"
    pass "IDs de requisito únicos en el proyecto ($total en ${#files[@]} features)"
  fi
}

# Las skills y agentes son parte del harness compartido: si alguien borra uno o le
# rompe el frontmatter, el workflow deja de ser operable para todo el equipo y nadie
# se entera hasta que lo necesita.
#
# El frontmatter se valida de verdad, no solo se grepea el nombre: un `description`
# sin quotear que contenga «: » rompe el YAML y la skill no carga, en silencio.
# Pasó una vez; por eso está acá.
verify_skills() {
  local expected_skills=(
    spec-write spec-approve feature-take
    feature-implement feature-review feature-close
  )
  local expected_agents=(reviewer spec-critic)

  local missing=() broken=()
  local s a f

  for s in "${expected_skills[@]}"; do
    f=".claude/skills/$s/SKILL.md"
    [[ -f "$f" ]] || { missing+=("$f"); continue; }
    check_frontmatter "$f" "$s" || broken+=("$FM_ERROR")
  done

  for a in "${expected_agents[@]}"; do
    f=".claude/agents/$a.md"
    [[ -f "$f" ]] || { missing+=("$f"); continue; }
    check_frontmatter "$f" "$a" || broken+=("$FM_ERROR")
  done

  if ((${#missing[@]})); then
    fail "faltan skills/agentes del harness: ${missing[*]}"
  fi
  if ((${#broken[@]})); then
    fail "frontmatter roto:"
    printf '      %s\n' "${broken[@]}" >&2
  fi
  if ((${#missing[@]} == 0 && ${#broken[@]} == 0)); then
    pass "skills (${#expected_skills[@]}) y agentes (${#expected_agents[@]}) con frontmatter válido"
  fi
}

# Valida el frontmatter YAML de una skill o agente. Deja el motivo en $FM_ERROR.
FM_ERROR=""
check_frontmatter() {
  local file="$1" expected_name="$2"
  FM_ERROR=""

  if [[ "$(head -1 "$file")" != "---" ]]; then
    FM_ERROR="$file: no arranca con «---»"
    return 1
  fi

  local fm
  fm="$(awk 'NR>1 { if ($0 == "---") exit; print }' "$file")"
  if [[ -z "$fm" ]]; then
    FM_ERROR="$file: frontmatter vacío o sin cierre «---»"
    return 1
  fi

  local declared
  declared="$(printf '%s\n' "$fm" | sed -n 's/^name:[[:space:]]*//p' | head -1 | tr -d "\"'")"
  if [[ -z "$declared" ]]; then
    FM_ERROR="$file: falta «name»"
    return 1
  fi
  if [[ "$declared" != "$expected_name" ]]; then
    FM_ERROR="$file: name=«$declared», se esperaba «$expected_name»"
    return 1
  fi

  local desc
  desc="$(printf '%s\n' "$fm" | sed -n 's/^description:[[:space:]]*//p' | head -1)"
  if [[ -z "$desc" ]]; then
    FM_ERROR="$file: falta «description»"
    return 1
  fi

  # Escalar YAML sin quotear que contiene «: » → el parser corta ahí y la skill
  # no carga. Es un fallo silencioso, así que se chequea explícitamente.
  if [[ "${desc:0:1}" != "'" && "${desc:0:1}" != '"' && "$desc" == *": "* ]]; then
    FM_ERROR="$file: «description» sin quotear contiene «: » → YAML inválido. Envolvela en comillas simples."
    return 1
  fi

  return 0
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

#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# tests/ingress-nginx/scripts/run_tests.sh
#
# Offline test suite for the ingress-nginx template.
# No cluster required – only helm (with chart dependencies fetched).
#
# Usage:
#   bash tests/ingress-nginx/scripts/run_tests.sh [TEST_IDS...]
#
# Examples:
#   bash tests/ingress-nginx/scripts/run_tests.sh          # run all tests
#   bash tests/ingress-nginx/scripts/run_tests.sh 1 3 f2   # run test-1, test-3 and fail-case-2
#   bash tests/ingress-nginx/scripts/run_tests.sh f         # run all fail-cases
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_DIR="${SCRIPT_DIR}/.."
CHART="${CHART:-${SCRIPT_DIR}/../../../charts/interop-eks-microservice-chart}"
BASE="${TEST_DIR}/helm-values/values-base.yaml"

# ── Colors ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
pass()      { echo -e "${GREEN}[PASS]${NC} $*"; }
fail_msg()  { echo -e "${RED}[FAIL]${NC} $*"; FAILED_TESTS+=("$*"); }
info()      { echo -e "${YELLOW}[INFO]${NC} $*"; }
section()   { echo -e "\n${CYAN}── $* ──${NC}"; }
separator() { echo "────────────────────────────────────────────────────────────────"; }

FAILED_TESTS=()

# ── Test-selection ─────────────────────────────────────────────────────────────
# Accepts plain numbers (1 2 3...) and/or "f" prefix for fail-cases (f1 f2...).
# Empty → run all.
SELECTED=()
[[ $# -gt 0 ]] && SELECTED=("$@") || true

should_run() {                    # $1: "1"-"5" or "f1"-"f5"
  [ "${#SELECTED[@]}" -eq 0 ] && return 0
  for sel in "${SELECTED[@]}"; do
    [[ "$sel" == "$1" ]] && return 0
    # "f" alone means run all fail-cases
    [[ "$sel" == "f" && "$1" == f* ]] && return 0
  done
  return 1
}

# ── Helpers ────────────────────────────────────────────────────────────────────
# lint: runs helm lint and prints a simplified summary line.
run_lint() {
  local tc="$1"
  helm lint "$CHART" -f "$BASE" -f "$tc" --strict 2>&1
}

# template: renders the chart and captures stdout.
run_template() {
  local tc="$1"
  helm template test-svc "$CHART" -f "$BASE" -f "$tc" 2>&1
}

# assert_contains: grep for a pattern in the rendered output.
assert_contains() {          # $1: label  $2: pattern  $3: rendered output
  if echo "$3" | grep -qE "$2"; then
    pass "$1: found «$2»"
  else
    fail_msg "$1: expected «$2» – NOT FOUND"
  fi
}

# assert_absent: fail if pattern is present.
assert_absent() {            # $1: label  $2: pattern  $3: rendered output
  if echo "$3" | grep -qE "$2"; then
    fail_msg "$1: «$2» should be ABSENT but was found"
  else
    pass "$1: «$2» correctly absent"
  fi
}

# assert_count: check exact number of pattern occurrences.
assert_count() {             # $1: label  $2: pattern  $3: expected  $4: rendered
  local n
  n=$(echo "$4" | grep -cE "$2" || true)
  if [[ "$n" -eq "$3" ]]; then
    pass "$1: «$2» appears exactly $3 time(s)"
  else
    fail_msg "$1: «$2» expected $3 time(s), found $n"
  fi
}

# ── Preflight ──────────────────────────────────────────────────────────────────
separator
info "Chart: $CHART"
info "Base values: $BASE"
command -v helm >/dev/null 2>&1 || { echo "ERROR: helm not found"; exit 1; }
[ -d "$CHART" ] || { echo "ERROR: chart directory not found: $CHART"; exit 1; }

# ── Positive test cases ────────────────────────────────────────────────────────

# ── Test 1: single host, single path (Prefix) ─────────────────────────────────
if should_run "1"; then
  TC="${TEST_DIR}/helm-values/test-case-1-single-rule.yaml"
  section "Test 1 – single host / single path"

  if run_lint "$TC" >/dev/null 2>&1; then
    pass "Test 1: helm lint passed"
  else
    fail_msg "Test 1: helm lint FAILED"
    run_lint "$TC" || true
  fi

  rendered=$(run_template "$TC")
  assert_contains "Test 1" "kind: Ingress"           "$rendered"
  assert_contains "Test 1" "ingressClassName: nginx" "$rendered"
  assert_contains "Test 1" 'host: "api\.example\.com"' "$rendered"
  assert_contains "Test 1" 'path: "/api"'            "$rendered"
  assert_contains "Test 1" "pathType: Prefix"        "$rendered"
  assert_count    "Test 1" "^    - host:" 1           "$rendered"
fi

# ── Test 2: single host, multiple paths ───────────────────────────────────────
if should_run "2"; then
  TC="${TEST_DIR}/helm-values/test-case-2-multi-path-single-host.yaml"
  section "Test 2 – single host / multiple paths"

  if run_lint "$TC" >/dev/null 2>&1; then
    pass "Test 2: helm lint passed"
  else
    fail_msg "Test 2: helm lint FAILED"
    run_lint "$TC" || true
  fi

  rendered=$(run_template "$TC")
  assert_contains "Test 2" "kind: Ingress"           "$rendered"
  # The helper must group both paths under a SINGLE host rule entry.
  assert_count    "Test 2" "^    - host:" 1           "$rendered"
  assert_contains "Test 2" 'host: "api\.example\.com"' "$rendered"
  assert_contains "Test 2" 'path: "/api"'            "$rendered"
  assert_contains "Test 2" 'path: "/health"'         "$rendered"
  assert_contains "Test 2" "pathType: Prefix"        "$rendered"
  assert_contains "Test 2" "pathType: Exact"         "$rendered"
fi

# ── Test 3: multiple hosts ────────────────────────────────────────────────────
if should_run "3"; then
  TC="${TEST_DIR}/helm-values/test-case-3-multi-host.yaml"
  section "Test 3 – multiple hosts"

  if run_lint "$TC" >/dev/null 2>&1; then
    pass "Test 3: helm lint passed"
  else
    fail_msg "Test 3: helm lint FAILED"
    run_lint "$TC" || true
  fi

  rendered=$(run_template "$TC")
  assert_contains "Test 3" "kind: Ingress"                  "$rendered"
  assert_count    "Test 3" "^    - host:" 2                  "$rendered"
  assert_contains "Test 3" 'host: "api\.example\.com"'      "$rendered"
  assert_contains "Test 3" 'host: "admin\.example\.com"'    "$rendered"
fi

# ── Test 4: custom annotations ────────────────────────────────────────────────
if should_run "4"; then
  TC="${TEST_DIR}/helm-values/test-case-4-annotations.yaml"
  section "Test 4 – custom annotations"

  if run_lint "$TC" >/dev/null 2>&1; then
    pass "Test 4: helm lint passed"
  else
    fail_msg "Test 4: helm lint FAILED"
    run_lint "$TC" || true
  fi

  rendered=$(run_template "$TC")
  assert_contains "Test 4" "kind: Ingress"                                    "$rendered"
  assert_contains "Test 4" "nginx\.ingress\.kubernetes\.io/rewrite-target"    "$rendered"
  assert_contains "Test 4" "nginx\.ingress\.kubernetes\.io/ssl-redirect"      "$rendered"
  assert_contains "Test 4" "pathType: ImplementationSpecific"                 "$rendered"
fi

# ── Test 5: ingress disabled (create: false) ──────────────────────────────────
if should_run "5"; then
  TC="${TEST_DIR}/helm-values/test-case-5-ingress-disabled.yaml"
  section "Test 5 – ingress disabled"

  if run_lint "$TC" >/dev/null 2>&1; then
    pass "Test 5: helm lint passed"
  else
    fail_msg "Test 5: helm lint FAILED"
    run_lint "$TC" || true
  fi

  rendered=$(run_template "$TC")
  assert_absent "Test 5" "kind: Ingress" "$rendered"
fi

# ── Test 6: ALB type – rules is optional ─────────────────────────────────────
if should_run "6"; then
  TC="${TEST_DIR}/helm-values/test-case-6-alb-no-rules.yaml"
  section "Test 6 – ALB type, rules absent (optional for alb)"

  if run_lint "$TC" >/dev/null 2>&1; then
    pass "Test 6: helm lint passed (rules correctly optional for alb)"
  else
    fail_msg "Test 6: helm lint FAILED (rules should be optional when type=alb)"
    run_lint "$TC" || true
  fi

  rendered=$(run_template "$TC")
  # The ALB template renders its own Ingress; the nginx template must NOT render.
  assert_contains "Test 6" "ingressClassName: .\"alb\"|alb."  "$rendered"
  assert_absent   "Test 6" "ingressClassName: .\"nginx\"|nginx\." "$rendered"
fi

# ── Fail cases (expected to fail) ─────────────────────────────────────────────

# Helper: assert that a command fails (exit code != 0).
assert_fails() {   # $1: label  $2: values-file  $3: "lint"|"template"
  local label="$1" tc="$2" mode="$3" rc=0
  if [[ "$mode" == "lint" ]]; then
    run_lint  "$tc" >/dev/null 2>&1 || rc=$?
  else
    run_template "$tc" >/dev/null 2>&1 || rc=$?
  fi
  if [[ "$rc" -ne 0 ]]; then
    pass "$label: correctly rejected (exit $rc)"
  else
    fail_msg "$label: expected failure but command SUCCEEDED"
  fi
}

if should_run "f1"; then
  section "Fail case 1 – missing ingress.type"
  assert_fails "Fail 1" "${TEST_DIR}/fail-cases/fail-case-1-missing-type.yaml" "lint"
fi

if should_run "f2"; then
  section "Fail case 2 – missing ingress.ingressClassName"
  assert_fails "Fail 2" "${TEST_DIR}/fail-cases/fail-case-2-missing-ingressclassname.yaml" "lint"
fi

if should_run "f3"; then
  section "Fail case 3 – missing ingress.rules"
  assert_fails "Fail 3" "${TEST_DIR}/fail-cases/fail-case-3-missing-rules.yaml" "lint"
fi

if should_run "f4"; then
  section "Fail case 4 – empty rules list"
  assert_fails "Fail 4" "${TEST_DIR}/fail-cases/fail-case-4-empty-rules.yaml" "lint"
fi

if should_run "f5"; then
  section "Fail case 5 – empty host in rule"
  assert_fails "Fail 5" "${TEST_DIR}/fail-cases/fail-case-5-empty-host.yaml" "template"
fi

# ── Summary ───────────────────────────────────────────────────────────────────
separator
if [ "${#FAILED_TESTS[@]}" -eq 0 ]; then
  echo -e "${GREEN}All tests passed.${NC}"
  exit 0
else
  echo -e "${RED}${#FAILED_TESTS[@]} test(s) FAILED:${NC}"
  for t in "${FAILED_TESTS[@]}"; do
    echo -e "  ${RED}✗${NC} $t"
  done
  exit 1
fi

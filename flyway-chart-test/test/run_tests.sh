#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# test/run_tests.sh
#
# Prerequisites: docker, kind, kubectl, helm
#
# Usage:
#   CHART_PATH=/path/to/chart bash test/run_tests.sh [OPTIONS] [TEST_IDS...]
#
# Options:
#   --skip-build      reuse existing local image (local/flyway-custom:test)
#   --skip-cluster    reuse existing kind cluster
#   --skip-teardown   do not delete the cluster after the run
#
# Test selection (run only specific tests by number):
#   bash test/run_tests.sh 1 3
#   bash test/run_tests.sh --skip-teardown 2 4
#
# If no TEST_IDS are given, all tests are run.
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# ── Configuration ─────────────────────────────────────────────────────────────
KIND_CLUSTER_NAME="flyway-chart-test"
NS="flyway-chart-test"
CHART_PATH="${CHART_PATH:-${ROOT_DIR}/../chart}"
DEPLOY_TIMEOUT="300s"

SKIP_BUILD=false
SKIP_CLUSTER=false
SKIP_TEARDOWN=false

CUSTOM_IMAGE="local/flyway-custom:test"
INFRA_IMAGES=(
  "postgres:16-alpine"
  "flyway/flyway:latest"
  "busybox:latest"
)

# ── Argument parsing ──────────────────────────────────────────────────────────
SELECTED_TESTS=()   # empty = run all

for arg in "$@"; do
  case "$arg" in
    --skip-build)    SKIP_BUILD=true ;;
    --skip-cluster)  SKIP_CLUSTER=true ;;
    --skip-teardown) SKIP_TEARDOWN=true ;;
    [0-9]*)          SELECTED_TESTS+=("$arg") ;;
  esac
done

should_run() {
  local id="$1"
  [ "${#SELECTED_TESTS[@]}" -eq 0 ] && return 0   # no filter → run all
  for sel in "${SELECTED_TESTS[@]}"; do
    [ "$sel" = "$id" ] && return 0
  done
  return 1
}

# ── Colors ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
pass()      { echo -e "${GREEN}[PASS]${NC} $*"; }
fail()      { echo -e "${RED}[FAIL]${NC} $*"; FAILED_TESTS+=("$*"); }
info()      { echo -e "${YELLOW}[INFO]${NC} $*"; }
section()   { echo -e "${CYAN}$*${NC}"; }
separator() { echo "────────────────────────────────────────────────────────"; }

FAILED_TESTS=()

# ── Preflight checks and setup
check_prerequisites() {
  separator; info "Checking prerequisites..."
  for cmd in docker kind kubectl helm; do
    command -v "$cmd" >/dev/null 2>&1 || { echo "ERROR: $cmd not found"; exit 1; }
  done
  [ -d "$CHART_PATH" ] || { echo "ERROR: chart not found at $CHART_PATH"; exit 1; }
  info "All prerequisites satisfied."
}

# ── Kind cluster
setup_cluster() {
  separator; info "Setting up kind cluster '${KIND_CLUSTER_NAME}'..."
  if $SKIP_CLUSTER && kind get clusters 2>/dev/null | grep -q "^${KIND_CLUSTER_NAME}$"; then
    info "Reusing existing cluster."
  else
    kind delete cluster --name "${KIND_CLUSTER_NAME}" 2>/dev/null || true
    kind create cluster --name "${KIND_CLUSTER_NAME}"
  fi
  kubectl cluster-info --context "kind-${KIND_CLUSTER_NAME}" >/dev/null
  info "Cluster ready."
}

# ── Images
build_and_load_images() {
  separator; info "Building and loading all images into kind..."

  if $SKIP_BUILD; then
    info "--skip-build: reusing existing image ${CUSTOM_IMAGE}."
  else
    info "Building ${CUSTOM_IMAGE}..."
    docker build -t "${CUSTOM_IMAGE}" "${ROOT_DIR}/docker"
  fi
  kind load docker-image "${CUSTOM_IMAGE}" --name "${KIND_CLUSTER_NAME}"

  for img in "${INFRA_IMAGES[@]}"; do
    info "Pulling ${img}..."
    docker pull "${img}"
    kind load docker-image "${img}" --name "${KIND_CLUSTER_NAME}"
  done
  info "All images loaded."
}

# ── Infrastructure
setup_infrastructure() {
  separator; info "Deploying infrastructure..."
  kubectl create namespace "${NS}" --dry-run=client -o yaml | kubectl apply -f -
  kubectl apply -f "${ROOT_DIR}/k8s/postgres.yaml"
  kubectl apply -f "${ROOT_DIR}/configmaps/flyway-migrations-configmap.yaml"
  info "Waiting for PostgreSQL..."
  kubectl wait deployment/postgres \
    --for=condition=available --timeout=90s -n "${NS}" \
    || { echo "ERROR: PostgreSQL not ready"; exit 1; }
  pass "PostgreSQL ready"
}

# ── Helm helpers
helm_install() {
  local release="$1"
  local values_file="$2"
  info "Installing helm release '${release}'..."
  helm upgrade --install "${release}" "${CHART_PATH}" \
    -f "${ROOT_DIR}/helm-values/values-base.yaml" \
    -f "${ROOT_DIR}/helm-values/${values_file}" \
    --namespace "${NS}" \
    --timeout "${DEPLOY_TIMEOUT}" 2>&1 || return 1

  info "Waiting for rollout of '${release}'..."
  kubectl rollout status deployment/"${release}" \
    -n "${NS}" --timeout="${DEPLOY_TIMEOUT}" 2>&1 || return 1
}

helm_uninstall() {
  local release="$1"
  helm uninstall "${release}" --namespace "${NS}" --ignore-not-found 2>/dev/null || true
  kubectl wait pods -l "app.kubernetes.io/name=${release}" \
    --for=delete --timeout=60s -n "${NS}" 2>/dev/null || true
}

flyway_init_logs() {
  local release="$1"
  local pod
  pod=$(kubectl get pods -n "${NS}" -l "app.kubernetes.io/name=${release}" \
    -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)
  [ -z "$pod" ] && { echo "(no pod found for ${release})"; return; }
  kubectl logs "${pod}" -n "${NS}" -c migrate-db --tail=100 2>/dev/null || true
}

# ── Flyway DB check
# Runs a psql query against the postgres pod and prints the result.
# Used after each test to inspect flyway_schema_history.
verify_flyway_history() {
  local label="$1"

  section "  DB verification — flyway_schema_history (${label})"

  local pg_pod
  pg_pod=$(kubectl get pods -n "${NS}" -l "app=postgres" \
    -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)

  if [ -z "$pg_pod" ]; then
    info "No postgres pod found — skipping DB verification."
    return
  fi

  local result
  result=$(kubectl exec "${pg_pod}" -n "${NS}" -- \
    psql -U flyway -d testdb -c "
SELECT * FROM flyway_schema_history ORDER BY installed_rank;
" 2>&1) || {
      info "flyway_schema_history not found (migration may not have run yet)."
      return
    }

  echo "${result}"

  # Assert at least one successful migration row
  local success_count
  success_count=$(kubectl exec "${pg_pod}" -n "${NS}" -- \
    psql -U flyway -d testdb -tAc \
    "SELECT COUNT(*) FROM flyway_schema_history WHERE success = true;" 2>/dev/null || echo "0")

  if [ "${success_count}" -gt 0 ]; then
    pass "DB check (${label}) — ${success_count} successful migration(s) in flyway_schema_history"
  else
    fail "DB check (${label}) — no successful migrations found in flyway_schema_history"
  fi

  # Also print any failed rows if present
  local failed_count
  failed_count=$(kubectl exec "${pg_pod}" -n "${NS}" -- \
    psql -U flyway -d testdb -tAc \
    "SELECT COUNT(*) FROM flyway_schema_history WHERE success = false;" 2>/dev/null || echo "0")

  if [ "${failed_count}" -gt 0 ]; then
    info "WARNING: ${failed_count} failed migration(s) found in flyway_schema_history"
    kubectl exec "${pg_pod}" -n "${NS}" -- \
      psql -U flyway -d testdb -c \
      "SELECT installed_rank, version, script, success FROM flyway_schema_history WHERE success = false;" \
      2>/dev/null || true
  fi
}

assert_migration_count() {
  local label="$1"
  local expected="$2"

  local pg_pod
  pg_pod=$(kubectl get pods -n "${NS}" -l "app=postgres" \
    -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)
  [ -z "$pg_pod" ] && { fail "assert_migration_count (${label}) — no postgres pod"; return; }

  local actual
  actual=$(kubectl exec "${pg_pod}" -n "${NS}" -- \
    psql -U flyway -d testdb -tAc \
    "SELECT COUNT(*) FROM flyway_schema_history WHERE success = true;" 2>/dev/null || echo "0")

  if [ "${actual}" -eq "${expected}" ]; then
    pass "DB check (${label}) — expected ${expected} migration(s), got ${actual} ✓"
  else
    fail "DB check (${label}) — expected ${expected} migration(s), got ${actual}"
  fi
}

# Verifies that a column exists on a given table.
# Usage: assert_column_exists <label> <table> <column>
assert_column_exists() {
  local label="$1"
  local table="$2"
  local column="$3"

  local pg_pod
  pg_pod=$(kubectl get pods -n "${NS}" -l "app=postgres" \
    -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)
  [ -z "$pg_pod" ] && { fail "assert_column_exists (${label}) — no postgres pod"; return; }

  local count
  count=$(kubectl exec "${pg_pod}" -n "${NS}" -- \
    psql -U flyway -d testdb -tAc \
    "SELECT COUNT(*) FROM information_schema.columns
     WHERE table_name='${table}' AND column_name='${column}';" 2>/dev/null || echo "0")

  if [ "${count}" -eq 1 ]; then
    pass "DB check (${label}) — column '${column}' exists on table '${table}' ✓"
  else
    fail "DB check (${label}) — column '${column}' not found on table '${table}'"
  fi
}

# Verifies that a foreign key constraint exists between two tables.
# Usage: assert_fk_exists <label> <fk_constraint_name>
assert_fk_exists() {
  local label="$1"
  local constraint_name="$2"

  local pg_pod
  pg_pod=$(kubectl get pods -n "${NS}" -l "app=postgres" \
    -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)
  [ -z "$pg_pod" ] && { fail "assert_fk_exists (${label}) — no postgres pod"; return; }

  local count
  count=$(kubectl exec "${pg_pod}" -n "${NS}" -- \
    psql -U flyway -d testdb -tAc \
    "SELECT COUNT(*) FROM information_schema.table_constraints
     WHERE constraint_type = 'FOREIGN KEY'
       AND constraint_name = '${constraint_name}';" 2>/dev/null || echo "0")

  if [ "${count}" -eq 1 ]; then
    pass "DB check (${label}) — FK constraint '${constraint_name}' exists ✓"
  else
    fail "DB check (${label}) — FK constraint '${constraint_name}' not found"
  fi
}

# Drops flyway_schema_history and all test tables so each test starts clean
reset_db() {
  local pg_pod
  pg_pod=$(kubectl get pods -n "${NS}" -l "app=postgres" \
    -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)
  [ -z "$pg_pod" ] && return

  info "Resetting DB state for next test..."
  kubectl exec "${pg_pod}" -n "${NS}" -- \
    psql -U flyway -d testdb -c "
      DROP TABLE IF EXISTS flyway_schema_history CASCADE;
      DROP TABLE IF EXISTS users    CASCADE;
      DROP TABLE IF EXISTS tenant   CASCADE;
      DROP TABLE IF EXISTS product  CASCADE;
      DROP TABLE IF EXISTS orders   CASCADE;
      DROP TABLE IF EXISTS account  CASCADE;
    " >/dev/null 2>&1 || true
}

# ── Test cases ────────────────────────────────────────────────────────────────
run_test_1() {
  separator; info "TEST 1: migrationsConfigmap (official image, ConfigMap volume)"
  local release="test-flyway-configmap"
  helm_uninstall "${release}"
  reset_db

  if helm_install "${release}" "test-case-1-configmap.yaml"; then
    logs=$(flyway_init_logs "${release}")
    echo "${logs}"
    if echo "${logs}" | grep -qE "Successfully applied|Schema.*up to date"; then
      pass "TEST 1 — migrations from ConfigMap applied"
    else
      fail "TEST 1 — Flyway did not confirm success"
    fi
    verify_flyway_history "TEST 1"
  else
    fail "TEST 1 — helm install failed or timed out"
  fi
  helm_uninstall "${release}"
}

run_test_2() {
  separator; info "TEST 2: migrationPaths — directories (custom image)"
  local release="test-flyway-paths-dirs"
  helm_uninstall "${release}"
  reset_db

  if helm_install "${release}" "test-case-2-paths-dirs.yaml"; then
    logs=$(flyway_init_logs "${release}")
    echo "${logs}"
    if echo "${logs}" | grep -q "INTERNAL_FLYWAY_MIGRATIONS_PATHS found"; then
      pass "TEST 2 — INTERNAL_FLYWAY_MIGRATIONS_PATHS detected"
    else
      fail "TEST 2 — INTERNAL_FLYWAY_MIGRATIONS_PATHS not found in logs"
    fi
    if echo "${logs}" | grep -qE "Successfully applied|Schema.*up to date"; then
      pass "TEST 2 — migrations from directory paths applied"
    else
      fail "TEST 2 — Flyway did not confirm success"
    fi
    verify_flyway_history "TEST 2"
  else
    fail "TEST 2 — helm install failed or timed out"
  fi
  helm_uninstall "${release}"
}

run_test_3() {
  separator; info "TEST 3: migrationPaths — single file (custom image)"
  local release="test-flyway-paths-file"
  helm_uninstall "${release}"
  reset_db

  if helm_install "${release}" "test-case-3-paths-file.yaml"; then
    logs=$(flyway_init_logs "${release}")
    echo "${logs}"
    if echo "${logs}" | grep -q "INTERNAL_FLYWAY_MIGRATIONS_PATHS found"; then
      pass "TEST 3 — INTERNAL_FLYWAY_MIGRATIONS_PATHS detected"
    else
      fail "TEST 3 — INTERNAL_FLYWAY_MIGRATIONS_PATHS not found in logs"
    fi
    if echo "${logs}" | grep -qE "Successfully applied|Schema.*up to date"; then
      pass "TEST 3 — migrations from single file path applied"
    else
      fail "TEST 3 — Flyway did not confirm success"
    fi
    verify_flyway_history "TEST 3"
  else
    fail "TEST 3 — helm install failed or timed out"
  fi
  helm_uninstall "${release}"
}

run_test_4() {
  separator; info "TEST 4: repair-and-migrate action (custom image)"
  local release="test-flyway-repair-migrate"
  helm_uninstall "${release}"
  reset_db

  if helm_install "${release}" "test-case-4-repair-migrate.yaml"; then
    logs=$(flyway_init_logs "${release}")
    echo "${logs}"
    if echo "${logs}" | grep -q "Starting Flyway repair"; then
      pass "TEST 4 — repair action executed"
    else
      fail "TEST 4 — repair not found in logs"
    fi
    if echo "${logs}" | grep -q "Starting Flyway migration\|Starting Flyway repair && migration"; then
      pass "TEST 4 — migrate action executed after repair"
    else
      fail "TEST 4 — migrate not found in logs"
    fi
    verify_flyway_history "TEST 4"
  else
    fail "TEST 4 — helm install failed or timed out"
  fi
  helm_uninstall "${release}"
}

run_test_5() {
  separator
  info "TEST 5: incremental migrations — two successive deploys on the same DB"
  info "  Step 1: initial deploy, tenant only"
  info "          → V1 (create tenant), V2 (add email)"
  info "  Step 2: upgrade, adds product domain"
  info "          → V3 (create product), V4 (FK product→tenant from step 1)"
  local release="test-flyway-incremental"
  helm_uninstall "${release}"
  reset_db

  # ── Step 1: first install — tenant migrations only (V1, V2) ─────────────────
  section "  [TEST 5 / step 1] First deploy — tenant migrations"
  if helm_install "${release}" "test-case-5-step1.yaml"; then
    logs=$(flyway_init_logs "${release}")
    echo "${logs}"
    if echo "${logs}" | grep -qE "Successfully applied|Schema.*up to date"; then
      pass "TEST 5 step 1 — tenant migrations applied"
    else
      fail "TEST 5 step 1 — Flyway did not confirm success"
    fi
    verify_flyway_history "TEST 5 / step 1"
    assert_migration_count "TEST 5 / step 1" 2        # V1 + V2
    assert_column_exists   "TEST 5 / step 1" "tenant" "email"
  else
    fail "TEST 5 step 1 — helm install failed or timed out"
    helm_uninstall "${release}"
    return
  fi

  # ── Step 2: helm upgrade — adds product migrations (V3, V4) ─────────────────
  # No reset_db: V1+V2 must remain in flyway_schema_history.
  # V4 adds a FK from product.tenant_id → tenant.id, proving that the product
  # migration can reference a table created in a previous deploy (step 1).
  section "  [TEST 5 / step 2] Upgrade — adding product migrations"
  if helm_install "${release}" "test-case-5-step2.yaml"; then
    logs=$(flyway_init_logs "${release}")
    echo "${logs}"
    if echo "${logs}" | grep -qE "Successfully applied|Schema.*up to date"; then
      pass "TEST 5 step 2 — product migrations applied"
    else
      fail "TEST 5 step 2 — Flyway did not confirm success"
    fi
    verify_flyway_history "TEST 5 / step 2"
    assert_migration_count "TEST 5 / step 2" 4        # V1 + V2 + V3 + V4
    assert_column_exists   "TEST 5 / step 2" "product" "tenant_id"
    assert_fk_exists       "TEST 5 / step 2" "fk_product_tenant"
  else
    fail "TEST 5 step 2 — helm upgrade failed or timed out"
  fi

  helm_uninstall "${release}"
}

# ── Teardown
teardown() {
  separator; info "Teardown..."
  if $SKIP_TEARDOWN; then
    info "--skip-teardown: cluster left running."
    info "  kubectl config use-context kind-${KIND_CLUSTER_NAME}"
    info "  kind delete cluster --name ${KIND_CLUSTER_NAME}  # to clean up manually"
    return
  fi
  kind delete cluster --name "${KIND_CLUSTER_NAME}" 2>/dev/null || true
  info "Cluster deleted."
}
trap teardown EXIT

# ── Main
separator
echo "  Flyway Helm Chart — Integration Test Suite"
if [ "${#SELECTED_TESTS[@]}" -gt 0 ]; then
  echo "  Running tests: ${SELECTED_TESTS[*]}"
fi
separator

check_prerequisites
setup_cluster
build_and_load_images
setup_infrastructure

should_run 1 && run_test_1
should_run 2 && run_test_2
should_run 3 && run_test_3
should_run 4 && run_test_4
should_run 5 && run_test_5

separator
if [ ${#FAILED_TESTS[@]} -eq 0 ]; then
  echo -e "${GREEN}All tests passed.${NC}"
else
  echo -e "${RED}Failed tests:${NC}"
  for t in "${FAILED_TESTS[@]}"; do echo "  - $t"; done
  exit 1
fi
separator

#!/usr/bin/env bash
# filepath: /Users/manuelm/Documents/repo/PagoPA/EKS Charts/interop-eks-microservice-chart/tests/external_secrets_operator/run_tests.sh

set -u

CHART_PATH="${CHART_PATH:-charts/interop-eks-microservice-chart}"
BASE_VALUES="${BASE_VALUES:-tests/external_secrets_operator/values-base.yaml}"
SUCCESS_DIR="${SUCCESS_DIR:-tests/external_secrets_operator/success}"
FAILURE_DIR="${FAILURE_DIR:-tests/external_secrets_operator/failure}"

TOTAL=0
PASSED=0
FAILED=0

run_case() {
  local expected="$1" # success | failure
  local file="$2"

  TOTAL=$((TOTAL + 1))
  echo "==> [$expected] $(basename "$file")"

  if helm template test "$CHART_PATH" -f "$BASE_VALUES" -f "$file" >/tmp/helm-test.out 2>/tmp/helm-test.err; then
    if [ "$expected" = "success" ]; then
      echo "PASS"
      PASSED=$((PASSED + 1))
    else
      echo "FAIL (expected failure, got success)"
      FAILED=$((FAILED + 1))
      sed 's/^/  /' /tmp/helm-test.out
    fi
  else
    if [ "$expected" = "failure" ]; then
      echo "PASS"
      PASSED=$((PASSED + 1))
    else
      echo "FAIL (expected success, got failure)"
      FAILED=$((FAILED + 1))
      sed 's/^/  /' /tmp/helm-test.err
    fi
  fi

  echo
}

if [ ! -f "$BASE_VALUES" ]; then
  echo "Base values file not found: $BASE_VALUES"
  exit 1
fi

if [ ! -d "$SUCCESS_DIR" ] && [ ! -d "$FAILURE_DIR" ]; then
  echo "No test directories found."
  exit 1
fi

# Success cases
if [ -d "$SUCCESS_DIR" ]; then
  for f in "$SUCCESS_DIR"/*.yaml; do
    [ -e "$f" ] || continue
    run_case "success" "$f"
  done
fi

# Failure cases
if [ -d "$FAILURE_DIR" ]; then
  for f in "$FAILURE_DIR"/*.yaml; do
    [ -e "$f" ] || continue
    run_case "failure" "$f"
  done
fi

echo "Summary: total=$TOTAL passed=$PASSED failed=$FAILED"

if [ "$FAILED" -gt 0 ]; then
  exit 1
fi

exit 0
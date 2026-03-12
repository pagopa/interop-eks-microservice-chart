CHART_PATH=./charts/interop-eks-microservice-chart bash tests/flyway-chart-test/scripts/run_tests.sh

# Example: Reuse existing cluster and docker images already built and loaded on the cluster
CHART_PATH=./charts/interop-eks-microservice-chart bash  scripts/run_tests.sh --skip-cluster --skip-build
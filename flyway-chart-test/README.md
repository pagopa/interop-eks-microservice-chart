CHART_PATH=./charts/interop-eks-microservice-chart bash flyway-chart-test/test/run_tests.sh

# Ricicla cluster e immagine già buildati:
bash test/run_tests.sh --skip-cluster --skip-build
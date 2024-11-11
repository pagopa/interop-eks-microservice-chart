# !/bin/bash
set -euo pipefail

#helm dep up

helm template mychart ../../charts/interop-eks-microservice-chart --debug  -f ./values-service.yaml
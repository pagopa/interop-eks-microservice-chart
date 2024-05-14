# interop-eks-microservice-chart

This chart is used to standardize K8s microservice manifests for the [PagoPA Interop project](https://www.interop.pagopa.it) running on AWS EKS.

Inspired by https://github.com/pagopa/aks-microservice-chart-blueprint (many thanks to ...)

## Usage

### Chart setup

```bash
helm repo add interop-eks-microservice-chart https://pagopa.github.io/interop-eks-microservice-chart
helm repo update
```

From your project directory, create a folder for the chart and a basic `Chart.yaml`:

```bash
mkdir helm && cd helm

cat <<EOF > Chart.yaml
apiVersion: v2
name: my-microservice
description: My microservice description
type: application
version: 1.0.0
appVersion: 1.0.0
dependencies:
- name: interop-eks-microservice-chart
  version: 1.0.0
  repository: "https://pagopa.github.io/interop-eks-microservice-chart"
EOF
```

> **_NOTE:_** in the previous file, set the chart's version (`dependencies[0].version`) to the [latest release](https://github.com/pagopa/interop-eks-microservice-chart/releases).

Build the chart:

```bash
helm dep build
```

## Features

For a complete list of values, see the chart [README](https://github.com/pagopa/interop-eks-microservice-chart/blob/main/charts/interop-eks-microservice-chart/README.md).

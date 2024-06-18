# interop-eks-microservice-chart

This chart is used to standardize K8s microservice manifests for the [PagoPA Interop project](https://www.interop.pagopa.it) running on AWS EKS.

Inspired by https://github.com/pagopa/aks-microservice-chart-blueprint (many thanks to ...)

## Usage

### Chart setup 🔧

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

> **_NOTE:_** set the chart's version (`dependencies[0].version`) to the [latest release](https://github.com/pagopa/interop-eks-microservice-chart/releases).

Build the chart:

```bash
helm dep build
```

### Generate K8s manifests

## Features ✨

For a complete list of values, see the chart [README](https://github.com/pagopa/interop-eks-microservice-chart/blob/main/charts/interop-eks-microservice-chart/README.md).

### Environment Variables

⚠️  Do NOT use this method for secret/sensitive values, read the `Secrets` section! ⚠️

There are two ways to set environment variables:

1. `configmap` field
2. `env` field
3. referencing other configmaps with envFromConfigmaps

In general, variables used in application logic (e.g. BUCKET_NAME) should use the `configmap` field, while "system" variables (e.g. PORT) the `env` field.

Example:
```yaml
configmap:
  BUCKET_NAME: "foo"
  SCHEMA_NAME: "bar"

env:
  PORT: 3000 
```

### Secrets

Secrets/sensitive values must be stored in a K8s Secret object, and then referenced using the chart's `envFromSecrets` field:

Example:
```yaml
envFromSecrets:
  DB_PASSWORD: "db_secret.dbPassword"
```
where DB_PASSWORD will be the environment variable name, db_secret is the name of the secret and dbPassword is a secret's field.


# ingress-nginx test suite

Offline test suite for the `ingress-nginx` template
(`charts/interop-eks-microservice-chart/templates/ingress-nginx.yaml`).

No Kubernetes cluster is required – tests rely only on `helm lint` and
`helm template` to validate schema constraints and rendered output.

## Directory layout

```
tests/ingress-nginx/
├── helm-values/
│   ├── values-base.yaml                       shared base values (service, deployment, …)
│   ├── test-case-1-single-rule.yaml           single host, single path (Prefix)
│   ├── test-case-2-multi-path-single-host.yaml  same host, two paths → grouped into one rule entry
│   ├── test-case-3-multi-host.yaml            two different hosts → two separate rule entries
│   ├── test-case-4-annotations.yaml           custom nginx annotations + ImplementationSpecific pathType
│   ├── test-case-5-ingress-disabled.yaml      ingress.create=false → no Ingress resource rendered
│   └── test-case-6-alb-no-rules.yaml          type=alb, rules absent → valid (rules optional for alb)
├── fail-cases/
│   ├── fail-case-1-missing-type.yaml          create=true but ingress.type absent → schema error
│   ├── fail-case-2-missing-ingressclassname.yaml  ingressClassName absent → schema error
│   ├── fail-case-3-missing-rules.yaml         rules absent → schema error
│   ├── fail-case-4-empty-rules.yaml           rules: [] (minItems=1 violated) → schema error
│   └── fail-case-5-empty-host.yaml            rule with host=""  → fail() at render time
└── scripts/
    └── run_tests.sh                            test runner
```

## Running the tests

From the repository root:

```bash
# Run all tests
bash tests/ingress-nginx/scripts/run_tests.sh

# Run only specific positive tests (1, 3) and one fail-case (f2)
bash tests/ingress-nginx/scripts/run_tests.sh 1 3 f2

# Run all fail-cases only
bash tests/ingress-nginx/scripts/run_tests.sh f

# Override chart path
CHART=/path/to/chart bash tests/ingress-nginx/scripts/run_tests.sh
```

Prerequisites: `helm` in `$PATH` and chart dependencies fetched
(`helm dependency update charts/interop-eks-microservice-chart`).

## Test descriptions

| ID  | File                                   | What is validated |
|-----|----------------------------------------|--------------------|
| 1   | test-case-1-single-rule.yaml           | Ingress rendered with correct `ingressClassName`, `host`, `path`, `pathType`; exactly one `- host:` entry |
| 2   | test-case-2-multi-path-single-host.yaml | Helper groups two rules for the same host into a single `- host:` block with two `paths` entries |
| 3   | test-case-3-multi-host.yaml            | Hosts are rendered as two separate `- host:` entries |
| 4   | test-case-4-annotations.yaml           | `metadata.annotations` block is populated; `ImplementationSpecific` pathType is accepted |
| 5   | test-case-5-ingress-disabled.yaml      | No `kind: Ingress` appears in the rendered manifests |
| f1  | fail-case-1-missing-type.yaml          | `helm lint` fails (schema: `type` required when `create=true`) |
| f2  | fail-case-2-missing-ingressclassname.yaml | `helm lint` fails (schema: `ingressClassName` required) |
| f3  | fail-case-3-missing-rules.yaml         | `helm lint` fails (schema: `rules` required) |
| f4  | fail-case-4-empty-rules.yaml           | `helm lint` fails (schema: `rules` minItems=1) |
| f5  | fail-case-5-empty-host.yaml            | `helm template` fails (helper `fail()`: empty host) |

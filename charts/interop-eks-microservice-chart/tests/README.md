# Test Suite per Helm Chart

Questa directory contiene una test suite per la Chart Helm `interop-eks-microservice-chart`.

## 📋 Prerequisiti

Per eseguire i test è necessario installare il plugin `helm-unittest`:

```bash
helm plugin install https://github.com/helm-unittest/helm-unittest.git
```

## 🧪 Test Disponibili

### File di Test

| File | Descrizione | Template Testati |
|------|-------------|------------------|
| `deployment_test.yaml` | Test per deployment backend Node.js | `deployment.yaml` |
| `deployment_frontend_test.yaml` | Test per deployment frontend | `deployment.frontend.yaml` |
| `service_test.yaml` | Test per il Service Kubernetes | `service.yaml` |
| `serviceaccount_test.yaml` | Test per ServiceAccount e Roles | `serviceaccount.yaml`, `roles.yaml` |
| `configmap_test.yaml` | Test per ConfigMap backend e frontend | `configmap.yaml`, `configmap.frontend.yaml` |
| `ingress_test.yaml` | Test per Ingress e TargetGroupBinding | `ingress.yaml`, `targetGroupBinding.yaml` |
| `scaledobject_test.yaml` | Test per autoscaling KEDA | `scaledobject.yaml` |

### Aree Coperte dai Test

#### Deployment Backend
- ✅ Creazione deployment base con configurazione minima
- ✅ Utilizzo di digest immagini
- ✅ Configurazione risorse (CPU/memoria)
- ✅ Variabili d'ambiente da ConfigMap e Secret
- ✅ Liveness e readiness probes
- ✅ Annotazioni per rollout
- ✅ Security context
- ✅ Strategia di rolling update

#### Deployment Frontend
- ✅ Creazione deployment frontend specifico
- ✅ Rendering condizionale basato su techStack
- ✅ Configurazione container Nginx
- ✅ Mount di ConfigMap frontend
- ✅ Probes HTTP per frontend
- ✅ Label e annotazioni specifiche
- ✅ Security context

#### Service
- ✅ Creazione Service ClusterIP e NodePort
- ✅ Configurazione porte (main, monitoring, management)
- ✅ Porte aggiuntive personalizzate
- ✅ Selector labels corretti
- ✅ Abilitazione/disabilitazione porte monitoring/management
- ✅ Annotazioni personalizzate

#### ServiceAccount & Roles
- ✅ Creazione ServiceAccount
- ✅ Annotazione IAM role ARN per AWS
- ✅ Creazione Role RBAC
- ✅ Creazione RoleBinding
- ✅ Gestione di ruoli multipli
- ✅ Label personalizzate

#### ConfigMap
- ✅ ConfigMap backend con dati
- ✅ ConfigMap frontend per applicazioni React/Vue
- ✅ Rendering condizionale
- ✅ Gestione valori numerici e booleani
- ✅ Template values
- ✅ Label e annotazioni personalizzate

#### Ingress & TargetGroupBinding
- ✅ Ingress con AWS ALB
- ✅ Annotazioni ALB
- ✅ Regole ingress con host e path
- ✅ TargetGroupBinding con ARN
- ✅ Target type (IP vs instance)
- ✅ Healthcheck configuration
- ✅ IP address type

#### KEDA Autoscaling
- ✅ ScaledObject configuration
- ✅ Min/max replica count
- ✅ Polling interval e cooldown
- ✅ Trigger Prometheus
- ✅ Trigger CPU e Memory
- ✅ Trigger AWS SQS
- ✅ Trigger multipli
- ✅ ScaleTargetRef corretto

## 🚀 Esecuzione dei Test

### Comandi Base

```bash
# Tutti i test
helm unittest charts/interop-eks-microservice-chart

# Con output verbose
helm unittest -v charts/interop-eks-microservice-chart

# Con aggiornamento snapshot
helm unittest -u charts/interop-eks-microservice-chart
```

### Test Specifici

```bash
# Test deployment backend
helm unittest -f 'tests/deployment_test.yaml' charts/interop-eks-microservice-chart

# Test deployment frontend
helm unittest -f 'tests/deployment_frontend_test.yaml' charts/interop-eks-microservice-chart

# Test service
helm unittest -f 'tests/service_test.yaml' charts/interop-eks-microservice-chart

# Test serviceaccount e roles
helm unittest -f 'tests/serviceaccount_test.yaml' charts/interop-eks-microservice-chart

# Test configmap
helm unittest -f 'tests/configmap_test.yaml' charts/interop-eks-microservice-chart

# Test ingress e target group binding
helm unittest -f 'tests/ingress_test.yaml' charts/interop-eks-microservice-chart

# Test KEDA autoscaling
helm unittest -f 'tests/scaledobject_test.yaml' charts/interop-eks-microservice-chart
```

### Validazione Chart

```bash
# Lint della chart
helm lint charts/interop-eks-microservice-chart

# Template rendering con valori di esempio
helm template test-release charts/interop-eks-microservice-chart \
  -f tests/nodejs_generic_service/values.yaml

# Validazione completa (lint + test)
helm lint charts/interop-eks-microservice-chart && \
helm unittest charts/interop-eks-microservice-chart
```

## 📊 Output dei Test

Un esempio di output atteso:

```
### Chart [ interop-eks-microservice-chart ] charts/interop-eks-microservice-chart

 PASS  test deployment backend	charts/interop-eks-microservice-chart/tests/deployment_test.yaml
 PASS  test deployment frontend	charts/interop-eks-microservice-chart/tests/deployment_frontend_test.yaml
 PASS  test service	charts/interop-eks-microservice-chart/tests/service_test.yaml
 PASS  test serviceaccount and roles	charts/interop-eks-microservice-chart/tests/serviceaccount_test.yaml
 PASS  test configmaps	charts/interop-eks-microservice-chart/tests/configmap_test.yaml
 PASS  test ingress and target group binding	charts/interop-eks-microservice-chart/tests/ingress_test.yaml
 PASS  test KEDA autoscaling	charts/interop-eks-microservice-chart/tests/scaledobject_test.yaml

Charts:      1 passed, 1 total
Test Suites: 7 passed, 7 total
Tests:       XX passed, XX total
Snapshot:    0 passed, 0 total
Time:        X.XXXs
```

## 🔧 Aggiunta di Nuovi Test

Per aggiungere nuovi test:

1. Crea un nuovo file `*_test.yaml` nella directory `tests/`
2. Segui la struttura:

```yaml
suite: descrizione della suite
templates:
  - template-da-testare.yaml
tests:
  - it: descrizione del test
    set:
      # valori da passare alla chart
    asserts:
      - isKind:
          of: TipoRisorsa
      - equal:
          path: percorso.nel.manifest
          value: valore-atteso
```

3. Esegui il test:

```bash
helm unittest charts/interop-eks-microservice-chart
```

## 📚 Riferimenti

- [Helm Unittest Plugin](https://github.com/helm-unittest/helm-unittest)
- [Helm Testing Best Practices](https://helm.sh/docs/topics/chart_tests/)
- [Documentazione Chart](../README.md)

## 🤝 Contribuire

Quando modifichi i template della chart:

1. Aggiorna o aggiungi i test corrispondenti
2. Esegui il lint e i test per verificare che tutto funzioni:
   ```bash
   helm lint charts/interop-eks-microservice-chart
   helm unittest charts/interop-eks-microservice-chart
   ```
3. Assicurati che tutti i test passino prima di fare commit

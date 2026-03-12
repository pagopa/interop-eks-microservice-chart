
# interop-eks-microservice-chart

![Version: 1.37.0](https://img.shields.io/badge/Version-1.37.0-informational?style=flat-square) ![AppVersion: 1.0.0](https://img.shields.io/badge/AppVersion-1.0.0-informational?style=flat-square)

A Helm chart for PagoPa Interop Microservices

## Values

The following table lists the configurable parameters of the Interop-eks-microservice-chart chart and their default values.

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| autoscaling.keda | object | `{"cooldownPeriod":null,"create":false,"maxReplicaCount":null,"minReplicaCount":null,"pollingInterval":null,"triggers":null}` | KEDA autoscaling configuration |
| autoscaling.keda.cooldownPeriod | int | `nil` | cooldown period in seconds |
| autoscaling.keda.create | bool | `false` | Enable KEDA autoscaling |
| autoscaling.keda.maxReplicaCount | int | `nil` | maximum replica count |
| autoscaling.keda.minReplicaCount | int | `nil` | minimum replica count |
| autoscaling.keda.pollingInterval | int | `nil` | metrics polling interval in seconds |
| autoscaling.keda.triggers | list | `nil` | triggers configuration, refer to https://keda.sh/docs/2.17/scalers/ |
| deployment.enableRolloutAnnotations | bool | `false` | Enable annotation generation for referenced configmaps and secrets |
| deployment.env | object | `nil` | List of environment variables for a container, specifying a value directly for each named variable |
| deployment.envFromConfigmaps | object | `{}` | List of environment variables for a container, specifying a key from a Configmap for each named variable (k8s equivalent of envFrom.configMapRef) |
| deployment.envFromFieldRef | object | `{}` | List of pod fields used as values for environment variablesenvironment variables for a container, specifying a key from a Secret for each named variable (k8s equivalent of env.valueFrom.fieldRef.fieldPath) |
| deployment.envFromSecrets | object | `{}` | List of environment variables for a container, specifying a key from a Secret for each named variable (k8s equivalent of envFrom.secretRef) |
| deployment.flywayInitContainer.create | bool | `false` |  |
| deployment.flywayInitContainer.downloadRedshiftDriver | bool | `false` | Enable Flyway to download Redshift jdbc driver |
| deployment.flywayInitContainer.env | object | `{}` | List of environment variables for a container, specifying a value directly for each named variable |
| deployment.flywayInitContainer.envFromConfigmaps | object | `{}` | List of environment variables for a container, specifying a key from a Configmap for each named variable (k8s equivalent of envFrom.configMapRef) |
| deployment.flywayInitContainer.envFromFieldRef | object | `{}` | List of pod fields used as values for environment variablesenvironment variables for a container, specifying a key from a Secret for each named variable (k8s equivalent of env.valueFrom.fieldRef.fieldPath) |
| deployment.flywayInitContainer.envFromSecrets | object | `{}` | List of environment variables for a container, specifying a key from a Secret for each named variable (k8s equivalent of envFrom.secretRef) |
| deployment.flywayInitContainer.executeFlywayMigrate | bool | `true` | execute Flyway migrate command to apply migrations to the database |
| deployment.flywayInitContainer.executeFlywayRepair | bool | `false` | execute Flyway repair command to recompute applied migrations metadata; useful for whitespace changes. |
| deployment.flywayInitContainer.image.digest | string | `nil` | if set, overrides tag with the specified digest |
| deployment.flywayInitContainer.image.repositoryName | string | `nil` | must be set if create is true, e.g. "interop-flyway-migrations" |
| deployment.flywayInitContainer.image.repositoryPrefix | string | `nil` |  |
| deployment.flywayInitContainer.image.tag | string | `nil` | defaults to deployment image tag if not set |
| deployment.flywayInitContainer.migrationPaths | string | `nil` | List of comma separated paths to migration files or directories containing migration files (e.g. "/migrations/a_directory,v1_migration.sql,/migrations/b_directory") |
| deployment.flywayInitContainer.migrationsConfigmap | string | `nil` | Configmap with migrations |
| deployment.flywayInitContainer.version | string | `"8.2.3"` | Flyway container image version |
| deployment.image | object | `{"digest":null,"imagePullPolicy":"Always","repositoryName":null,"repositoryPrefix":null,"tag":null}` | Microservice image configuration |
| deployment.image.digest | string | `nil` | Image digest |
| deployment.image.imagePullPolicy | string | `"Always"` | Image pull policy |
| deployment.image.repositoryName | string | `nil` | Alternative image name |
| deployment.image.repositoryPrefix | string | `nil` | Image repository |
| deployment.image.tag | string | `nil` | Image tag |
| deployment.metadata.annotations | object | `nil` | Additional annotations to apply to Deployment metadata |
| deployment.metadata.labels | object | `nil` | Additional labels to apply to Deployment metadata |
| deployment.podTemplateMetadata.annotations | object | `nil` | Additional annotations to apply to Pod `spec.template.metadata` |
| deployment.podTemplateMetadata.labels | object | `nil` | Additional labels to apply to Pod `spec.template.metadata` |
| deployment.postStartHook.command | array | `nil` | Command to run in the postStart hook |
| deployment.postStartHook.create | bool | `false` | Enable postStart hook |
| deployment.preStopHookGracefulTermination.create | bool | `true` | Enable preStop hook for graceful termination |
| deployment.preStopHookGracefulTermination.durationSeconds | int | `30` | Duration in seconds for the preStop hook to complete |
| deployment.replicas | int | `nil` | Number of desired replicas for the service being deployed |
| deployment.resources | object | `{"limits":{"cpu":null,"memory":null},"requests":{"cpu":null,"memory":null}}` | K8s container resources requests and limits |
| deployment.securityContext | object | `{"allowPrivilegeEscalation":false}` | Pod securityContext, applied to main container |
| deployment.strategy | object | `{"rollingUpdate":{"maxSurge":"25%","maxUnavailable":"0%"},"type":"RollingUpdate"}` | Rollout strategy |
| enableLookup | bool | `true` | Enable Resources lookup on K8s cluster to resolve referenced values |
| externalSecrets.create | bool | `false` | Enable ExternalSecret creation |
| externalSecrets.data | list | `[]` | List of individual secret keys to sync from external secret manager |
| externalSecrets.refreshInterval | string | `"0"` | Refresh interval for the secret (e.g., "1h", "30m") |
| externalSecrets.refreshPolicy | string | `"OnChange"` | Refresh policy for the secret, allowed values: [ "OnChange", "Interval" ] |
| externalSecrets.secretStoreRef | object | `{"kind":"SecretStore","name":""}` | Reference to SecretStore or ClusterSecretStore |
| externalSecrets.targetSecret | object | `{"creationPolicy":"Merge","deletionPolicy":"Retain","name":""}` | Target Kubernetes Secret configuration |
| externalSecrets.targetSecret.creationPolicy | string | `"Merge"` | Creation policy: Owner, Orphan, Merge, None |
| externalSecrets.targetSecret.deletionPolicy | string | `"Retain"` | Deletion policy: Retain, Delete |
| externalSecrets.targetSecret.name | string | `""` | Name of the target secret (defaults to microservice name) |
| ingress.className | string | `"alb"` | ingress.create and service.targetGroupArn must be mutually exclusive. |
| ingress.create | bool | `false` | Enable K8s Ingress deployment generation |
| ingress.groupName | string | `"interop-be"` |  |
| name | string | `nil` | Name of the service that will be deployed on K8s cluster |
| namespace | string | `nil` | Namespace hosting the service that will be deployed on K8s cluster |
| service.albHealthcheck | object | `{"path":null,"port":null,"protocol":null,"successCodes":null}` | ALB healthcheck config |
| service.containerPort | string | `nil` |  |
| service.create | bool | `false` | Enable K8s Service deployment generation |
| service.enableManagement | bool | `true` | Enable container management port |
| service.enableMonitoring | bool | `true` | Enable container monitoring port |
| service.ipAddressType | string | `nil` | IP address type for the target group, allowed values: [ "ipv4", "ipv6" ] |
| service.managementPort | int | `8558` |  |
| service.monitoringPort | int | `9095` |  |
| service.portName | string | `nil` | Service port name |
| service.targetGroupArn | string | `nil` | Target Group ARN for the service, used to create a TargetGroupBinding |
| service.targetPort | string | `nil` |  |
| service.targetType | string | `nil` |  |
| service.type | enum | `"ClusterIP"` | K8s Service type, allowed values: [ "ClusterIP", "NodePort" ] |
| serviceAccount.create | bool | `true` | Enable ServiceAccount creation |
| serviceAccount.roleArn | string | `nil` | ServiceAccount roleARN |
| techStack | enum | `nil` | Defines the technology used to develop the container. The following values are allowed: [ "nodejs", "frontend"] |

## 1. Configurazione del Deployment di un MicroServizio

### 1.1. Env

#### 1.1.1. <ins>configmap - Referenziare la ConfigMap del MicroServizio
Per referenziare una chiave dalla ConfigMap dello specifico microservizio, è necessario aggiungere una coppia chiave/valore nel blocco "configmap" nel file _values.yaml_ specifico per il microservizio.
La coppia chiave/valore deve essere così definita:
* Chiave: è mappata con il nome (name) della variabile d'ambiente utilizzata dal Deployment ed, al contempo, con la chiave definita nella ConfigMap; dunque le due chiavi coincidono;
* Valore: è il valore reale associato alla chiave precedentemente definita

Dichiarando la sezione "configmap" nel file _values.yaml_ di uno specifico microservizio saranno applicati i seguenti automatismi:
* sarà creata una ConfigMap con lo stesso "name" del Deployment del microservizio;
* il campo "data" di tale ConfigMap sarà popolato con tutti le coppie chiave/valore definite in "configmap"
* nel Deployment sarà aggiunto nella sezione "env" un riferimento per ogni coppia chiave/valore definita nella ConfigMap del microservizio

Definendo la seguente configurazione d'esempio nel _values.yaml_ del microservizio, ad esempio "agreement-management" per ambiente "qa":

```
# /microservices/agreement-management/qa/values.yaml

configmap:
    ENV_FIELD_KEY: "ENV_FIELD_VALUE"
```

sarà creata una ConfigMap dedicata al microservizio e contenente i dati indicati:

```
apiVersion: v1
kind: ConfigMap
metadata:
  name: "microservice-configmap-name"
  namespace: "..."
data:
  ENV_FIELD_KEY: "ENV_FIELD_VALUE"
```

e sarà aggiunto un riferimento nel Deployment nella sezione _env_:

```
env:
  - name: ENV_FIELD_KEY
    valueFrom:
      configMapKeyRef:
        name: "microservice-configmap-name"
        key: ENV_FIELD_KEY
```

Non c'è limite al numero di variabili d'ambiente configurabili nella sezione "configmap".

#### 1.1.2. <ins>envFromConfigmaps - Referenziare una ConfigMap esterna</ins>

Per referenziare una chiave da una ConfigMap esterna, è necessario aggiungere una coppia chiave/valore nel blocco "deployment.envFromConfigmaps" nel file _values.yaml_ specifico per il microservizio.
La coppia chiave/valore deve essere così definita:
* Chiave: è mappata con il nome (name) della variabile d'ambiente utilizzata dal Deployment
* Valore: è composto da due valori separati dal carattere "."; il primo valore rappresenta il nome della ConfigMap esterna referenziata, il secondo valore è la chiave desiderata definita nella ConfigMap

Definendo la seguente configurazione d'esempio nel _values.yaml_ del microservizio, ad esempio "agreement-management" per ambiente "qa":

```
# /microservices/agreement-management/qa/values.yaml

deployment:
  envFromConfigmaps:
    CUSTOM_LABEL: "external-configmap-name.REFERENCED_LABEL"
```

sarà aggiunto un riferimento nel Deployment nella sezione _env_:

```
env:
  - name: CUSTOM_LABEL
    valueFrom:
      configMapKeyRef:
        name: "external-configmap-name"
        key: REFERENCED_LABEL
```

Non c'è limite al numero di variabili d'ambiente configurabili nella sezione "envFromConfigmaps".

#### 1.1.3. <ins>envFromSecrets - Referenziare un Secret esterno</ins>

Per referenziare una chiave da un Secret esterno è necessario aggiungere una coppia chiave/valore nel blocco "deployment.envFromSecrets" nel file _values.yaml_ specifico per il microservizio.
La coppia chiave/valore deve essere così definita:
* Chiave: è mappata con il nome (name) della variabile d'ambiente utilizzata dal Deployment
* Valore: è composto da due valori separati dal carattere "."; il primo valore rappresenta il nome del Secret esterno referenziato, il secondo valore è la chiave desiderata definita nel Secret

Definendo la seguente configurazione d'esempio nel _values.yaml_ del microservizio, ad esempio "agreement-management" per ambiente "qa":

```
# /microservices/agreement-management/qa/values.yaml

deployment:
  envFromSecrets:
    CUSTOM_LABEL: "external-secret-name.REFERENCED_LABEL"
```

sarà aggiunto un riferimento nel Deployment nella sezione _env_:

```
- name: CUSTOM_LABEL
  valueFrom:
    secretKeyRef:
        name: "external-secret-name"
        key: REFERENCED_LABEL
```

Non c'è limite al numero di variabili d'ambiente configurabili nella sezione "envFromSecrets".

#### 1.1.4 <ins>env - Definire variabili d'ambiente custom</ins>

Per definire una variabile d'ambiente custom per il Deployment è necessario aggiungere una coppia chiave/valore nel blocco "deployment.env" nel file _values.yaml_ specifico per il microservizio.
Definendo la seguente configurazione d'esempio al file _values.yaml_ del microservizio, ad esempio "agreement-management" per ambiente "qa":

```
# /microservices/agreement-management/qa/values.yaml

deployment:
  env:
    ENV_NAME: "ENV_VALUE"
```

sarà aggiunto un riferimento nel Deployment nella sezione _env_:

```
- env:
  - name: "ENV_NAME"
    value: "ENV_VALUE"
```

Non c'è limite al numero di variabili d'ambiente configurabili nella sezione "env".

#### 1.1.5 <ins>envFromFieldRef - Referenziare informazioni del Pod</ins>

Per esporre dei campi del Pod al runtime del container, è possibile utilizzare il campo "fieldRef", come da [documentazione](https://kubernetes.io/docs/concepts/workloads/pods/downward-api/#downwardapi-fieldRef) ufficiale Kubernetes.
Un campo esposto con "fieldRef" può essere referenziato dal Deployment di un microservizio, ad esempio "agreement-management" per ambiente "qa", inserendo la seguente configurazione nel file _values.yaml_ come segue:

```
# /microservices/agreement-management/qa/values.yaml

deployment:
  envFromFieldRef:
    NAMESPACE: "metadata.namespace"
```

Tale configurazione è mappata nel Deployment in questo modo:

```
env:
 - name: "NAMESPACE"
   valueFrom:
     fieldRef:
       fieldPath: "metadata.namespace"
```

Non c'è limite al numero di variabili d'ambiente configurabili nella sezione "envFromFieldRef".

### 1.2 Volumi

Di seguito sono descritte le configurazioni da aggiungere al file _values.yaml_ del microservizio per aggiungere uno o più volume e volumeMounts.

**Volumes**
Seguendo la documentazione Kubernetes ufficiale in merito ai [Volumes](https://kubernetes.io/docs/concepts/storage/volumes/), per aggiungere un volume è necessario aggiornare il file _values.yaml_ del microservizio da configurare, ad esempio "agreement-management" per ambiente "qa", utilizzando la seguente sintassi:

```
# /microservices/agreement-management/qa/values.yaml

deployment:
  volumes:
    - name: categories-index-volume
      emptyDir: {}
```

Il campo "volumes" può contenere la definizione di uno o più oggetti.

**Volume Mounts**
Per aggiungere un volumeMounts relativo ad un volume configurato, è necessario aggiornare il file _values.yaml_ del microservizio da configurare, ad esempio "agreement-management" per ambiente "qa", utilizzando la seguente sintassi:

```
# /microservices/agreement-management/qa/values.yaml

deployment:
  volumeMounts:
    - name: categories-index-volume
      mountPath: /opt/docker/index/categories
```

Il campo "volumeMounts" può contenere la definizione di uno o più oggetti.

---

## 2. FlyWay init container

Alcuni microservizi possono avere la necessità di utilizzare Flyway per la gestione di migrazioni del DB; al fine di soddisfare tale requisito, è possibile abilitare un Flyway init container aggiungendo ai _values.yaml_ la seguente configurazione, ad esempio per il servizio "agreement-management" nell'ambiente "qa":

```
# /microservices/agreement-management/qa/values.yaml

deployment:
  flywayInitContainer:
    create: true
```

Per un corretto avvio del container, è necessario che nel cluster / namespace in cui è rilasciato il microservizio siano presenti le ConfigMap ed i Secret di seguito elencati:

* ConfigMap "interop-be-db-commons" - configurazioni Db comuni, di seguito le chiavi referenziate:
  * POSTGRES_HOST
  * POSTGRES_PORT
  * POSTGRES_DB
* ConfigMap del microservizio - configurazione specifica del microservizio da rilasciare, di seguito i campi attesi nel file _values.yaml_ del microservizio:
  ```
  # /microservices/agreement-management/qa/values.yaml

  deployment:
    flywayInitContainer:
      create: true
      envFromConfigmaps:
        postgresSchema: "agreement-management.postgresSchema"
  ```
* Secret "postgres" - secret del Db postgres, di seguito le chiavi referenziate:
  * POSTGRES_USR
  * POSTGRES_PSW

Al container è automaticamente applicata la seguente configurazione di risorse ed attualmente non può essere modificata:

```
# /interop-eks-microservice-chart/templates/deployment.yaml

resources:
  requests:
    memory: "64Mi"
    cpu: "10m"
  limits:
    memory: "1Gi"
    cpu: "500m"
```

---

## 3.  Ingress

Per installare ed abilitare l'Ingress per un dato microservizio, ad esempio agreement-management per l'ambiente "qa", è necessario definire il seguente blocco nel _values.yaml_:

```
# /microservices/agreement-management/qa/values.yaml

ingress:
  create: true
```

Al fine di aggiungere una regola di instradamento specifica per il microservizio in esame, è necessario anche specificare il parametro "ingress.applicationPath" come segue:

```
# /microservices/agreement-management/qa/values.yaml

ingress:
  applicationPath: "/api-gateway"
```

In automatico sarà generato un Ingress template con annotazione "alb.ingress.kubernetes.io/group.name" valorizzata con il default "interop-be"; è comunque possibile effettuare l'override di tale valore specificando il campo "groupName" come segue:

```
# /microservices/agreement-management/qa/values.yaml

ingress:
  groupName: "custom-group-name"
```

Opzionalmente,

* è possibile definire un host con cui eseguire l'override del default "*":

```
# /microservices/agreement-management/qa/values.yaml

ingress:
  host: "*.dev.interop.pagopa.it"
```

* è possibile aggiungere all'Ingress l'annotation "alb.ingress.kubernetes.io/group.order" utilizzando la seguente configurazione nel file _values.yaml_ del microservizio, ad essempio per "agreement-management" in ambiente "qa":

```
# /microservices/agreement-management/qa/values.yaml

ingress:
  groupOrder: 1
```
---

## 4. Service

E' possibile abilitare e customizzare le seguenti annotations per il Service generato per il microservizio:

  * alb.ingress.kubernetes.io/healthcheck-path
  * alb.ingress.kubernetes.io/healthcheck-port
  * alb.ingress.kubernetes.io/success-codes

definendo nel _values.yaml_ del servizio, ad esempio "agreement-management" in ambiente "qa", i seguenti attributi:
```
# /microservices/agreement-management/qa/values.yaml

healthcheck:
  path: "/ui"
  port: "8081"
  successCodes: "301"
```

Di seguito i mapping tra annotations e values:

  * "alb.ingress.kubernetes.io/healthcheck-path" è popolato con il contenuto di "healthcheck.path"
  * "alb.ingress.kubernetes.io/healthcheck-port" è popolato con il contenuto di "healthcheck.port" o, se non è presente, con "service.port"
  * "alb.ingress.kubernetes.io/success-codes" è popolato con il contenuto di "healthcheck.successCodes"

In aggiunta alle annotations, è possibile specificare delle porte custom su cui esporre il servizio applicando la seguente configurazione al file _values.yaml_ del microservizio che si sta sviluppando, ad esempio "agreement-management" in ambiente "qa"

```
# /microservices/agreement-management/qa/values.yaml

service:
  additionalPorts:
    - name: <port name>
      containerPort: <exposed port>
      protocol: <port protocol>
    - name: <port name 2>
      containerPort: <exposed port 2>
      protocol: <port protocol 2>
```

Con questo meccanismo, è possibile specificare una o più porte aggiuntive; tale configurazione si riflette sia sul Service che sul Deployment Kubernetes, ad esempio:

```
# Agreement-management Service.yaml

apiVersion: v1
kind: Service
metadata:
  name: interop-be-agreement-management
  namespace: qa
  ...
spec:
  type: ClusterIP
  ports:
    - name: name1
      targetPort: 9091
      protocol: tcp
    - name: name2
      targetPort: 9092
      protocol: tcp
  selector:
    app: interop-be-agreement-management
```

```
# Agreement-management Deployment.yaml

# Source: interop-eks-microservice-chart/templates/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: interop-be-agreement-management
  namespace: qa
  ...
spec:
  ...
  template:
    ...
    spec:
      containers:
        - name: interop-be-agreement-management
          ports:
            - name: name1
              containerPort: 9091
              protocol: tcp
            - name: name2
              containerPort: 9092
              protocol: tcp
```
---

## 5. Tipologie di Deployment

### 5.1. TechStack NodeJS

Di seguito sono descritti di template di Deployment utilizzati per Microservizi sviluppati in NodeJS; per poter essere utilizzati è necessario impostare il valore di *techStack* nel file _values.yaml_ dello specifico Microservizio.
Ad esempio, per il servizio _catalog-process_ in ambiente di _dev-refactor_ è necessario utilizzare la seguente configurazione:

```
# /microservices/catalog-process/dev-refactor/values.yaml

techStack: "nodejs"
```

Questa configurazione è necessaria per tutti i Deployment di seguito descritti.

#### 5.1.1. <ins>Default NodeJS Microservice Deployment</ins>

Il deployment di default utilizzato per Microservizi sviluppati in NodeJS è "deployment.nodejs.yaml"; per poter essere utilizzato, nel file _values.yaml_ non deve essere impostato il valore di _moduleType_.

Per questo Deployment è previsto l'utilizzo del FlyWay InitContainer; di seguito sono elencate le variabili d'ambiente in uso per tale container:

  * POSTGRES_HOST: mappata con la chiave _POSTGRES_HOST_ della ConfigMap _interop-be-db-commons_
  * POSTGRES_PORT: mappata con la chiave _POSTGRES_PORT_ della ConfigMap _interop-be-db-commons_
  * POSTGRES_DB: mappata con la chiave _POSTGRES_DB_ della ConfigMap _interop-be-db-commons_
  * FLYWAY_URL: valore composto dinamicamente in base ai valori di POSTGRES_HOST, POSTGRES_PORT e POSTGRES_DB recuperati dalla ConfigMap _interop-be-db-commons_
  * FLYWAY_CREATE_SCHEMAS: valorizzato con _true_
  * FLYWAY_PLACEHOLDER_REPLACEMENT: valorizzato con _true_
  * FLYWAY_SCHEMAS: mappato con la chiave definita in _deployment.flyway.postgresSchema_ nella ConfigMap del microservizio
  * FLYWAY_PLACEHOLDERS_APPLICATIONSCHEMA: mappato con la chiave definita in _deployment.flyway.postgresSchema_ nella ConfigMap del microservizio
  * FLYWAY_USER: mappato con la chiave _POSTGRES_USR_ del Secret comune "postgres"
  * FLYWAY_PASSWORD: mappato con la chiave _POSTGRES_PSW_ del Secret comune "postgres"

Per il container principale, sono definite le seguenti variabili d'ambiente:
  * NAMESPACE: mappato con il fieldRef metadata.namespace
  * REQUIRED_CONTACT_POINT_NR: mappato con il valore _replicas_ definito nel _values.yaml_
  * DEV_ENDPOINTS_ENABLED: mappato con la chiave DEV_ENDPOINTS_ENABLED della ConfigMap comune _interob-be-commons_

#### 5.1.2. <ins>Generic Consumer Deployment</ins>

Il deployment "deployment.nodejs.generic-consumer.yaml" è attualmente in uso solo per l'ambiente _dev-refactor_ e per i seguenti microservizi:
  * authorization-updater
  * notifier-seeder

Può essere attivato impostando il valore di **moduleType** nel _values.yaml_ del microservizio, ad esempio per _authorization-updater_ in ambiente _dev-refactor_:

```
# /microservices/authorization-updater/dev-refactor/values.yaml

techStack: "nodejs"
moduleType: "generic-consumer"
```

A differenza del Deployment di default, sono definite le seguenti variabili d'ambiente per il container principale:
  * LOG_LEVEL: mappato con il valore definito in _deployment.logLeveL_
  ```
  deployment:
    logLeveL_: "INFO"
  ```
  * KAFKA_BROKERS: mappato con la chiave _KAFKA_BROKERS_ della ConfigMap comune "common-kafka"

Per questo Deployment non è previsto l'utilizzo del FlyWay InitContainer.

#### 5.1.3. <ins>Process Microservice Deployment</ins>

Il deployment "deployment.nodejs.process-microservice.yaml" è attualmente in uso solo per l'ambiente _dev-refactor_ e per il seguente microservizio:
  * catalog-process

Può essere attivato impostando il valore di **moduleType** nel _values.yaml_ del microservizio, ad esempio per _catalog-process_ in ambiente _dev-refactor_:

```
# /microservices/catalog-process/dev-refactor/values.yaml

techStack: "nodejs"
moduleType: "process-ms"
```

Per questo Deployment è previsto l'utilizzo del FlyWay InitContainer; a differenza del Deployment di default, sono utilizzate delle chiavi specifiche della ConfigMap comune **common-event-store**:

  * POSTGRES_HOST: mappata con la chiave _EVENTSTORE_DB_HOST_ della ConfigMap
  * POSTGRES_PORT: mappata con la chiave _EVENTSTORE_DB_PORT_ della ConfigMap
  * POSTGRES_DB: mappata con la chiave _EVENTSTORE_DB_NAME_ della ConfigMap

Inoltre, sempre per l'init container, sono definite le seguenti variabili d'ambiente:
  * FLYWAY_URL: valore composto dinamicamente in base ai valori di EVENTSTORE_DB_HOST, EVENTSTORE_DB_PORT e EVENTSTORE_DB_NAME recuperati dalla suddetta ConfigMap
  * POSTGRES_DB: mappato con la chiave _EVENTSTORE_DB_NAME_ della ConfigMap comune "common-event-store"
  * FLYWAY_USER: mappato con la chiave _POSTGRES_USR_ della ConfigMap comune "event-store"
  * FLYWAY_PASSWORD: mappato con la chiave _POSTGRES_PSW_ del Secret comune "event-store"
  * FLYWAY_SCHEMAS: mappato con la chiave _EVENTSTORE_DB_SCHEMA_ della ConfigMap specifica del microservizio
  * FLYWAY_PLACEHOLDERS_APPLICATIONSCHEMA: mappato con la chiave _EVENTSTORE_DB_SCHEMA_ della ConfigMap specifica del microservizio

Per il container principale, sono definite le seguenti variabili d'ambiente:
  * PORT: mappato con il value definito in _service.containerPort_
  ```
  service:
    containerPort: 8080
  ```
  * HOST: mappato con il valore definito in _deployment.host_
  ```
  deployment:
    host: "0.0.0.0"
  ```
  * LOG_LEVEL: mappato con il valore definito in _deployment.logLeveL_
  ```
  deployment:
    logLeveL_: "INFO"
  ```
  * EVENTSTORE_DB_HOST: mappato con la chiave _EVENTSTORE_DB_HOST_ della ConfigMap comune "common-event-store"
  * EVENTSTORE_DB_NAME: mappato con la chiave _EVENTSTORE_DB_NAME_ della ConfigMap comune "common-event-store"
  * EVENTSTORE_DB_PORT: mappato con la chiave _EVENTSTORE_DB_PORT_ della ConfigMap comune "common-event-store"
  * EVENTSTORE_DB_USERNAME: mappato con la chiave _POSTGRES_USR_ della ConfigMap comune "event-store"
  * EVENTSTORE_DB_PASSWORD: mappato con la chiave _POSTGRES_PSW_ del Secret comune "event-store"
  * EVENTSTORE_DB_USE_SSL: valorizzato con "true"
  * READMODEL_DB_HOST: mappato con la chiave _READMODEL_DB_HOST_ della ConfigMap comune "common-read-model"
  * READMODEL_DB_NAME: mappato con la chiave _READMODEL_DB_NAME_ della ConfigMap comune "common-read-model"
  * READMODEL_DB_PORT: mappato con la chiave _READMODEL_DB_PORT_ della ConfigMap comune "common-read-model"
  * READMODEL_DB_USERNAME: mappato con la chiave _READONLY_USR_ della ConfigMap comune "read-model"
  * READMODEL_DB_PASSWORD: mappato con la chiave _READONLY_PSW_ del Secret comune "read-model"

#### 5.1.4. <ins>Read Model Writer Deployment</ins>

Il deployment "deployment.nodejs.read-model-writer.yaml" è attualmente in uso solo per l'ambiente _dev-refactor_ e per il seguente microservizio:
  * catalog-read-model-writer

Può essere attivato impostando il valore di **moduleType** nel _values.yaml_ del microservizio, ad esempio per _catalog-read-model-writer_ in ambiente _dev-refactor_:

```
# /microservices/catalog-read-model-writer/dev-refactor/values.yaml

techStack: "nodejs"
moduleType: "read-model-writer"
```

A differenza del Deployment di default, sono definite le seguenti variabili d'ambiente per il container principale:
  * PORT: mappato con il value definito in _service.containerPort_
    ```
    service:
      containerPort: 8080
    ```
  * HOST: mappato con il valore definito in _deployment.host_
  ```
  deployment:
    host: "0.0.0.0"
  ```
  * LOG_LEVEL: mappato con il valore definito in _deployment.logLeveL_
  ```
  deployment:
    logLeveL_: "INFO"
  ```
  * KAFKA_BROKERS: mappato con la chiave _KAFKA_BROKERS_ della ConfigMap comune "common-kafka"
  * READMODEL_DB_HOST: mappato con la chiave _READMODEL_DB_HOST_ della ConfigMap comune "common-read-model"
  * READMODEL_DB_NAME: mappato con la chiave _READMODEL_DB_NAME_ della ConfigMap comune "common-read-model"
  * READMODEL_DB_PORT: mappato con la chiave _READMODEL_DB_PORT_ della ConfigMap comune "common-read-model"
  * READMODEL_DB_USERNAME: mappato con la chiave _READMODEL_DB_USERNAME_ della ConfigMap comune "common-read-model"
  * READMODEL_DB_PASSWORD: mappato con la chiave _PROJECTION_PSW_ del Secret comune "read-model"

Per questo Deployment non è previsto l'utilizzo del FlyWay InitContainer.

#### 5.1.5 Frontend Deployment

Il deployment "deployment.frontend.yaml" è utilizzato dai servizi valorizzati con "techStack" a "frontend";
oltre ai campi previsti da un generico deployment, come descritto in precedenza, è possibile specificare un ulteriore campo "frontend",
in cui specificare le seguenti chiavi:
  1. env.js
  2. nginx
  3. additionalAssets

#### env.js
Il campo "env.js" ha questo formato:
```
frontend:
  env.js:
    window.pagopa_env:
      KEY: "VALUE1"
      KEY2: "VALUE2" # Questo valore è sovrascritto dal successivo a causa della chiave duplicata
      KEY2: "VALUE2.1"
      fromConfigmaps:
        EVENTSTORE_DB_HOST: "common-event-store.EVENTSTORE_DB_HOST"
        EVENTSTORE_DB_NAME: "common-event-store.EVENTSTORE_DB_NAME"
```
dove:
  - "window.pagopa_env": sarà utilizzato per valorizzare la configmap associata al deployment di frontend. E' possibile utilizzare un nome diverso da "window.pagopa_env"
  - KEY: è un chiave generica con valore in chiaro utilizzato per valorizzare il contenuto di "window.pagopa_env". E' possibile definire più di una coppia chiave/valore, eventuali chiavi duplicate saranno ignorate dando la precedenza all'ultima definita
  - fromConfigmaps: è una chiave speciale utilizzata per definire una lista di coppie chiave valore dove quest'ultimo è composto da un prefisso, che definisce una ConfigMap da referenziare, ed un suffisso, che definisce la chiave da cercare nella ConfigMap, separati da un punto; il valore referenziato dalla accoppiata prefisso/suffisso sarà ricercato nella ConfigMap dichiarata e il valore risultante inserito in "window.pagopa_env". Le stesse regole per le chiavi descritte in precedenza, valgono anche per quelle definite in "fromConfigmaps"

L'esito della computazione del precedente snippet di codice, all'interno della ConfigMap generata per il deployment di frontend, avrà questo formato:
```
env.js: |-
  window.pagopa_env =
    {
      "KEY": "VALUE1",
      "KEY2": "VALUE2.1",
      "EVENTSTORE_DB_HOST": "xxxxxx.eu-south-1.rds.amazonaws.com",
      "EVENTSTORE_DB_NAME": "dbname"
    }
```

#### additionalAssets
Il campo "eadditionalAssets" ha questo formato:
```
frontend:
  additionalAssets:
    - tool.js
    - env.js
```
E' utilizzato per definire una lista di chiavi utilizzate nel deployment di Frontend.
Tali valori sono gestiti nel deployment per generare automaticamente dei riferimenti a volumes e volumeMounts come segue:

```
# Source: interop-eks-microservice-chart/templates/deployment.frontend.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  ...
spec:

  template:
    ...
    spec:
      containers:
        - name: test-frontend
          image: "000000000000.dkr.ecr.eu-central-1.amazonaws.com/test-frontend:latest"
          ...
          volumeMounts:
            - name: tool-js
              mountPath: /usr/share/nginx/html/ui/tool.js
              subPath: tool.js
              readOnly: true
            - name: env-js
              mountPath: /usr/share/nginx/html/ui/env.js
              subPath: env.js
              readOnly: true
      volumes:
        - name: tool-js
          configMap:
            defaultMode: 420
            name: test-frontend
            items:
              - key: tool.js
                path: tool.js
        - name: env-js
          configMap:
            defaultMode: 420
            name: test-frontend
            items:
              - key: env.js
                path: env.js
```

Esempio di configurazione del values.yaml specifica solo per i deployment di Frontend:

frontend:
  env.js:
    window.pagopa_env:
      KEY: "VALUE1"
      KEY_2: "VALUE2"
      fromConfigmaps:
        EVENTSTORE_DB_HOST: "common-event-store.EVENTSTORE_DB_HOST"
        EVENTSTORE_DB_NAME: "common-event-store.EVENTSTORE_DB_NAME"
  # tools.js è ignorato
  tool.js:
    window.pagopa_env:
      KEY: "VALUE1"
      KEY_2: "VALUE2"
      KEY_2: "VALUE2"
      fromConfigmaps:
        EVENTSTORE_DB_HOST: "common-event-store.EVENTSTORE_DB_HOST"
        EVENTSTORE_DB_NAME: "common-event-store.EVENTSTORE_DB_NAME"
        AGREEMENT_OUTBOUND_TOPIC: "common-kafka.AGREEMENT_OUTBOUND_TOPIC"
        READMODEL_DB_HOST: "common-read-model.READMODEL_DB_HOST"
  nginx:
    default.conf: |-
      server {
        listen       80;
        listen  [::]:80;
        server_name  localhost;
        absolute_redirect off;

        location /ui {
            root   /usr/share/nginx/html;
            sub_filter_once off;
            sub_filter_types *;
            sub_filter **CSP_NONCE** $request_id;
            add_header Content-Security-Policy "default-src 'self'; object-src 'none'; connect-src 'self' https://test.s3.eu-central-1.amazonaws.com; script-src 'nonce-$request_id'; style-src 'self' 'unsafe-inline'; worker-src 'none'; font-src 'self'; img-src 'self' data:; base-uri 'self'";
            add_header Strict-Transport-Security "max-age=31536000";
            add_header X-Content-Type-Options "nosniff";
            add_header X-Frame-Options "SAMEORIGIN";
            add_header Referrer-Policy "no-referrer";
            rewrite /ui/index.html /ui permanent;
            try_files $uri /ui/index.html =404;
        }

        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   /usr/share/nginx/html;
        }
      }
  additionalAssets:
    - tool.js
    - env.js

## 6. ExternalSecrets

External Secrets Operator è un operatore Kubernetes che permette di sincronizzare secrets da provider esterni (AWS Secrets Manager, Azure Key Vault, GCP Secret Manager, HashiCorp Vault, ecc.) nei Secret nativi di Kubernetes.

Questa chart crea un singolo ExternalSecret che può sincronizzare multipli secrets da diverse fonti in un unico Secret Kubernetes, semplificando la gestione e il riferimento ai secrets nei deployment.

### 6.1. Configurazione Base

Per abilitare la creazione di un ExternalSecret, impostare `externalSecrets.create: true`:

```yaml
externalSecrets:
  create: true
  refreshInterval: "1h"
  secretStoreRef:
    name: aws-secretsmanager
    kind: SecretStore
  targetSecret:
    name: my-app-secrets  # Nome del Secret K8s che conterrà tutte le chiavi
  data:
    - secretKey: db-password
      remoteRef:
        key: /prod/database/credentials
        property: password
    - secretKey: api-key
      remoteRef:
        key: /prod/api/credentials
        property: api-key
```

Questa configurazione crea:
- **1 ExternalSecret** con nome uguale al microservizio
- **1 Secret Kubernetes** (`my-app-secrets`) contenente tutte le chiavi sincronizzate

### 6.2. Parametri Principali

#### 6.2.1. secretStoreRef

Riferimento al SecretStore o ClusterSecretStore da utilizzare:

```yaml
secretStoreRef:
  name: aws-secretsmanager  # Nome del SecretStore
  kind: SecretStore         # SecretStore o ClusterSecretStore
```

#### 6.2.2. refreshInterval

Intervallo di refresh per la sincronizzazione:

```yaml
refreshInterval: "1h"  # Ogni ora
```

#### 6.2.3. targetSecret

Configurazione del Secret Kubernetes di destinazione che conterrà tutte le chiavi:

```yaml
targetSecret:
  name: my-app-secrets     # Nome del Secret K8s
  creationPolicy: Merge    # Owner, Orphan, Merge, None
  deletionPolicy: Retain   # Retain, Delete
```

#### 6.2.4. data

Lista di chiavi individuali da sincronizzare da diverse fonti. Tutte le chiavi vengono aggregate in un unico Secret:

```yaml
data:
  - secretKey: db-password      # Nome chiave nel Secret K8s
    remoteRef:
      key: /prod/db/creds      # Percorso nel provider esterno
      property: password        # Proprietà specifica
  - secretKey: api-key
    remoteRef:
      key: /prod/api/credentials
      property: api-key
  - secretKey: jwt-secret
    remoteRef:
      key: /prod/app/secrets
      property: jwt-secret
```

#### 6.2.5. dataFrom

Sincronizzazione di interi secrets o ricerca per pattern:

```yaml
dataFrom:
  # Estrarre tutte le chiavi da un secret
  - extract:
      key: /prod/api/credentials
  # Cercare secrets per path e tags
  - find:
      path: /prod/secrets/
      name:
        regexp: "^feature-.*"
      tags:
        environment: production
```

### 6.3. Template per Secret Trasformati

È possibile trasformare i dati sincronizzati usando template Go:

```yaml
externalSecrets:
  create: true
  secretStoreRef:
    name: aws-secretsmanager
    kind: SecretStore
  targetSecret:
    name: app-config
    template:
      type: Opaque
      metadata:
        labels:
          app: my-app
      data:
        # Trasforma i valori sincronizzati in un file config
        config.yaml: |
          database:
            host: {{ .db_host }}
            port: {{ .db_port }}
            username: {{ .db_username }}
            password: {{ .db_password }}
          api:
            key: {{ .api_key }}
            secret: {{ .api_secret }}
  data:
    - secretKey: db_host
      remoteRef:
        key: /prod/db/config
        property: host
    - secretKey: db_port
      remoteRef:
        key: /prod/db/config
        property: port
    - secretKey: db_username
      remoteRef:
        key: /prod/db/credentials
        property: username
    - secretKey: db_password
      remoteRef:
        key: /prod/db/credentials
        property: password
    - secretKey: api_key
      remoteRef:
        key: /prod/api/credentials
        property: key
    - secretKey: api_secret
      remoteRef:
        key: /prod/api/credentials
        property: secret
```

### 6.4. Utilizzo nei Deployment

Il Secret creato dall'ExternalSecret può essere referenziato nei deployment tramite `envFromSecrets`:

```yaml
deployment:
  enableRolloutAnnotations: true
  envFromSecrets:
    # Tutte le chiavi sono nello stesso Secret
    DATABASE_PASSWORD: my-app-secrets.db-password
    DATABASE_USERNAME: my-app-secrets.db-username
    API_KEY: my-app-secrets.api-key
    JWT_SECRET: my-app-secrets.jwt-secret

externalSecrets:
  create: true
  secretStoreRef:
    name: aws-secretsmanager
    kind: SecretStore
  targetSecret:
    name: my-app-secrets
  data:
    - secretKey: db-password
      remoteRef:
        key: /prod/database/credentials
        property: password
    - secretKey: db-username
      remoteRef:
        key: /prod/database/credentials
        property: username
    - secretKey: api-key
      remoteRef:
        key: /prod/api/credentials
        property: api-key
    - secretKey: jwt-secret
      remoteRef:
        key: /prod/app/secrets
        property: jwt-secret
```

### 6.5. Rollout Annotations

Quando `deployment.enableRolloutAnnotations` è abilitato, i deployment vengono automaticamente riavviati quando cambia la configurazione di ExternalSecret. Viene calcolato l'hash (SHA256) del template ExternalSecret e inserito come annotation nel pod template, triggering un rolling restart ogni volta che la configurazione degli ExternalSecrets viene modificata.

**Workflow automatico:**
1. Modificare la configurazione di `externalSecrets` nei values (aggiungere/modificare/rimuovere chiavi in `data` o `dataFrom`, cambiare `secretStoreRef`, ecc.)
2. Applicare l'aggiornamento del chart con `helm upgrade`
3. L'hash del template ExternalSecret cambia automaticamente
4. I pod vengono riavviati automaticamente e caricano i nuovi secret

**Vantaggi:**
- Nessun campo manuale `version` da incrementare
- Rollout automatico ogni volta che la configurazione degli ExternalSecrets cambia
- L'hash viene ricalcolato automaticamente da Helm

**Nota**: External Secrets Operator sincronizza automaticamente i secrets dal provider esterno secondo il `refreshInterval` configurato. Il restart dei pod avviene automaticamente quando si modifica la configurazione di ExternalSecret nel chart.

### 6.6. Aggregazione di Secrets da Multiple Fonti

Un vantaggio chiave di questa implementazione è la possibilità di aggregare secrets da diverse fonti in un unico Secret Kubernetes:

```yaml
externalSecrets:
  create: true
  targetSecret:
    name: aggregated-secrets
  data:
    # Database secrets
    - secretKey: db-host
      remoteRef:
        key: /prod/database/config
        property: host
    - secretKey: db-password
      remoteRef:
        key: /prod/database/credentials
        property: password

    # API secrets
    - secretKey: api-key
      remoteRef:
        key: /prod/api/credentials
        property: key

    # Cache secrets
    - secretKey: redis-password
      remoteRef:
        key: /prod/cache/credentials
        property: password

    # Monitoring secrets
    - secretKey: monitoring-token
      remoteRef:
        key: /prod/monitoring/tokens
        property: app-token

  # Anche aggiungere interi secrets
  dataFrom:
    - extract:
        key: /prod/feature-flags
```

Risultato: un singolo Secret K8s `aggregated-secrets` contenente tutte le chiavi.

### 6.7. Esempio Completo

Vedere il file `microservices/externalsecrets-example/values.yaml` per un esempio completo di configurazione.


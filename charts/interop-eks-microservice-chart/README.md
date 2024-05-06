
Interop-eks-microservice-chart
===========

A Helm chart for PagoPa Interop Microservices


## Configuration

The following table lists the configurable parameters of the Interop-eks-microservice-chart chart and their default values.

| Parameter                | Description             | Default        |
| ------------------------ | ----------------------- | -------------- |
| `securityContext.runAsUser` |  | `1001` |
| `securityContext.allowPrivilegeEscalation` |  | `false` |
| `image.imagePullPolicy` |  | `"Always"` |
| `service.type` |  | `"ClusterIP"` |
| `service.monitoringPort` |  | `9095` |
| `service.managementPort` |  | `8558` |
| `service.enableHttp` |  | `true` |
| `service.targetPort` |  | `"http"` |
| `service.enableMonitoring` |  | `true` |
| `service.enableManagement` |  | `true` |
| `ingress.enable` |  | `false` |
| `ingress.className` |  | `"alb"` |
| `ingress.groupName` |  | `"interop-be"` |
| `deployment.flyway.enableFlywayInitContainer` |  | `false` |
| `deployment.enableReadinessProbe` |  | `true` |
| `deployment.enableLivenessProbe` |  | `true` |

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

#### 1.1.5 <ins>envFieldRef - Referenziare informazioni del Pod</ins>

Per esporre dei campi del Pod al runtime del container, è possibile utilizzare il campo "fieldRef", come da [documentazione](https://kubernetes.io/docs/concepts/workloads/pods/downward-api/#downwardapi-fieldRef) ufficiale Kubernetes.
Un campo esposto con "fieldRef" può essere referenziato dal Deployment di un microservizio, ad esempio "agreement-management" per ambiente "qa", inserendo la seguente configurazione nel file _values.yaml_ come segue:

```
# /microservices/agreement-management/qa/values.yaml

deployment:
  envFieldRef:
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

Non c'è limite al numero di variabili d'ambiente configurabili nella sezione "envFieldRef".

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

## 2. Common ConfigMaps

Di seguito sono descritte le ConfigMap esterne che possono essere referenziate dai singoli microservizi seguendo la sintassi indicata in "envFromConfigmaps - Referenziare una ConfigMap esterna"; le seguenti ConfigMap sono comuni a tutti i Deployment e raggruppano dei valori comuni a tutti i microservizi.
Al fine di essere utilizzate, le ConfigMap comuni devono essere già state installate nel namespace/ambiente in cui si vogliono rilasciare i microservizi.

### 2.1. interop-be-commons

Il nome di questa ConfigMap è "interop-be-commons" ed include parametri di configurazione generali ed URL di utilità comune, come ad esempio:

* AGREEMENT_MANAGEMENT_URL
* AGREEMENT_PROCESS_URL
* SELFCARE_V2_URL
* WELL_KNOWN_URLS
* PERSISTENCE_EVENTS_QUEUE_URL
* ...

Per utilizzare una delle chiavi specificate nella ConfigMap "interop-be-commons" è sufficiente referenziarla nel file _values.yaml_ del microservizio, ad esempio "agreement-management" per ambiente "qa", come segue:

```
# /microservices/agreement-management/qa/values.yaml

deployment:
  envFromConfigmaps:
    CUSTOM_KEY_AGREEMENT_MANAGEMENT_URL: "interop-be-commons.AGREEMENT_MANAGEMENT_URL"
```


### 2.2. interop-be-db-commons

Il nome di questa ConfigMap è "interop-be-db-commons" ed include parametri di configurazione generali relativi alle connessioni ai DB postgres, documentDB e redis, ad esempio:

* POSTGRES_HOST
* POSTGRES_PORT
* READ_MODEL_DB_HOST
* RATE_LIMITER_REDIS_HOST
* ...

Per utilizzare una delle chiavi specificate nella ConfigMap "interop-be-db-commons" è sufficiente referenziarla nel file _values.yaml_ del microservizio, ad esempio "agreement-management" per ambiente "qa", come segue:

```
# /microservices/agreement-management/qa/values.yaml

deployment:
  envFromConfigmaps:
    CUSTOM_KEY_POSTGRES_HOST: "interop-be-db-commons.POSTGRES_HOST"
```

### 2.3. common-db-migrations

Il nome di questa ConfigMap è "common-db-migrations" ed include script di inizializzazione del db postgres; in particolare si occupa di creare le tabelle event_journal, event_tag, snapshot, akka_projection_offset_store, akka_projection_management.

Per referenziare questa ConfigMap è sufficiente mapparla con un volume nella definizione del Deployment del microservizio, ad esempio "agreement-management" per ambiente "qa", come segue:

```
# /microservices/agreement-management/qa/values.yaml

volumes:
  - name: migrations-files
    projected:
      sources:
       - configMap:
          name: common-db-migrations
```

---

## 4. Common Values

Per ogni ambiente sono definiti dei valori di default utilizzati dalla Chart dei microservizi e dei cronjob; tali valori sono reperibili nei file presenti in "commons/<ENV>/values.yaml" e, se necessario, possono essere sovrascritti dai microservizi.


### 4.1 Valori di default
Di seguito l'elenco dei campi con esempi di valorizzazioni, ad esempio per l'ambiente "dev":

```
# /commons/dev/values-microservice.yaml

# Namespace su cui è rilasciato il servizio e le sue risorse
namespace: "dev"

# Numero di repliche per il servizio
replicas: 1

# Tecnologia utilizzata per sviluppare il servizio, ad esempio "scala" o "nodejs" per i backend e "frontend" per servizi di frontend
techStack: "scala"

# Porta su cui è esposto il servizio
service:
  port: 8088

# Configurazione dell'immagine Docker del servizio; necessario specificare il nome dell'immagine specifica associata al servizio.
image:
  repositoryPrefix: "505630707203.dkr.ecr.eu-central-1.amazonaws.com"
  imagePullPolicy: Always

# Nome della ConfigMap con le configurazioni comuni relative ai Db
commonsDbConfigmapName: "interop-be-db-commons"

# Risorse utilizzate (richieste/limite) dal container
resources:
  requests:
    cpu: "500m"
    memory: "2Gi"
  limits:
    cpu: "500m"
    memory: "2Gi"
```

### 4.2 Esempio di override
Dati i valori di default specificati nel file _values.yaml_ della Chart ed i valori comuni a tutti i servizi definiti in _commons/<ENV>/values-microservice .yaml_, è sempre possibile indicare dei valori che li sovrascrivano per il servizio che si sta sviluppando.
In ogni caso, in dipendenza da come sono gestiti ed implementati i progetti contenenti le definizioni delle Chart e dei servizi, l'override è eseguito a partire dalla definizione più generale, quella della Chart, passando per eventuali definizioni comuni per ambienti, nella directory commons, fino ad arrivare a definizioni specifiche per i servizi sviluppati, nelle directory microservices e jobs; il valore più specifico ha una priorità maggiore rispetto a quelli più generali.

**<u>Caso 1</u> - Chart e Servizio**

Considerando il seguente contenuto del _values.yaml_ della Chart "interop-eks-microservice-chart":
```
# /interop-eks-microservice-chart/values.yaml

service:
  port: 8080
```

Nei commons non è specificato nessun override per tale valore, ma in fase di sviluppo di un servizio, ad esempio "agreement-management", è possibile indicare quanto segue nel _values.yaml_ dell'ambiente "qa":
```
# /microservices/agreement-management/qa/values.yaml

service:
  port: 8081
```

In fase di generazione dei template Helm, il valore finale considerato sarà quello specificato nel values del servizio, quindi:
```
service:
  port: 8081
```

**<u>Caso 2</u> - Commons e Servizio**

Considerando il seguente contenuto del _values.yaml_ definito nei commons dell'ambiente "qa":
```
# /commons/qa/values-microservice.yaml

service:
  port: 8081
```

e tenendo conto che nel _values.yaml_ della Chart "interop-eks-microservice-chart" non è specificato alcun valore, in fase di sviluppo di un servizio, ad esempio "agreement-management", è possibile indicare quanto segue nel _values.yaml_ dello stesso:
```
# /microservices/agreement-management/qa/values.yaml

service:
  port: 8082
```

In fase di generazione dei template Helm, il valore finale considerato sarà quello specificato nel values del servizio, quindi:
```
service:
  port: 8082
```

**<u>Caso 3</u> - Chart e Commons**

Considerando il seguente contenuto del _values.yaml_ della Chart "interop-eks-microservice-chart":
```
# /interop-eks-microservice-chart/values.yaml

service:
  port: 8080
```

e dato il seguente contenuto del _values.yaml_ definito nei commons dell'ambiente "qa":
```
# /commons/qa/values-microservice.yaml

service:
  port: 8081
```

se in fase di sviluppo di un servizio, ad esempio "agreement-management", non si indica alcun valore specifico, durante la generazione dei template Helm il valore finale considerato sarà quello dei common values dell'ambiente selezionato, quindi:
```
service:
  port: 8081
```

**<u>Caso 4</u> - Chart, Commons e Servizio**

Considerando il seguente contenuto del _values.yaml_ della Chart "interop-eks-microservice-chart":
```
# /interop-eks-microservice-chart/values.yaml

service:
  port: 8080
```

e dato il seguente contenuto del _values.yaml_ definito nei commons dell'ambiente "qa":
```
# /commons/qa/values-microservice.yaml

service:
  port: 8081
```

se in fase di sviluppo di un servizio, ad esempio "agreement-management", si indica un valore specifico:
```
# /microservices/agreement-management/qa/values.yaml

service:
  port: 8082
```

durante la generazione dei template Helm il valore finale considerato sarà quello indicato per il servizio, quindi:
```
service:
  port: 8082
```

**<u>Caso 5</u> - Solo Chart**

Considerando il seguente contenuto del _values.yaml_ della Chart "interop-eks-microservice-chart":
```
# /interop-eks-microservice-chart/values.yaml

service:
  port: 8080
```

se in fase di sviluppo di un servizio, ad esempio "agreement-management", non si indica alcun valore specifico, durante la generazione dei template Helm, il valore finale considerato sarà quello dei values della Chart, quindi:
```
service:
  port: 8080
```

**<u>Caso 6</u> - Solo commons**

Considerando il seguente contenuto del _values.yaml_ nei commons dell'ambiente "qa":
```
# /commons/qa/values-microservice.yaml

service:
  port: 8081
```

se in fase di sviluppo di un servizio, ad esempio "agreement-management", non si indica alcun valore specifico, durante la generazione dei template Helm il valore finale considerato sarà quello dei common values dell'ambiente selezionato, quindi:
```
service:
  port: 8081
```

**<u>Caso 7</u> - Solo servizio**

Considerando il seguente contenuto del _values.yaml_ di un servizio, ad esempio "agreement-management" (microservices/agreement-management/qa/values.yaml):
```
# /microservices/agreement-management/qa/values.yaml

service:
  port: 8082
```

durante la generazione dei template Helm il valore finale considerato sarà quello indicato per il servizio stesso, quindi:
```
service:
  port: 8082
```

### 4.3 Cronjob

Nei commons degli ambienti di rilascio sono presenti dei values separati per i classici microservizi, per cui è previsto anche un Service Kubernetes, definiti nel file _values-microservice.yaml_ e per i job in esecuzione programmata, Cronjob Kubernetes, per i quali è utilizzato il file _values-cronjob.yaml_.
Nonostante sussita questa separazione fisica dei values, ai fini dello sviluppo di uno dei due tra Microservizi e Cronjob, valgono le stesse regole di override precedentemente descritte.

---

## 5. FlyWay init container

Alcuni microservizi possono avere la necessità di utilizzare Flyway per la gestione di migrazioni del DB; al fine di soddisfare tale requisito, è possibile abilitare un Flyway init container aggiungendo ai _values.yaml_ la seguente configurazione, ad esempio per il servizio "agreement-management" nell'ambiente "qa":

```
# /microservices/agreement-management/qa/values.yaml

deployment:
  flyway:
    enableFlywayInitContainer: true
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
    flyway:
      postgresSchema: "qa_agreement"
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

Altri valori di default sono definiti all'interno della Chart e, come per quelli comuni per ambiente, possono essere sovrascritti:

```
# /interop-eks-microservice-chart/values.yaml

# securityContext del Pod, utilizzata nel Deployment
securityContext:
  runAsUser: 1001
  allowPrivilegeEscalation: false

# Pull policy dell'immagine Docker
image:
  imagePullPolicy: Always

# Configurazione utilizzata dall Service e dal Deployment
service:
  type: "ClusterIP"
  monitoringPort: 9095
  managementPort: 8558
  enableHttp: true
  targetPort: "http"
  enableMonitoring: true
  enableManagement: true

# Configurazione dell'Ingress, disabilitato se non indicato esplicitamente
ingress:
  enable: false
  className: alb
  groupName: "interop-be"

# Configurazione del Deployment con Flyway disattivato e sonde attive
deployment:
  flyway:
    enableFlywayInitContainer: false
  enableReadinessProbe: true
  enableLivenessProbe: true
```

---

## 6.  Ingress

Per installare ed abilitare l'Ingress per un dato microservizio, ad esempio agreement-management per l'ambiente "qa", è necessario definire il seguente blocco nel _values.yaml_:

```
# /microservices/agreement-management/qa/values.yaml

ingress:
  enable: true
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

## 7. Service

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


## 8. Script

## 8.1 Generazione dei Template Helm

E' possibile generare i template Helm di un Cronjob o di un Microservizio senza applicare alcuna modifica al cluster Kubernetes per cui si vogliono produrre i manifest.


**Generazione dei template di un singolo microservizio**

Per generare i template di un Microservizio in ambiente di "qa", ad esempio per "agreement-management", è possibile utilizzare lo script "helmTemplate-svc-single.sh" nel seguente modo:

```
sh helmTemplate-svc-single.sh -e qa -m agreement-management -d
```

o utilizzando la sintassi estesa

```
sh helmTemplate-svc-single.sh --environment qa --microservice agreement-management --debug
```

E' possibile combinare opzioni in versione compressa o estesa ed accedere all'help dello script con la seguente opzione:

```
sh helmTemplate-svc-single.sh --help
sh helmTemplate-svc-single.sh -h
```

L'esecuzione di questo script comporta la creazione di una directory "out_agreement-management_qa" conenente un file yaml con i template generati per il servizio ed ambiente specificati.

**Generazione dei template di un singolo cronjob**

Per generare i template di un Cronjob in ambiente di "qa", ad esempio per "attributes-loader", è possibile utilizzare lo script "helmTemplate-cron-single.sh" nel seguente modo:

```
sh helmTemplate-cron-single.sh -e qa -j attributes-loader -d
```

o utilizzando la sintassi estesa

```
sh helmTemplate-cron-single.sh --environment qa --job attributes-loader --debug
```

E' possibile combinare opzioni in versione compressa o estesa ed accedere all'help dello script con la seguente opzione:

```
sh helmTemplate-cron-single.sh --help
sh helmTemplate-cron-single.sh -h
```

L'esecuzione di questo script comporta la creazione di una directory "out_cron_attributes-loader_qa" conenente un file yaml con i template generati per il cronjob ed ambiente specificati.


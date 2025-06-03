{{/*
Expand the name of the chart.
*/}}
{{- define "interop-eks-microservice-chart.name" -}}
{{- .Values.nameOverride | default .Chart.Name  | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "interop-eks-microservice-chart.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := .Values.nameOverride |  default .Chart.Name }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "interop-eks-microservice-chart.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "interop-eks-microservice-chart.labels" -}}
app.kubernetes.io/name: {{ .Values.name }}
helm.sh/chart: {{ include "interop-eks-microservice-chart.chart" . }}
{{ include "interop-eks-microservice-chart.selectorLabels" . }}
{{- if .Values.deployment.image.tag }}
{{- $imageTag := "" }}
{{- $imageTag = ( print .Values.deployment.image.tag | nospace ) }}
app.kubernetes.io/version: {{ $imageTag | quote }}
{{- else if .Values.deployment.image.digest }}
{{- $digestSuffix := "" }}
{{- $digestSuffix = (nospace .Values.deployment.image.digest) }}
app.kubernetes.io/version: {{ $digestSuffix }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels - USED
*/}}
{{- define "interop-eks-microservice-chart.selectorLabels" -}}
app: {{ .Values.name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "interop-eks-microservice-chart.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- .Values.serviceAccount.name |  default (include "interop-eks-microservice-chart.fullname" .) }}
{{- else }}
{{- .Values.serviceAccount.name | default "default" }}
{{- end }}
{{- end }}


{{- define "interop-eks-microservice-chart.check-tpl-value" -}}
  {{- $givenValue := typeIs "string" .value | ternary .value (.value | toYaml) }}
  {{- $givenContext := .context }}
  {{- $givenScope := .scope }}

  {{- $pattern := `{{\.Values[^}]+}}` }}
  {{- $valuesMatches := (regexFindAll $pattern $givenValue -1) }}

  {{- /* For every match check if the rendered template is valid, i.e. not empty/null */}}
  {{- range $index, $match := $valuesMatches }}
    {{- $renderedValue := include "interop-eks-microservice-chart.render-tpl-value" (dict "value" $match "context" $givenContext "scope" $givenScope) }}
    {{- if or (eq $renderedValue nil) (eq $renderedValue "")  }}
      {{ fail (printf "Error: %s must be set and non-empty" $match) }}
    {{- end }}
  {{- end }}
{{- end -}}


{{- define "interop-eks-microservice-chart.render-tpl-value" -}}
  {{- $givenValue := .value }}
  {{- $givenContext := .context }}
  {{- $givenScope := .scope }}
  {{- $renderedValue := "" }}

  {{- if and (ne $givenScope nil) (ne $givenScope "") }}
    {{- $renderedValue = tpl (cat "{{- with $.RelativeScope -}}" $givenValue "{{- end }}") (merge (dict "RelativeScope" $givenScope) $givenContext) }}
  {{- else }}
    {{- $renderedValue = tpl $givenValue $givenContext -}}
  {{- end }}

  {{- $renderedValue -}}
{{- end -}}

{{/*
Renders a value that contains template perhaps with scope if the scope is present.
Usage:
{{ include "interop-eks-microservice-chart.render-template" ( dict "value" .Values.path.to.the.Value "context" $ ) }}
{{ include "interop-eks-microservice-chart.render-template" ( dict "value" .Values.path.to.the.Value "context" $ "scope" $app ) }}
*/}}
{{- define "interop-eks-microservice-chart.render-template" -}}
{{- $value := typeIs "string" .value | ternary .value (.value | toYaml) }}

{{- if and (typeIs "string" $value) (contains "{{" (toJson $value)) }}
  {{- $givenScope := .scope }}
  {{- $givenContext := .context }}
  {{- include "interop-eks-microservice-chart.check-tpl-value" (dict "value" $value "context" $givenContext "scope" $givenScope) -}}
  {{- include "interop-eks-microservice-chart.render-tpl-value" (dict "value" $value "context" $givenContext "scope" $givenScope) -}}
{{- else }}
  {{- $value -}}
{{- end -}}
{{- end -}}

{{/*
Generate annotations (in deployment.spec.template.metadata) for each configmap, secret and service account referenced by the deployment.
Usage:
{{ include "interop-eks-microservice-chart.generateRolloutAnnotations" }}
*/}}
{{- define "interop-eks-microservice-chart.generateRolloutAnnotations" -}}

{{- if and .Values.deployment .Values.deployment.enableRolloutAnnotations -}}
{{ .Values.name }}/configmap.sha256: {{ include (print $.Template.BasePath "/configmap.yaml") . | sha256sum | quote }}
{{- end }}

{{- if and .Values.deployment .Values.deployment.envFromConfigmaps .Values.deployment.enableRolloutAnnotations .Values.enableLookup }}
{{- $processedConfigmaps := dict }}
{{- range $key, $val := .Values.deployment.envFromConfigmaps }}
{{- $configmapAddress := mustRegexSplit "\\." $val 2 }}
{{- $configmapName := index $configmapAddress 0 }}
{{- if not (hasKey $processedConfigmaps $configmapName) }}
{{- $configmap := lookup "v1" "ConfigMap" $.Values.namespace $configmapName }}
{{- if $configmap }}
{{ $configmapName }}/configmap.resourceVersion: {{ $configmap.metadata.resourceVersion | quote }}
{{- $_ := set $processedConfigmaps $configmapName "" }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}

{{- /* Frontend configmap generateRolloutAnnotations */ -}}
{{- if and $.Values.frontend (hasKey $.Values.frontend "env.js") }}
{{- $processedConfigmaps := list }}
{{- range $key, $val := $.Values.frontend }}
{{- if eq $key "env.js" }}
{{- range $json_key, $json_val := $val }}
{{- range $subKey, $subValue := $json_val }}
{{- if and (eq $subKey "fromConfigmaps") $.Values.enableLookup }}
{{- range $fromConfigmapsSubKey, $fromConfigmapsSubValue := $subValue }}
{{- $configmapAddress := mustRegexSplit "\\." $fromConfigmapsSubValue 2 }}
{{- $configmapName := index $configmapAddress 0 }}
{{- if not (has $configmapName $processedConfigmaps) }}
{{- $configMap := (lookup "v1" "ConfigMap" $.Values.namespace $configmapName) }}
{{- if $configMap }}
{{- $processedConfigmaps = append $processedConfigmaps $configmapName }}
{{ $configmapName }}/configmap.resourceVersion: {{ $configMap.metadata.resourceVersion | quote }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}

{{- if and .Values.deployment .Values.deployment.flywayInitContainer.migrationsConfigmap .Values.deployment.enableRolloutAnnotations  .Values.enableLookup }}
{{- $configmapName := .Values.deployment.flywayInitContainer.migrationsConfigmap }}
{{- $configmap := lookup "v1" "ConfigMap" $.Values.namespace $configmapName }}
{{- if $configmap }}
{{ $configmapName }}/flywayConfigmap.resourceVersion: {{ $configmap.metadata.resourceVersion | quote }}
{{- end }}
{{- end }}

{{- if and .Values.deployment .Values.deployment.envFromSecrets .Values.deployment.enableRolloutAnnotations .Values.enableLookup }}
{{- $processedSecrets := dict }}
{{- range $key, $val := .Values.deployment.envFromSecrets }}
{{- $secretAddress := mustRegexSplit "\\." $val 2 }}
{{- $secretName := index $secretAddress 0 }}
{{- if not (hasKey $processedSecrets $secretName) }}
{{- $secret := lookup "v1" "Secret" $.Values.namespace $secretName }}
{{- if $secret }}
{{ $secretName }}/secret.resourceVersion: {{ $secret.metadata.resourceVersion | quote }}
{{- $_ := set $processedSecrets $secretName "" }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}

{{- if and .Values.deployment .Values.deployment.flywayInitContainer.envFromSecrets .Values.deployment.enableRolloutAnnotations .Values.enableLookup }}
{{- $processedSecrets := dict }}
{{- range $key, $val := .Values.deployment.flywayInitContainer.envFromSecrets -}}
{{- $renderedVal := include "interop-eks-microservice-chart.render-template" (dict "value" $val "context" $) }}
{{- $secretAddress := mustRegexSplit "\\." $renderedVal 2 }}
{{- $secretName := index $secretAddress 0 }}
{{- if not (hasKey $processedSecrets $secretName) }}
{{- $secret := lookup "v1" "Secret" $.Values.namespace $secretName }}
{{- if $secret }}
{{ $secretName }}/flywaySecret.resourceVersion: {{ $secret.metadata.resourceVersion | quote }}
{{- $_ := set $processedSecrets $secretName "" }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}

{{- if and .Values.deployment .Values.deployment.enableRolloutAnnotations .Values.serviceAccount.create}}
{{ $.Values.name }}/serviceAccount.sha256: {{ include (print $.Template.BasePath "/serviceaccount.yaml") . | sha256sum | quote }}
{{- end -}}
{{- end }}
{{/* End of generateRolloutAnnotations */}}

{{/* Generate frontend configmap dynamic data */}}
{{- define "interop-eks-microservice-chart.generateFrontendConfigmapData" -}}
{{- $givenContext :=  .context }}
{{- if and $givenContext.Values.frontend (hasKey $givenContext.Values.frontend "env.js") }}
{{- range $key, $val := $givenContext.Values.frontend }}
{{/* $key is env.js */}}
{{- if eq $key "env.js" }}
{{ $key }}: |-
{{- /* json_key = window.pagopa_env */ -}}
{{- range $json_key, $json_val := $val }}
{{- $windowVar := dict }}
{{- range $subKey, $subValue := $json_val }}
{{- if eq $subKey "fromConfigmaps" }}
{{- if $givenContext.Values.enableLookup }}
{{- /* fromConfigmapsSubKey is a sub key in fromConfigmaps */ -}}
{{- /* fromConfigmapsSubValue is a complex value in the format CONFIGMAP_NAME.CONFIGMAP_KEY */ -}}
{{- range $fromConfigmapsSubKey, $fromConfigmapsSubValue := $subValue }}
{{- if not (hasKey $windowVar $fromConfigmapsSubKey) }}
{{- $configmapAddress := mustRegexSplit "\\." $fromConfigmapsSubValue 2 }}
{{- $configmapName := index $configmapAddress 0 }}
{{- $configmapKey := index $configmapAddress 1 }}
{{- $configMapData := (lookup "v1" "ConfigMap" $givenContext.Values.namespace $configmapName) }}
{{- if not $configMapData }}
{{- fail (printf "Error: ConfigMap %s not found in namespace %s" $configmapName $givenContext.Values.namespace) }}
{{- end }} {{/* if not $configMapData */}}
{{- if hasKey (index $configMapData "data") $configmapKey }}
{{- /* If the configmap key exists, we add it to the windowVar */ -}}
{{- $configMapValue := (index (index $configMapData "data") $configmapKey) }}
{{- if $configMapValue }}
{{- $windowVar = merge $windowVar (dict $fromConfigmapsSubKey $configMapValue) }}
{{- else }}
{{ fail (printf "Error: ConfigMap value for key %s in %s not found, namespace %s" $configmapKey $configmapName $givenContext.Values.namespace) }}
{{- end }} {{/* if not $configMapValue */}}
{{- else }}
{{ fail (printf "Error: ConfigMap key %s not found in ConfigMap %s, namespace %s" $configmapKey $configmapName $givenContext.Values.namespace) }}
{{- end }} {{/* if hasKey (index $configMapData "data") $configmapKey */}}
{{- end }} {{/* if not (hasKey $windowVar $fromConfigmapsSubKey) */}}
{{- end }} {{/* range $fromConfigmapsSubKey, $fromConfigmapsSubValue := $subValue */}}
{{- end }} {{/* if $givenContext.Values.enableLookup */}}
{{- else }}
{{- if not (hasKey $windowVar $subKey) }}
{{- $renderedVal := include "interop-eks-microservice-chart.render-template" (dict "value" $subValue "context" $givenContext) }}
{{- $windowVar = merge $windowVar (dict $subKey $renderedVal) }}
{{- end }}
{{- end }}
{{- end }}
{{- $json_key | nindent 2 }} = {{- $windowVar | toPrettyJson | nindent 4 }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}

{{/* End of generateFrontendConfigmapData */}}

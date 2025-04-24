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
{{- $imageTag = (nospace .Values.deployment.image.tag) }}
app.kubernetes.io/version: {{ $imageTag }}
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

{{- if contains "{{" (toJson $value) }}
  {{- $givenScope := .scope }}
  {{- $givenContext := .context }}

  {{- include "interop-eks-microservice-chart.check-tpl-value" (dict "value" $value "context" $givenContext "scope" $givenScope) -}}
  {{- include "interop-eks-microservice-chart.render-tpl-value" (dict "value" $value "context" $givenContext "scope" $givenScope) -}}
{{- else }}
  {{- $value -}}
{{- end -}}
{{- end -}}

{{/*
Generate annotations (in deployment.spec.template.metadata) for each configmap and secret referenced by the deployment.
Usage:
{{ include "interop-eks-microservice-chart.generateRolloutAnnotations" }}
*/}}
{{- define "interop-eks-microservice-chart.generateRolloutAnnotations" -}}

{{- if and .Values.deployment .Values.deployment.enableRolloutAnnotations -}}
{{ .Values.name }}/configmap.sha256: {{ include (print $.Template.BasePath "/configmap.yaml") . | sha256sum | quote }}
{{- end }}

{{- if and .Values.deployment .Values.deployment.envFromConfigmaps .Values.deployment.enableRolloutAnnotations }}
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

{{- if and .Values.deployment .Values.deployment.flywayInitContainer.migrationsConfigmap .Values.deployment.enableRolloutAnnotations }}
{{- $configmapName := .Values.deployment.flywayInitContainer.migrationsConfigmap }}
{{- $configmap := lookup "v1" "ConfigMap" $.Values.namespace $configmapName }}
{{- if $configmap }}
{{ $configmapName }}/flywayConfigmap.resourceVersion: {{ $configmap.metadata.resourceVersion | quote }}
{{- end }}
{{- end }}

{{- if and .Values.deployment .Values.deployment.envFromSecrets .Values.deployment.enableRolloutAnnotations }}
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

{{- if and .Values.deployment .Values.deployment.flywayInitContainer.envFromSecrets .Values.deployment.enableRolloutAnnotations}}
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

{{- end -}}
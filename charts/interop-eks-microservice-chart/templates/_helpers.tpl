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
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
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

  {{- $pattern := `{{\.Values[^}]+}}` -}}
  {{- $valuesMatches := (regexFindAll $pattern $givenValue -1) }}
  {{- $matchesCount := len $valuesMatches -}}
  
  {{/* For every match check if the rendered template is valid, i.e. not empty/null */}}
  {{- range $index, $match := $valuesMatches }}
    {{- $renderedValue := include "interop-eks-microservice-chart.render-tpl-value" (dict "value" $match "context" $givenContext "scope" $givenScope) -}}
    {{- if or (eq $renderedValue nil) (eq $renderedValue "")  }}
      {{ fail (printf "Error: %s must be set and non-empty" $givenValue) }}
    {{- end }}
  {{- end }}
{{- end -}}


{{- define "interop-eks-microservice-chart.render-tpl-value" -}}
  {{- $givenValue := .value }}
  {{- $givenContext := .context }}
  {{- $givenScope := .scope }}
  {{- $renderedValue := "" -}}
  
  {{- if and (ne $givenScope nil) (ne $givenScope "") }}  
    {{- $renderedValue = tpl (cat "{{- with $.RelativeScope -}}" $givenValue "{{- end }}") (merge (dict "RelativeScope" $givenScope) $givenContext) }}
  {{- else }}
    {{- $renderedValue = tpl $givenValue $givenContext }}
  {{- end }}

  {{- $renderedValue }}
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

  {{- $renderedValue := include "interop-eks-microservice-chart.render-tpl-value" (dict "value" $value "context" $givenContext "scope" $givenScope) -}}
  {{- $renderedValue -}}

{{- else }}
    {{- $value -}}
{{- end -}}
{{- end -}}
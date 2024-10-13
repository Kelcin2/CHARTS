{{/*
Expand the name of the chart.
*/}}
{{- define "ray-serve.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "ray-serve.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
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
{{- define "ray-serve.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "ray-serve.labels" -}}
helm.sh/chart: {{ include "ray-serve.chart" . }}
{{ include "ray-serve.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "ray-serve.selectorLabels" -}}
app.kubernetes.io/name: {{ include "ray-serve.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "ray-serve.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "ray-serve.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}


{{/*
Calculate if model enabled
*/}}
{{- define "ray-serve.modelEnabled" -}}
{{- if "enabled" | hasKey . | not | or .enabled }}
{{- print "true" }}
{{- else }}
{{- print "false" }}
{{- end }}
{{- end }}

{{/*
Calculate model gpus or cpus
*/}}
{{- define "ray-serve.CalXpus" -}}
{{- $models := list -}}
{{- $type := .type -}}
{{- $totalXpuNum := $type | eq "gpu" | ternary .Values.deployment.rayServe.modelConfig.numGpus .Values.deployment.rayServe.modelConfig.numCpus -}}
{{- if and ($totalXpuNum | empty | not) (gt (int64 $totalXpuNum) 0) -}}
  {{- $totalModelNumNotConfiguredXpu := 0 -}}
  {{- range .models }}
    {{- $modelXpuNum := $type | eq "gpu" | ternary (dig "numGpus" 0.0 .) (dig "numCpus" 0.0 .) -}}
    {{- if and ($modelXpuNum | empty | not) (0 | float64 | gt $modelXpuNum) -}}
      {{- $totalXpuNum = $modelXpuNum | subf $totalXpuNum -}}
      {{- if 0 | float64 | lt $totalXpuNum -}}
        {{- printf "The sum of the %s for each model exceeds the total number of %s configured" $type $type | fail -}}
      {{- end -}}
    {{- else -}}
      {{- $totalModelNumNotConfiguredXpu = $totalModelNumNotConfiguredXpu | add1 -}}
    {{- end -}}
  {{- end }}
  {{- $xpuNumPerModel := 0 | float64 -}}
  {{- if gt $totalModelNumNotConfiguredXpu 0 -}}
    {{- if le $totalXpuNum 0.0 -}}
      {{- printf "There are also %d models not configured %s, but the total number of %s left is %f, which is not enough to allocate to the remaining models" $totalModelNumNotConfiguredXpu $type $type $totalXpuNum | fail -}}
    {{- end -}}
    {{- $xpuNumPerModel = $totalModelNumNotConfiguredXpu | float64 | divf $totalXpuNum | mulf 1000000 | int64 -}}
    {{- $xpuNumPerModel = divf $xpuNumPerModel 1000000 -}}
  {{- end -}}
  {{- range .models }}
    {{- $modelXpuNum := $type | eq "gpu" | ternary (dig "numGpus" 0.0 .) (dig "numCpus" 0.0 .) -}}
    {{- if and ($modelXpuNum | empty | not) (0 | float64 | gt $modelXpuNum) -}}
      {{- $models = . | append $models -}}
    {{- else -}}
      {{- $models = $xpuNumPerModel | set . ($type | eq "gpu" | ternary "numGpus" "numCpus") | append $models -}}
    {{- end -}}
  {{- end }}
{{- else -}}
  {{- if $type | eq "gpu" -}}
    {{- range .models }}
      {{- $models = unset . "numGpus" | append $models -}}
    {{- end }}
  {{- else -}}
    {{- range .models }}
      {{- $models = 0 | set . "numCpus" | append $models -}}
    {{- end }}
  {{- end -}}
{{- end -}}
{{- $models | toJson | print -}}
{{- end }}

{{/*
Calculate model config
*/}}
{{- define "ray-serve.CalModelConfig" -}}
{{- $models := list -}}
{{- if .group | hasKey .Values.deployment.rayServe.modelConfig.models | not }}
{{- printf "can't find the group `%s`" .group | fail -}}
{{- end }}
{{- range "models" | get (get .Values.deployment.rayServe.modelConfig.models .group) }}
{{- if include "ray-serve.modelEnabled" . | eq "true" }}
{{- $models = . | append $models -}}
{{- end }}
{{- end }}
{{- $models = include "ray-serve.CalXpus" (dict "Values" .Values "type" "gpu" "models" $models) | fromJsonArray -}}
{{- $models = include "ray-serve.CalXpus" (dict "Values" .Values "type" "cpu" "models" $models) | fromJsonArray -}}
{{- $models | toJson | print -}}
{{- end }}

{{/*
Standardize the group name
*/}}
{{- define "ray-serve.standardizeGroupName" -}}
  {{- if "group" | hasKey . | not }}
  {{- print "" -}}
  {{- else if eq "rayServe" .group  }}
  {{- print "" -}}
  {{- else }}
  {{- .group | snakecase | replace "_" "-" | lower | printf "-%s" -}}
  {{- end }}
{{- end }}
{{/*
Expand the name of the chart.
*/}}
{{- define "vllm-cpu.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "vllm-cpu.fullname" -}}
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
{{- define "vllm-cpu.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "vllm-cpu.labels" -}}
helm.sh/chart: {{ include "vllm-cpu.chart" . }}
{{ include "vllm-cpu.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "vllm-cpu.selectorLabels" -}}
app.kubernetes.io/name: {{ include "vllm-cpu.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "vllm-cpu.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "vllm-cpu.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
get the custom chat template file name
*/}}
{{- define "vllm-cpu.getChatTemplateFileName" -}}
{{- if .Values.deployment.vllm.customChatTemplate }}
{{- printf "template_%s.jinja" .Values.deployment.vllm.customChatTemplate }}
{{- else }}
{{- fail "deployment.vllm.customChatTemplate MUST be not empty!" }}
{{- end }}
{{- end }}
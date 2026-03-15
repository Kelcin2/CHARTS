{{/*
Expand the name of the chart.
*/}}
{{- define "my-openclaw.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "my-openclaw.fullname" -}}
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
{{- define "my-openclaw.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "my-openclaw.labels" -}}
helm.sh/chart: {{ include "my-openclaw.chart" . }}
{{ include "my-openclaw.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "my-openclaw.selectorLabels" -}}
app.kubernetes.io/name: {{ include "my-openclaw.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "my-openclaw.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "my-openclaw.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Generate the auth token for openclaw.
*/}}
{{- define "my-openclaw.genAuthToken" -}}
{{- 64 | randAlphaNum | lower | print -}}
{{- end }}


{{/*
get the auth token for openclaw.
Get the token from root context firstly,
if exist, then use it directly,
if not exist,
    If deployment.openclaw.generateNewToken is true, then generate a new token and set it to root context, and use it directly.
    If deployment.openclaw.generateNewToken is false, then get the token from openclaw-secret in current namespace.
        if found, then set it to root context and use it,
        if not found, then generate a new token, set it to root context and use it.
*/}}
{{- define "my-openclaw.getAuthToken" -}}
{{- $token := .Values._authToken -}}
{{- if empty $token }}
  {{- if .Values.deployment.openclaw.generateNewToken }}
    {{- $token = (include "my-openclaw.genAuthToken" .) -}}
  {{- else }}
    {{- $secret := (lookup "v1" "Secret" .Release.Namespace "openclaw-secret") -}}
    {{- $token = $secret | default dict | dig "data" "_authToken" "" -}}
    {{- if empty $token | not  }}
      {{- $token = $token | b64dec -}}
     {{- else }}
      {{- $token = (include "my-openclaw.genAuthToken" .) -}}
    {{- end }}
  {{- end }}
{{- $_ := $token | set .Values "_authToken" -}}
{{- end }}
{{- print $token -}}
{{- end }}

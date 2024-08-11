{{/*
Expand the name of the chart.
*/}}
{{- define "volume-config.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "volume-config.fullname" -}}
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
{{- define "volume-config.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "volume-config.labels" -}}
helm.sh/chart: {{ include "volume-config.chart" . }}
{{ include "volume-config.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "volume-config.selectorLabels" -}}
app.kubernetes.io/name: {{ include "volume-config.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "volume-config.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "volume-config.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}


{{/*
Get NFS Server IP
*/}}
{{- define "volume-config.getNfsServer" -}}
{{- $nfsHost := .Values.deployment.volumeConfig.nfsServer.host -}}
{{- $nfsSvcNamespace := .Values.deployment.volumeConfig.nfsServer.svcNamespace -}}
{{- $nfsSvcName := .Values.deployment.volumeConfig.nfsServer.svcName -}}
{{- $nfsServer := "" -}}
{{- if $nfsHost -}}
{{- $nfsServer = $nfsHost -}}
{{- else -}}
{{- $nfsSvcNamespace = required "deployment.volumeConfig.nfsServer.svcNamespace can not be empty if host is empty!" $nfsSvcNamespace -}}
{{- $nfsSvcName = required "deployment.volumeConfig.nfsServer.svcName can not be empty if host is empty!" $nfsSvcName -}}
{{- $nfsServer = lookup "v1" "Service" $nfsSvcNamespace $nfsSvcName -}}
{{- $nfsServer = required (printf "Can not find svc `%s` in namepace `%s`! Please Check!" $nfsSvcName $nfsSvcNamespace) $nfsServer -}}
{{- $nfsServer = dig "spec" "clusterIP" "" $nfsServer -}}
{{- $nfsServer = required (printf "Can not find the clusterIP of the svc `%s` in namepace `%s`! Please Check!" $nfsSvcName $nfsSvcNamespace) $nfsServer -}}
{{ print $nfsServer }}
{{- end -}}
{{- end }}

{{/*
Get NFS version option
*/}}
{{- define "volume-config.getNfsServerVersionOption" -}}
{{- if .Values.deployment.volumeConfig.nfsServer.version }}
mountOptions:
  - nfsvers={{ .Values.deployment.volumeConfig.nfsServer.version }}
{{- end }}
{{- end }}
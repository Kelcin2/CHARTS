{{/*
Expand the name of the chart.
*/}}
{{- define "nfs-client-provisioner.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "nfs-client-provisioner.fullname" -}}
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
{{- define "nfs-client-provisioner.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "nfs-client-provisioner.labels" -}}
helm.sh/chart: {{ include "nfs-client-provisioner.chart" . }}
{{ include "nfs-client-provisioner.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "nfs-client-provisioner.selectorLabels" -}}
app.kubernetes.io/name: {{ include "nfs-client-provisioner.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "nfs-client-provisioner.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "nfs-client-provisioner.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Get NFS Server IP
*/}}
{{- define "nfs-client-provisioner.getNfsServer" -}}
{{- $nfsHost := .Values.deployment.nfsClientProvisioner.nfsServer.host -}}
{{- $nfsSvcNamespace := .Values.deployment.nfsClientProvisioner.nfsServer.svcNamespace -}}
{{- $nfsSvcName := .Values.deployment.nfsClientProvisioner.nfsServer.svcName -}}
{{- $nfsServer := "" -}}
{{- if $nfsHost -}}
{{- $nfsServer = $nfsHost -}}
{{- else -}}
{{- $nfsSvcNamespace = required "deployment.nfsClientProvisioner.nfsServer.svcNamespace can not be empty if host is empty!" $nfsSvcNamespace -}}
{{- $nfsSvcName = required "deployment.nfsClientProvisioner.nfsServer.svcName can not be empty if host is empty!" $nfsSvcName -}}
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
{{- define "nfs-client-provisioner.getNfsServerVersionOption" -}}
{{- if .Values.deployment.nfsClientProvisioner.nfsServer.version }}
mountOptions:
  - nfsvers={{ .Values.deployment.nfsClientProvisioner.nfsServer.version }}
{{- end }}
{{- end }}
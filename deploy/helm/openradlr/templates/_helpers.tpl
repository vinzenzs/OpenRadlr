{{- define "openradlr.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "openradlr.fullname" -}}
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

{{- define "openradlr.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "openradlr.selectorLabels" -}}
app.kubernetes.io/name: {{ include "openradlr.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "openradlr.labels" -}}
helm.sh/chart: {{ include "openradlr.chart" . }}
{{ include "openradlr.selectorLabels" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "openradlr.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "openradlr.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{- define "openradlr.image" -}}
{{- $repo := required "image.repository is required" .Values.image.repository }}
{{- if .Values.image.digest }}
{{- printf "%s@%s" $repo .Values.image.digest }}
{{- else }}
{{- printf "%s:%s" $repo (default .Chart.AppVersion .Values.image.tag) }}
{{- end }}
{{- end }}

{{- define "openradlr.secretName" -}}
{{- default (include "openradlr.fullname" .) .Values.secrets.existingSecret }}
{{- end }}

{{/* Whether the chart has a Secret to read from (its own or an existing one). */}}
{{- define "openradlr.hasSecret" -}}
{{- with .Values.secrets }}
{{- if or .existingSecret .stravaClientId .stravaClientSecret .secretKey }}true{{ end }}
{{- end }}
{{- end }}

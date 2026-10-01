{{- define "sample-app.name" -}}
sample-app
{{- end -}}

{{- define "sample-app.fullname" -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "sample-app.labels" -}}
app.kubernetes.io/name: {{ include "sample-app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version }}
slot: {{ .Values.slot }}
{{- end -}}

{{- define "sample-app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "sample-app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
slot: {{ .Values.slot }}
{{- end -}}

{{- define "sample-app.serviceAccountName" -}}
{{- if .Values.serviceAccount.name -}}
{{- .Values.serviceAccount.name -}}
{{- else -}}
{{- printf "%s-sa" (include "sample-app.fullname" .) -}}
{{- end -}}
{{- end -}}

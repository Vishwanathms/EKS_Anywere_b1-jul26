{{- define "nginx-demo.name" -}}
nginx-demo
{{- end }}

{{- define "nginx-demo.fullname" -}}
nginx-demo
{{- end }}

{{- define "nginx-demo.labels" -}}
app: {{ include "nginx-demo.name" . }}
{{- end }}
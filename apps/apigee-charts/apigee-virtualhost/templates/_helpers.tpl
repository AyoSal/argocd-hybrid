{{/*
  validateTLSProtocols validates TLS version along with the minimum and maximum comparison.
  TODO - need to elabrote this function (https://edge-internal.git.corp.google.com/apigee-hybrid-setup/+/refs/heads/master/tmpl/tmpl_functions.go#169)
*/}}
{{- define "validateTLSProtocols" -}}
{{- if eq .minTLSProtocolVersion "" -}}
{{- empty -}}
{{- else -}}
{{- $mn := float64 .min -}}
{{- $mx := float64 .max -}}
{{ if gt $mn $mx }}
{{- fail printf "tls protocol min value: %s is greater than max %s" .minTLSProtocolVersion .maxTLSProtocolVersion }}
{{- end -}}
{{- end -}}
{{- end -}}


{{/*
  toIstioTLSProtocolVersion
  @param s - version input
*/}}
{{- define "toIstioTLSProtocolVersion" -}}
{{- if eq .s "AUTO" -}}
{{- "TLS_AUTO" -}}  
{{- else if eq .s "1.0" -}}
{{- "TLSV1_0" -}} 
{{- else if eq .s "1.1" -}}
{{- "TLSV1_1" -}} 
{{- else if eq .s "1.2" -}}
{{- "TLSV1_2" -}} 
{{- else if eq .s "1.3" -}}
{{- "TLSV1_3" -}} 
{{- else -}}
{{- fail "supported tls protocol are: auto, 1.0, 1.1, 1.2 and 1.3" }}
{{- end -}}
{{- end -}}

{{/*
  namespace resolves the overridden namespace where a value from --namespace
  flag in the cmd line will have a higher precedence than in the override file
  or the default value from values.yaml.
  @param release - the built in Release object.
  @param values  - the built in Values object.
*/}}
{{- define "namespace" -}}
{{- if eq .release.Namespace "default" -}}
{{- .values.namespace -}}
{{- else -}}
{{- .release.Namespace -}}
{{- end -}}
{{- end -}}
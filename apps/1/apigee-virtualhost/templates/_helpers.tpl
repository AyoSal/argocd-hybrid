{{/*
  Check the helm binary version to ensure that it meets the minimum version
*/}}
{{- define "helmVersionCheck" -}}
{{- if semverCompare "<v3.10.0" .Capabilities.HelmVersion.Version -}}
{{- fail "Please use at least Helm v3.10.0 or above. You can find more about Helm releases and installation at https://github.com/helm/helm/releases." -}}
{{- end -}}
{{- end -}}

{{/*
  Check the target virtualhost exists
*/}}
{{- define "targetVirtualhostCheck" -}}
  {{- $found := false -}}
  {{- range $envgroup := $.Values.virtualhosts -}}
    {{- if eq $envgroup.name $.Values.envgroup -}}
    {{ $found = true -}}
    {{- end -}}
  {{- end -}}
  {{- if not $found -}}
  {{- fail (printf "Virtualhost '%s' not found in the provided virtualhosts. Are you targeting the correct virtualhost (--set envgroup=%s)? Does the target virtualhost exist in the overrides?" .Values.envgroup .Values.envgroup) -}}
  {{- end -}}
{{- end -}}

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

{{/*
  tryFileContent.get returns file content otherwise error if file is empty or unreachable
    @param files - .Files object
    @param f - string filepath
*/}}
{{- define "tryFileContent.get" -}}
{{- $tr := (trimPrefix "./" .f) -}}
{{- $c := .files.Get $tr -}}
{{- if empty $c -}}
{{- fail (printf "'%s' is either an empty file or unreachable" $tr) -}}
{{- else -}}
{{- $c -}}
{{- end -}}
{{- end -}}

{{/*
  container.image returns the image for the given component
    @param hub - string repo base url
    @param o - object component
    @param n - string image name
*/}}
{{- define "container.image" -}}
{{ if .hub }}
{{- printf "%s/%s:%s" .hub .n .o.image.tag -}}
{{ else }}
{{- printf "%s:%s" .o.image.url .o.image.tag -}}
{{- end -}}
{{- end -}}

{{/*
  nodeAffinity.runtime
*/}}
{{- define "nodeAffinity.runtime" -}}
nodeAffinity:
  {{- if .requiredForScheduling }}
  requiredDuringSchedulingIgnoredDuringExecution:
    nodeSelectorTerms:
    - matchExpressions:
      - key: {{ quote (index .apigeeRuntime "key") }}
        operator: In
        values:
        - {{ quote (index .apigeeRuntime "value") }}
  {{- end }}
  preferredDuringSchedulingIgnoredDuringExecution:
  - weight: 100
    preference:
      matchExpressions:
      - key: {{ quote (index .apigeeRuntime "key") }}
        operator: In
        values:
        - {{ quote (index .apigeeRuntime "value") }}
{{- end -}}

{{/*
    suffix name for Guardrails pod
*/}}
{{- define "suffixName" -}}
{{- randNumeric 6 | nospace -}}
{{- end -}}

{{/*
  orgScopeEncodedName
    @param name - string
*/}}
{{- define "orgScopeEncodedName" -}}
{{- if .name -}}
{{- printf "%s-%s" (include "shortName" .name) (include "shortSha" .name) -}}
{{- else -}}
{{ fail "Please provide org name in overrides" }}
{{- end -}}
{{- end -}}

{{/*
  shortName
*/}}
{{- define "shortName" -}}
{{- substr 0 15 . -}}
{{- end -}}

{{/*
  shortSha
*/}}
{{- define "shortSha" -}}
{{- sha256sum . | trunc 7 -}}
{{- end -}}

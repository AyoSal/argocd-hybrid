{{/*
  Check the helm binary version to ensure that it meets the minimum version
*/}}
{{- define "helmVersionCheck" -}}
{{- if semverCompare "<v3.10.0" .Capabilities.HelmVersion.Version -}}
{{- fail "Please use at least Helm v3.10.0 or above. You can find more about Helm releases and installation at https://github.com/helm/helm/releases." -}}
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
  namespace resolves the overridden namespace where a value from --namespace
  flag in the cmd line will have a higher precedence than in the override file
  or the default value from values.yaml.
*/}}
{{- define "namespace" -}}
{{- if eq .Release.Namespace "default" -}}
{{- .Values.namespace -}}
{{- else -}}
{{- .Release.Namespace -}}
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
  metricsSA resolves the metrics service account from values.
*/}}
{{- define "metricsSA" -}}
  {{- $metricsName := "apigee-metrics" }}
  {{- $telemetryName := "apigee-telemetry" -}}
  {{- $generatedName := include "orgScopeEncodedName" (dict "name" .Values.org) -}}
  {{- if .Values.gcp.workloadIdentity.enabled -}}
  {{- printf "%s-sa" $metricsName -}}
  {{- else if .Values.multiOrgCluster -}}
  {{- printf "%s-%s" $metricsName $generatedName -}}
  {{- else -}}
  {{- printf "%s-%s" $metricsName $telemetryName -}}
  {{- end -}}
{{- end -}}

{{/*
  metricsAdapterSA resolves the previous metrics adapter service account name.
*/}}
{{- define "metricsAdapterSA" -}}
  {{- printf "apigee-metrics-adapter-apigee-telemetry" -}}
{{- end -}}

{{/*
  metricsAdapterName resolves the metrics adapter service account name.
*/}}
{{- define "metricsAdapterName" -}}
  {{- printf "apigee-metrics-adapter" -}}
{{- end -}}

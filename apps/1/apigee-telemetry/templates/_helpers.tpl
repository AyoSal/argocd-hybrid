{{/*
  Check the helm binary version to ensure that it meets the minimum version
*/}}
{{- define "helmVersionCheck" -}}
{{- if semverCompare "<v3.10.0" .Capabilities.HelmVersion.Version -}}
{{- fail "Please use at least Helm v3.10.0 or above. You can find more about Helm releases and installation at https://github.com/helm/helm/releases." -}}
{{- end -}}
{{- end -}}

{{/*
  validateVersion
    @param version - version
*/}}
{{- define "validateVersion" -}}
{{- $v := lower .version | replace "." "" }}
{{- if mustRegexMatch "^[a-z0-9]([a-z0-9-]*[a-z0-9])?$" $v }}
{{- $v -}}
{{- else -}}
{{- fail "version .version is not a valid format" }}
{{- end -}}
{{- end -}}

{{/*
  nodeAffinity.both
*/}}
{{- define "nodeAffinity.both" -}}
nodeAffinity:
  {{- if .requiredForScheduling }}
  requiredDuringSchedulingIgnoredDuringExecution:
    nodeSelectorTerms:
    - matchExpressions:
      - key: {{ quote (index .apigeeRuntime "key") }}
        operator: In
        values:
        - {{ quote (index .apigeeRuntime "value") }}
    - matchExpressions:
      - key: {{ quote (index .apigeeData "key") }}
        operator: In
        values:
        - {{ quote (index .apigeeData "value") }}
  {{- end }}
  preferredDuringSchedulingIgnoredDuringExecution:
  - weight: 100
    preference:
      matchExpressions:
      - key: {{ quote (index .apigeeRuntime "key") }}
        operator: In
        values:
        - {{ quote (index .apigeeRuntime "value") }}
      - key: {{ quote (index .apigeeData "key") }}
        operator: In
        values:
        - {{ quote (index .apigeeData "value") }}
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
  fwi.enabled will return true if federated workload identity is enabled
  It will also validate the FWI configuration
*/}}
{{- define "fwi.enabled" -}}
    {{- if .Values.gcp.federatedWorkloadIdentity.enabled -}}
        {{- if .Values.gcp.workloadIdentity.enabled -}}
            {{- fail "gcp.workloadIdentity.enabled must be false to use federated workload identity" -}}
        {{- end -}}
        {{- if empty .Values.gcp.federatedWorkloadIdentity.audience -}}
            {{- fail "audience required for federatedWorkloadIdentity" -}}
        {{- end -}}
        {{- if empty .Values.gcp.federatedWorkloadIdentity.credentialSourceFile -}}
            {{- fail "credentialSourceFile required for federatedWorkloadIdentity" -}}
        {{- end -}}
        {{- if or (empty .Values.gcp.federatedWorkloadIdentity.tokenExpiration) (lt (int64 .Values.gcp.federatedWorkloadIdentity.tokenExpiration) 600) -}}
            {{- fail "tokenExpiration >= 600 required for federatedWorkloadIdentity" -}}
        {{- end -}}
        {{- print true -}}
    {{- end -}}
{{- end -}}

{{- define "fwi.tokenPath" -}}
    {{- print (clean (dir .Values.gcp.federatedWorkloadIdentity.credentialSourceFile)) -}}
{{- end -}}

{{- define "fwi.tokenFile" -}}
    {{- print (base .Values.gcp.federatedWorkloadIdentity.credentialSourceFile) -}}
{{- end -}}

{{/*
  loggerGSAName
*/}}
{{- define "loggerGSAName" -}}
{{- if .Values.multiOrgCluster -}}
{{- $generatedName := include "orgScopeEncodedName" (dict "name" .Values.org) -}}
apigee-logger-{{ $generatedName }}-svc-account
{{- else -}}
apigee-logger-svc-account
{{- end -}}
{{- end -}}


{{/*
  loggerSAName
*/}}
{{- define "loggerSAName" -}}
{{- if .Values.multiOrgCluster -}}
{{- $generatedName := include "orgScopeEncodedName" (dict "name" .Values.org) -}}
apigee-logger-{{ $generatedName }}-sa
{{- else -}}
apigee-logger-apigee-telemetry
{{- end -}}
{{- end -}}


{{/*
  metricsGSAName
*/}}
{{- define "metricsGSAName" -}}
{{- if .Values.multiOrgCluster -}}
{{- $generatedName := include "orgScopeEncodedName" (dict "name" .Values.org) -}}
apigee-metrics-{{ $generatedName }}-svc-account
{{- else -}}
apigee-metrics-svc-account
{{- end -}}
{{- end -}}


{{/*
  metricsSAName
*/}}
{{- define "metricsSAName" -}}
{{- if .Values.multiOrgCluster -}}
{{- $generatedName := include "orgScopeEncodedName" (dict "name" .Values.org) -}}
apigee-metrics-{{ $generatedName }}-sa
{{- else -}}
apigee-metrics-sa
{{- end -}}
{{- end -}}


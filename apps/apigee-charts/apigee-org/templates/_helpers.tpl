{{/*
  validateInstanceID
    @param s - instance ID 
*/}}
{{- define "validateInstanceID" -}}
{{- $l := len .s -}}
{{- if lt $l 63 }}
{{- .s -}}
{{- else -}}
{{- fail "instanceID .s has to be less than 63 chars long but got $l" }}
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
  nodeAffinity.runtime
*/}}
{{- define "nodeAffinity.runtime" -}}
nodeAffinity:
  requiredDuringSchedulingIgnoredDuringExecution: 
    nodeSelectorTerms:
    - matchExpressions:
      - key: {{ quote (index .apigeeRuntime "key") }}
        operator: In 
        values:
        - {{ quote (index .apigeeRuntime "value") }}
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
  validateEncryptionKey
    @param key - string
*/}}
{{- define "validateEncryptionKey" -}}
{{- $i := .key | b64dec -}}
{{- if or (eq (len $i) 16) (eq (len $i) 24) (eq (len $i) 32) -}}
{{- $i -}}
{{- else -}}
{{- fail (printf "encryption key '%s' with length %v is not valid (valid length is either 16 or 24 oor 32)" $i (len $i)) -}}
{{- end -}}
{{- end -}}


{{/*
  hyphenToUnderscoreUpper
    @param s - string 
*/}}
{{- define "hyphenToUnderscoreUpper" -}}
{{- print .s | upper | replace "-" "_" -}}
{{- end -}}


{{/*
  getIngressGatewayImage
    @param s - string
*/}}
{{- define "getIngressGatewayImage" -}}
{{- if and .image .image.url -}}
{{- .image.url -}}
{{- else -}}
{{- .s -}}
{{- end -}}
{{- end -}}

{{/*
  getIngressGatewayImageTag
*/}}
{{- define "getIngressGatewayImageTag" -}}
{{- default .Values.apigeeIngressGateway.image.tag .image.tag -}}
{{- end -}}

{{/*
  getIngressGatewayImagePullPolicy
*/}}
{{- define "getIngressGatewayTag" -}}
{{- default .Values.apigeeIngressGateway.image.pullPolicy .image.pullPolicy -}}
{{- end -}}

{{/*
  getIngressGatewayReplicaCountMin
*/}}
{{- define "getIngressGatewayReplicaCountMin" -}}
{{- default .Values.apigeeIngressGateway.replicaCountMin .replicaCountMin -}}
{{- end -}}

{{/*
  getIngressGatewayReplicaCountMax
*/}}
{{- define "getIngressGatewayReplicaCountMax" -}}
{{- default .Values.apigeeIngressGateway.replicaCountMax .replicaCountMax -}}
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
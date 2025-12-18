{{/*
  Check the helm binary version to ensure that it meets the minimum version
*/}}
{{- define "helmVersionCheck" -}}
{{- if semverCompare "<v3.10.0" .Capabilities.HelmVersion.Version -}}
{{- fail "Please use at least Helm v3.10.0 or above. You can find more about Helm releases and installation at https://github.com/helm/helm/releases." -}}
{{- end -}}
{{- end -}}

{{/*
  Check the target env exists
*/}}
{{- define "targetEnvCheck" -}}
  {{- $found := false -}}
  {{- range $env := $.Values.envs -}}
    {{- if eq $env.name $.Values.env -}}
    {{ $found = true -}}
    {{- end -}}
  {{- end -}}
  {{- if not $found -}}
  {{- fail (printf "Environment '%s' not found in the provided environments. Are you targeting the correct environment (--set env=%s)? Does the target environment exist in the overrides?" .Values.env .Values.env) -}}
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
  envScopeEncodedName
    @param org - string
    @param env - string
*/}}
{{- define "envScopeEncodedName" -}}
{{- if and .org .env  -}}
{{- printf "%s-%s-%s" (include "shortName" .org) (include "shortName" .env) (include "shortSha" (printf "%s:%s" .org .env)) -}}
{{- else -}}
{{ fail "Please provide org and env name" }}
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
  validateEncryptionKey
    @param key - string 

    TODO - check for or ((len $i) eq 16) ((len $i) eq 24) ((len $i) eq 32) 
*/}}
{{- define "validateEncryptionKey" -}}
{{- $i := .key | b64dec -}}
{{- if or (eq (len $i) 16) (eq (len $i) 24) (eq (len $i) 32) -}}
{{- $i -}}
{{- else -}}
{{- fail (printf "encryption key '%s' with length %v is not valid (valid length is either 16 or 24 or 32" $i (len $i)) -}}
{{- end -}}
{{- end -}}


{{/*
    getSynchronizerReplicaMin
    @param value - default value
    @param env   - env interface
*/}}
{{- define "getSynchronizerReplicaMin" -}}
{{- if and .env.components .env.components.synchronizer .env.components.synchronizer.replicaCountMin -}}
{{- .env.components.synchronizer.replicaCountMin -}}
{{- else -}}
{{- .value -}}
{{- end -}}
{{- end -}}

{{/*
    getSynchronizerReplicaMax
    @param value - default value
    @param env   - env interface
*/}}
{{- define "getSynchronizerReplicaMax" -}}
{{- if and .env.components .env.components.synchronizer .env.components.synchronizer.replicaCountMax -}}
{{- .env.components.synchronizer.replicaCountMax -}}
{{- else -}}
{{- .value -}}
{{- end -}}
{{- end -}}

{{/*
    getUDCAReplicaMin
    @param value - default value
    @param env   - env interface
*/}}
{{- define "getUDCAReplicaMin" -}}
{{- if and .env.components .env.components.udca .env.components.udca.replicaCountMin -}}
{{- .env.components.udca.replicaCountMin -}}
{{- else -}}
{{- .value -}}
{{- end -}}
{{- end -}}

{{/*
    getUDCAReplicaMax
    @param value - default value
    @param env   - env interface
*/}}
{{- define "getUDCAReplicaMax" -}}
{{- if and .env.components .env.components.udca .env.components.udca.replicaCountMax -}}
{{- .env.components.udca.replicaCountMax -}}
{{- else -}}
{{- .value -}}
{{- end -}}
{{- end -}}


{{/*
    getRuntimeReplicaMin
    @param value - default value
    @param env   - env interface
*/}}
{{- define "getRuntimeReplicaMin" -}}
{{- if and .env.components .env.components.runtime .env.components.runtime.replicaCountMin -}}
{{- .env.components.runtime.replicaCountMin -}}
{{- else -}}
{{- .value -}}
{{- end -}}
{{- end -}}

{{/*
    getRuntimeReplicaMax
    @param value - default value
    @param env   - env interface
*/}}
{{- define "getRuntimeReplicaMax" -}}
{{- if and .env.components .env.components.runtime .env.components.runtime.replicaCountMax -}}
{{- .env.components.runtime.replicaCountMax -}}
{{- else -}}
{{- .value -}}
{{- end -}}
{{- end -}}

{{/*
    getRuntimeResources
    @param value - default value
    @param env   - env interface
*/}}
{{- define "getRuntimeResources" -}}
{{- if and .env.components .env.components.runtime .env.components.runtime.resources -}}
  {{- toYaml .env.components.runtime.resources -}}
{{- else if .value -}}
  {{- toYaml .value -}}
{{- end -}}
{{- end -}}

{{/*
    getRuntimeEnvCWC
    @param env   - env interface
    @param default - cwcAppend
*/}}
{{- define "getRuntimeEnvCWC" -}}
{{- $mergedCwc := dict -}}
{{- if .default -}}
  {{- $mergedCwc = mergeOverwrite $mergedCwc .default -}}
{{- end -}}
{{- if and .env.components .env.components.runtime .env.components.runtime.cwcAppend -}}
  {{- $mergedCwc = mergeOverwrite $mergedCwc .env.components.runtime.cwcAppend -}}
{{- end -}}
{{- if $mergedCwc -}}
    {{- $mergedCwc | toYaml -}}
{{- end -}}
{{- end -}}

{{/*
    getRuntimeGSA
    @param value - default value
    @param env   - env interface
*/}}
{{- define "getRuntimeGSA" -}}
{{- if and .env.gsa .env.gsa.runtime -}}
{{- .env.gsa.runtime -}}
{{- else -}}
{{- .value -}}
{{- end -}}
{{- end -}}

{{/*
    getSynchronizerGSA
    @param value - default value
    @param env   - env interface
*/}}
{{- define "getSynchronizerGSA" -}}
{{- if and .env.gsa .env.gsa.synchronizer -}}
{{- .env.gsa.synchronizer -}}
{{- else -}}
{{- .value -}}
{{- end -}}
{{- end -}}

{{/*
    getUdcaGSA
    @param value - default value
    @param env   - env interface
*/}}
{{- define "getUdcaGSA" -}}
{{- if and .env.gsa .env.gsa.udca -}}
{{- .env.gsa.udca -}}
{{- else -}}
{{- .value -}}
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
    @param values  - the built in Values object.
*/}}
{{- define "fwi.enabled" -}}
    {{- if .values.gcp.federatedWorkloadIdentity.enabled -}}
        {{- if .values.gcp.workloadIdentity.enabled -}}
            {{- fail "gcp.workloadIdentity.enabled must be false to use federated workload identity" -}}
        {{- end -}}
        {{- if empty .values.gcp.federatedWorkloadIdentity.audience -}}
            {{- fail "audience required for federatedWorkloadIdentity" -}}
        {{- end -}}
        {{- if empty .values.gcp.federatedWorkloadIdentity.credentialSourceFile -}}
            {{- fail "credentialSourceFile required for federatedWorkloadIdentity" -}}
        {{- end -}}
        {{- if or (empty .values.gcp.federatedWorkloadIdentity.tokenExpiration) (lt (int64 .values.gcp.federatedWorkloadIdentity.tokenExpiration) 600) -}}
            {{- fail "tokenExpiration >= 600 required for federatedWorkloadIdentity" -}}
        {{- end -}}
        {{- print true -}}
    {{- end -}}
{{- end -}}

{{/*
    @param values  - the built in Values object.
*/}}
{{- define "fwi.tokenPath" -}}
    {{- print (clean (dir .values.gcp.federatedWorkloadIdentity.credentialSourceFile)) -}}
{{- end -}}

{{/*
    @param values  - the built in Values object.
*/}}
{{- define "fwi.tokenFile" -}}
    {{- print (base .values.gcp.federatedWorkloadIdentity.credentialSourceFile) -}}
{{- end -}}

{{/*
    suffix name for Guardrails pod
*/}}
{{- define "suffixName" -}}
{{- randNumeric 6 | nospace -}}
{{- end -}}

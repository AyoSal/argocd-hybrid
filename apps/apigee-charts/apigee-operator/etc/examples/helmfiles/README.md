## Helmfile

[Helmfile](https://github.com/helmfile/helmfile) is a declarative spec for deploying helm charts


## Installation
For installation, please follow the instruction [here](https://helmfile.readthedocs.io/en/latest/#installation)

`helmfile` requires `diff` plugin, please use below command to install that
```
helm plugin install https://github.com/databus23/helm-diff
```

## Usage
```
helmfile apply [-f helmfile.yaml]
```
`helmfile.yaml` has a basic example of installing Apigee Helm Charts


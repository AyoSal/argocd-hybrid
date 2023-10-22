#!/usr/bin/env bash

# Exit immediately if sequence of one or more commands returns a non-zero status.
set -e

PWD=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)

# shellcheck disable=SC1090
source "${PWD}/common.sh"

# read the tag from the ../Chart.yaml
TAG=$(cat "${PWD}"/../../Chart.yaml | grep 'version:' | awk '{print $2}')
REPO=$1

# source image repo
GOOGLE_IMG_REPO="gcr.io/apigee-release/hybrid"
# images
APIGEE_COMPONENTS=( \
	"apigee-mart-server" \
	"apigee-synchronizer" \
	"apigee-runtime" \
	"apigee-hybrid-cassandra-client" \
	"apigee-hybrid-cassandra" \
	"apigee-cassandra-backup-utility" \
	"apigee-udca" \
	"apigee-connect-agent" \
	"apigee-watcher" \
	"apigee-operators" \
	"apigee-redis" \
	"apigee-mint-task-scheduler" \
)

THIRD_PARTY_COMPONENTS=( \
	"apigee-stackdriver-logging-agent:1.9.12-2" \
	"apigee-prom-prometheus:v2.45.0" \
	"apigee-stackdriver-prometheus-sidecar:0.9.0" \
	"apigee-kube-rbac-proxy:v0.14.2" \
	"apigee-envoy:v1.27.0" \
	"apigee-prometheus-adapter:v0.11.0" \
	"apigee-asm-ingress:1.17.2-asm.8-distroless" \
	"apigee-asm-istiod:1.17.2-asm.8-distroless" \
	"apigee-fluent-bit:2.1.8" \
)

#**
# @brief    Displays usage details.
#
usage() {
    log_info "$*\\n usage: $(basename "$0")" \
        "[repo where you want to push the images]\\n" \
        "Note: if the repo is not provided. It will be pushed to us.gcr.io/<PROJECT_ID>.\\n" \
        "      Please make sure you have gcloud installed as it uses for finding out PROJECT_ID\\n\\n" \
        "example: $(basename "$0") [foo.docker.com]" \
        "\\nnoptions:\\n" \
        "\\t -l, --list: to list all the images"
}

#**
# @brief    Displays usage details and error message. Exits with non-zero status.
#
exit_with_usage() {
  usage
  log_error "$*"
}

#**
# @brief    Obtains GCP project ID from gcloud configuration and updates global variable PROJECT_ID.
#
get_project(){
    local project_id ret
    local msg="Provide GCP Project ID via command line arguments or update gcloud config: gcloud config set project <project_id>"

    project_id=$(gcloud config list core/project --format='value(core.project)'); ret=$?
    [[ ${ret} -ne 0 || -z "${project_id}" ]] && \
        usage "Failed to get project ID from gcloud config.\\n${msg}"

    log_info "gcloud configured project ID is ${project_id}.\\n" \
        "Press: y to proceed for pushing images in project: ${project_id}\\n" \
        "Press: n to abort."
    read -r prompt
    if [[ "${prompt}" != "y" ]]; then
        usage "Aborting.\\n${msg}"
        exit 0
    fi
    PROJECT_ID="${project_id}"
}

docker_exe() {
  local action=$1
  local repo=$2

  for i in "${APIGEE_COMPONENTS[@]}"
  do
    docker "${action}" "${repo}/$i:${TAG}"
  done

  for i in "${THIRD_PARTY_COMPONENTS[@]}"
  do
    docker "${action}" "${repo}/$i"
  done
}

docker_tag() {
  local source=$1
  local dest=$2

  for i in "${APIGEE_COMPONENTS[@]}"
  do
    docker tag "${source}/$i:${TAG}" "${dest}/$i:${TAG}"
  done

  for i in "${THIRD_PARTY_COMPONENTS[@]}"
  do
    docker tag "${source}/$i" "${dest}/$i"
  done
}

list_images() {
  local source=$1
  echo "apigee:"
  for i in "${APIGEE_COMPONENTS[@]}"
  do
    printf '\t%s/%s:%s\n' "${source}" "${i}" "${TAG}"
  done
  echo "third party:"
  for i in "${THIRD_PARTY_COMPONENTS[@]}"
  do
    printf '\t%s/%s\n' "${source}" "${i}"
  done
}

### Start of mainline code ###

PARAMS=""
while (( "$#" )); do
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        -l|--list)
            list_images "${GOOGLE_IMG_REPO}"
            exit 0
            ;;
        -*)
            exit_with_usage "Unsupported flag $1" >&2
            exit 1
            ;;
        *)  # preserve positional arguments
            PARAMS="$PARAMS $1"
            shift
            ;;
    esac
done

# set positional arguments in their proper place
eval set -- "$PARAMS"

# Check gcloud config for project ID.
if [[ -z "${REPO}" ]]; then
  # Check gcloud is installed and on the $PATH.
  if ! which gcloud > /dev/null 2>&1; then
      log_error "gcloud is not installed or not on PATH."
  fi
  get_project
  REPO="us.gcr.io/${PROJECT_ID}"
fi

# Check docker is installed and on the $PATH.
if ! which docker > /dev/null 2>&1; then
    log_error "docker is not installed or not on PATH."
fi

# Pull all the images from the Google Docker Hub
docker_exe "pull" "${GOOGLE_IMG_REPO}"
# tag the pulled images
docker_tag "${GOOGLE_IMG_REPO}" "${REPO}"
# Push the images to the user defined repo.
docker_exe "push" "${REPO}"

#!/usr/bin/env bash
# Script that calls the Giteap API to delete one repo

if [[ -n "$CERC_SCRIPT_DEBUG" ]]; then
    set -x
fi

if ! [[ $# -eq 1 ]]; then
    echo "Illegal number of parameters" >&2
    exit 1
fi
repo_to_delete=$1

if [[ -z "${CERC_GITEA_AUTH_TOKEN}" ]]; then
    echo "CERC_GITEA_AUTH_TOKEN is not set" >&2
    exit 1
fi
if [[ -z "${CERC_GITEA_API_URL}" ]]; then
    echo "CERC_GITEA_API_URL is not set" >&2
    exit 1
fi
if [[ "${CERC_GITEA_MIRROR_REPO}" == "true" ]]; then
    is_mirror=true
else
    is_mirror=false
fi

gitea_target_org=$(dirname ${repo_to_delete})
gitea_target_repo_name=$(basename ${repo_to_delete})
# Sanity check the repo name
if [[ -z "${gitea_target_org}" ]]; then
    echo "${repo_to_delete} is not a valid repo name" >&2
    exit 1
fi
if [[ -z "${gitea_target_repo_name}" ]]; then
    echo "${repo_to_delete} is not a valid repo name" >&2
    exit 1
fi

echo "****** DELETING repo: ${repo_to_delete}"
# Note use: --trace-ascii - \ below to see the raw request
delete_response=$( curl -s -X DELETE "${CERC_GITEA_API_URL}/api/v1/repos/${repo_to_delete}" \
      -H "Authorization: token ${CERC_GITEA_AUTH_TOKEN}" \
      -H  "accept: application/json" \
)
echo ${delete_response} | jq -r

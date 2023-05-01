#!/usr/bin/env bash
# Script that calls the Giteap API to migrate one repo from
# a source hosting platform into that Gitea instance

if [[ -n "$CERC_SCRIPT_DEBUG" ]]; then
    set -x
fi

if ! [[ $# -eq 1 ]]; then
    echo "Illegal number of parameters" >&2
    exit 1
fi
repo_to_migrate=$1

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

gitea_target_org=$(dirname ${repo_to_migrate})
gitea_target_repo_name=$(basename ${repo_to_migrate})
# Sanity check the repo name
if [[ -z "${gitea_target_org}" ]]; then
    echo "${repo_to_migrate} is not a valid repo name" >&2
    exit 1
fi
if [[ -z "${gitea_target_repo_name}" ]]; then
    echo "${repo_to_migrate} is not a valid repo name" >&2
    exit 1
fi

github_repo_url="https://github.com/${repo_to_migrate}"
echo "Migrating repo: ${repo_to_migrate} (mirror:${is_mirror})"
# Note use: --trace-ascii - \ below to see the raw request
migrate_response=$( curl -s -X POST "${CERC_GITEA_API_URL}/api/v1/repos/migrate" \
      -H "Authorization: token ${CERC_GITEA_AUTH_TOKEN}" \
      -H "Content-Type: application/json" \
      -H  "accept: application/json" \
      -d @- << EOF
{
    "clone_addr": "${github_repo_url}",
    "mirror": ${is_mirror},
    "repo_name": "${gitea_target_repo_name}",
    "repo_owner": "${gitea_target_org}"
}
EOF
)
echo Migrated to: $(echo ${migrate_response} | jq -r .html_url)

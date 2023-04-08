#!/usr/bin/env bash
if [[ -n "$CERC_SCRIPT_DEBUG" ]]; then
    set -x
fi
mkdir -p ./gitea
mkdir -p ./gitea/ssh
mkdir -p ./act-runner

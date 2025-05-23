#!/usr/bin/bash

git_root=$(git rev-parse --show-toplevel)

cd "${git_root}"

act push \
--action-offline-mode \
-P ubuntu-24.04=my-act-aws-image \
-W "${git_root}/.github/workflows/run_terraform.yaml" \
--secret-file "${git_root}/act/inputs/.secrets" \
--env-file "${git_root}/act/inputs/.env" \
--var-file "${git_root}/act/inputs/.vars" \
--artifact-server-path "${git_root}/act/artifacts"
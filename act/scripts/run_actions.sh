#!/usr/bin/bash

act push \
--action-offline-mode \
-P ubuntu-latest=my-act-aws-image \
-W ../../.github/workflows/run_terraform.yaml \
--secret-file ../inputs/.secrets \
--env-file ../inputs/.env \
--var-file ../inputs/.vars \
--artifact-server-path ../inputs/artifacts

#!/usr/bin/bash

git_root=$(git rev-parse --show-toplevel)

lambda_path="${git_root}/backend/src/lambda"

# Must cd to src dir.
cd "${lambda_path}"

zip -r -9 -D -X "lambda.zip" . --quiet -x  "__pycache__/*" "lambda.zip"

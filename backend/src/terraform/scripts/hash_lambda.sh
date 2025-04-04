#!/usr/bin/bash

# Used to generate the lambda hash that determines to Terraform if there
# have been changes made.

# The program must then produce a valid JSON object on stdout, which will be
# used to populate the result attribute exported to the rest of the Terraform
# configuration. This JSON object must again have all of its values as strings.

git_root=$(git rev-parse --show-toplevel)

lambda_path="${git_root}/backend/src/lambda"

# Must cd to src dir.
cd "${lambda_path}"

# "lambda.zip" "__pycache__""

lambda_hash=$(find . \
  -type d -name "__pycache__" -prune -o \
  -type f ! -name "lambda.zip" -exec sha256sum {} + \
  | LC_ALL=C sort | sha256sum)

lambda_hash="${lambda_hash:0:${#lambda_hash}-3}" 

echo "{\"lambda_hash\": \"${lambda_hash}\"}"


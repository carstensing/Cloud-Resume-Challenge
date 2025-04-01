#!/usr/bin/bash

# Used to generate the lambda site hash that determines to Terraform if there
# have been changes made.

# The program must then produce a valid JSON object on stdout, which will be
# used to populate the result attribute exported to the rest of the Terraform
# configuration. This JSON object must again have all of its values as strings.

git_root=$(git rev-parse --show-toplevel)

lambda_site_path="${git_root}/backend/src/lambda"
lambda_zip="lambda.zip"
lambda_zip_path="${lambda_site_path}/${lambda_zip}"

# Must cd to src dir.
cd "${lambda_site_path}"

#       save destination         src dir
zip -rq -X -9 -D "${lambda_zip_path}" . -x "__pycache__/*" ".pytest_cache/*" \
"${lambda_zip}"

lambda_hash=$(sha256sum "${lambda_zip_path}" | awk '{print $1}')

echo "{\"lambda_hash\": \"${lambda_hash}\"}"
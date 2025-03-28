#!/usr/bin/bash

# Used to generate the hugo site hash that determines to Terraform if there
# have been changes made.

# The program must then produce a valid JSON object on stdout, which will be
# used to populate the result attribute exported to the rest of the Terraform
# configuration. This JSON object must again have all of its values as strings.

git_root=$(git rev-parse --show-toplevel)

hugo_site_path="${git_root}/frontend/src/hugo_site"
hugo_zip="hugo_site.zip"
hugo_sha256="hugo_site_zip.sha256"


cd "${hugo_site_path}"

zip -r "${hugo_zip}" . --quiet -x  "public/*" ".hugo_build.lock" \
"terraform.tfstate" "${hugo_zip}"

site_hash=$(sha256sum "${hugo_zip}" | awk '{print $1}')

# terraform_temp="${git_root}/backend/src/terraform/scripts/temp"
# echo "${site_hash}" >> "${terraform_temp}/site_hash.sha256"

rm -f "${hugo_zip}"

echo "{\"hash\": \"${site_hash}\"}"
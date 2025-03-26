#!/usr/bin/bash

# Used to generate the hugo site hash that determines to Terraform if there
# have been changes made.

# The program must then produce a valid JSON object on stdout, which will be
# used to populate the result attribute exported to the rest of the Terraform
# configuration. This JSON object must again have all of its values as strings.

hugo_site_path="../../../frontend/src/hugo_site"
hugo_zip_name="hugo_site.zip"
hugo_sha256_name="hugo_site_zip.sha256"


cd "${hugo_site_path}"

zip -r "${hugo_zip_name}" . --quiet -x  "public/*" ".hugo_build.lock" \
"terraform.tfstate" "${hugo_zip_name}" "${hugo_sha256_name}"

site_hash=$(sha256sum "${hugo_zip_name}" | awk '{print $1}')

rm -f "${hugo_zip_name}"

echo "{\"hash\": \"${site_hash}\"}"
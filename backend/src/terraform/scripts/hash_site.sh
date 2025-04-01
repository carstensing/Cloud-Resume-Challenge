#!/usr/bin/bash

# Used to generate the hugo site hash that determines to Terraform if there
# have been changes made.

# The program must then produce a valid JSON object on stdout, which will be
# used to populate the result attribute exported to the rest of the Terraform
# configuration. This JSON object must again have all of its values as strings.

git_root=$(git rev-parse --show-toplevel)
temp_path="/tmp"

hugo_site_path="${git_root}/frontend/src/hugo_site"
hugo_zip="hugo_site.zip"
hugo_zip_path="${temp_path}/${hugo_zip}"

# Must cd to src dir.
cd "${hugo_site_path}"

#       save destination         src dir
zip -rq -X -9 -D "${hugo_zip_path}" . -x "public/*" "themes/*" ".hugo_build.lock" \
"terraform.tfstate"

site_hash=$(sha256sum "${hugo_zip_path}" | awk '{print $1}')

echo "{\"site_hash\": \"${site_hash}\"}"

rm -f "${hugo_zip_path}"
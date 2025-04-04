#!/usr/bin/bash

# Used to generate the hugo site hash that determines to Terraform if there
# have been changes made.

# The program must then produce a valid JSON object on stdout, which will be
# used to populate the result attribute exported to the rest of the Terraform
# configuration. This JSON object must again have all of its values as strings.

git_root=$(git rev-parse --show-toplevel)

hugo_site_path="${git_root}/frontend/src/hugo_site"

# Must cd to src dir.
cd "${hugo_site_path}"

# "public/*" "themes/*" "resources/*" ".hugo_build.lock" "terraform.tfstate"

site_hash=$(find . \
  \( -path "./public/*" -o -path "./themes/*" -o -path "./resources/*" \) -prune -o \
  -type f \( ! -name ".hugo_build.lock" -a ! -name "terraform.tfstate" \) \
  -exec sha256sum {} + | LC_ALL=C sort | sha256sum)

site_hash="${site_hash:0:${#site_hash}-3}" 

echo "{\"site_hash\": \"${site_hash}\"}"

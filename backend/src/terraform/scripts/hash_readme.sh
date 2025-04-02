#!/usr/bin/bash

# Used to generate the README hash that determines to Terraform if there
# have been changes made and to run the post updater script.

# The program must then produce a valid JSON object on stdout, which will be
# used to populate the result attribute exported to the rest of the Terraform
# configuration. This JSON object must again have all of its values as strings.

git_root=$(git rev-parse --show-toplevel)
terraform_path="${git_root}/backend/src/terraform"
readme="${git_root}/README.md"

readme_hash=$(sha256sum "${readme}" | awk '{print $1}')

cd "${terraform_path}"

old_readme_hash=$(terraform output -raw readme_hash)

if [[ "${readme_hash}" != "${old_readme_hash}" ]]; then
    # echo "updating"
    python3 scripts/post_updater.py
fi

echo "{\"readme_hash\": \"${readme_hash}\"}"

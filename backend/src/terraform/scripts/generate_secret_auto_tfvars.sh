#!/usr/bin/bash

git_root=$(git rev-parse --show-toplevel)

aws sts get-caller-identity > /dev/null
if [ $? -ne 0 ]; then
  echo "Did you sign into AWS?"
  exit 1
fi

account_id=$(aws sts get-caller-identity | jq ".Account")

cat <<EOF > "${git_root}/backend/src/terraform/.secrets.auto.tfvars"
aws_account_id = ${account_id}
aws_profile    = "insert_profile_name_here"
EOF
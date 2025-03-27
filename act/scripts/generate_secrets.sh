#!/usr/bin/bash

aws sts get-caller-identity > /dev/null
if [ $? -ne 0 ]; then
  echo "Did you sign into AWS?"
  exit 1
fi

account_id=$(aws sts get-caller-identity | jq -r ".Account")
region=$(aws configure get region)

credentials_path="${HOME}/.aws/cli/cache"
credentials_file="${credentials_path}/$(ls -1 ${credentials_path} | head -n 1)"

access_key_id=$(jq -r ".Credentials.AccessKeyId" ${credentials_file})
secret_access_key=$(jq -r ".Credentials.SecretAccessKey" ${credentials_file})
session_token=$(jq -r ".Credentials.SessionToken" ${credentials_file})

cat <<EOF > ../inputs/.secrets
AWS_ACCESS_KEY_ID=${access_key_id}
AWS_SECRET_ACCESS_KEY=${secret_access_key}
SESSION_TOKEN=${session_token}
AWS_ACCOUNT_ID=${account_id}
EOF
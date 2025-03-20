#! /usr/bin/bash

rest_api_id=$1
stage_name=$2
sdk_dir_name="API_SDK"
hugo_site_path="../../../frontend/src/hugo_site"
sdk_path="${hugo_site_path}/assets/js/${sdk_dir_name}"

# Remove old SDK.
rm -fr "${sdk_path}"

# Get new SDK.
aws apigateway get-sdk \
    --rest-api-id $rest_api_id \
    --stage-name $stage_name \
    --sdk-type javascript ${sdk_dir_name}.zip

# Unzip new SDK, move it, delete zip file.
unzip "${sdk_dir_name}.zip"
mv apiGateway-js-sdk "${sdk_path}"
rm -fr "${sdk_dir_name}.zip"
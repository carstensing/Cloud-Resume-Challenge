#! /usr/bin/bash

rest_api_id=$1
stage_name=$2
sdk_dir_name="API_SDK"

aws apigateway get-sdk \
    --rest-api-id $rest_api_id \
    --stage-name $stage_name \
    --sdk-type javascript ${sdk_dir_name}.zip

unzip ${sdk_dir_name}.zip

rm -fr ../../hugo_site/assets/js/${sdk_dir_name}

mv apiGateway-js-sdk ../../hugo_site/assets/js/${sdk_dir_name}

rm -fr ${sdk_dir_name}.zip
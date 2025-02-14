terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

# Lambda ----------------------------------------------------------------------

resource "aws_iam_role" "lambda_role" {
  name = "website_lambda_role"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "lambda.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      },
    ]
  })

  tags = var.tags
}

resource "aws_iam_policy" "lambda_policy" {
  name = "site_lambda_policy"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : "logs:CreateLogGroup",
        "Resource" : "arn:aws:logs:${var.aws_region}:${var.aws_account_id}:*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource" : [
          "arn:aws:logs:${var.aws_region}:${var.aws_account_id}:log-group:/aws/lambda/*:*"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
        ],
        "Resource" : [
          "arn:aws:dynamodb:${var.aws_region}:${var.aws_account_id}:table/${aws_dynamodb_table.data_table.name}",
          "arn:aws:dynamodb:${var.aws_region}:${var.aws_account_id}:table/${aws_dynamodb_table.visitor_table.name}"
        ]
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "attach_policy_to_lambda_role" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

locals {
  lambda_src_path = "${path.module}/lambda/src"
}

data "archive_file" "zip_python_code" {
  type        = "zip"
  source_dir  = local.lambda_src_path
  output_path = "${local.lambda_src_path}/lambda_payload.zip"
}

# Create a lambda function
resource "aws_lambda_function" "site_lambda_func" {
  filename         = data.archive_file.zip_python_code.output_path
  source_code_hash = filebase64sha256(data.archive_file.zip_python_code.output_path)
  function_name    = "visitor-count"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.13"

  depends_on = [
    aws_iam_role_policy_attachment.attach_policy_to_lambda_role,
  ]

  environment {
    variables = {
      "data_tbl"    = aws_dynamodb_table.data_table.name
      "visitor_tbl" = aws_dynamodb_table.visitor_table.name
    }
  }

  tags = var.tags
}

resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.site_lambda_func.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.site_API.execution_arn}/*"
}

# DynamoDB --------------------------------------------------------------------

resource "aws_dynamodb_table" "data_table" {
  name         = "site-data"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "p-key"

  attribute {
    name = "p-key"
    type = "S"
  }

  tags = var.tags
}

resource "aws_dynamodb_table" "visitor_table" {
  name         = "site-visitors"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "ip-address"
  range_key    = "browser"

  attribute {
    name = "ip-address"
    type = "S"
  }

  attribute {
    name = "browser"
    type = "S"
  }

  tags = var.tags
}

# API Gateway -----------------------------------------------------------------

resource "aws_api_gateway_rest_api" "site_API" {
  name = "site-API"
  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = var.tags
}

resource "aws_api_gateway_deployment" "dep" {
  rest_api_id = aws_api_gateway_rest_api.site_API.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.visitor_counter,
      aws_api_gateway_method.get,
      aws_api_gateway_integration.get_integration,
      aws_api_gateway_method_response.get_mr_code_200,
      aws_api_gateway_integration_response.get_ir_code_200,
      aws_api_gateway_method.options,
      aws_api_gateway_integration.options_integration,
      aws_api_gateway_method_response.options_mr_code_200,
      aws_api_gateway_integration_response.options_ir_code_200
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "terraform_data" "update_SDK" {
  triggers_replace = [
    sha1(jsonencode([
      aws_api_gateway_rest_api.site_API.id,
      aws_api_gateway_stage.production_stage.stage_name
    ]))
  ]

  provisioner "local-exec" {
    command = "./generate_sdk.sh ${aws_api_gateway_rest_api.site_API.id} ${aws_api_gateway_stage.production_stage.stage_name}"
  }
}

resource "aws_api_gateway_stage" "production_stage" {
  deployment_id = aws_api_gateway_deployment.dep.id
  rest_api_id   = aws_api_gateway_rest_api.site_API.id
  stage_name    = "production"
}

resource "aws_api_gateway_resource" "visitor_counter" {
  parent_id   = aws_api_gateway_rest_api.site_API.root_resource_id
  path_part   = "visitor-counter"
  rest_api_id = aws_api_gateway_rest_api.site_API.id
}

resource "aws_api_gateway_method" "get" {
  authorization = "NONE"
  http_method   = "GET"
  resource_id   = aws_api_gateway_resource.visitor_counter.id
  rest_api_id   = aws_api_gateway_rest_api.site_API.id
}

resource "aws_api_gateway_integration" "get_integration" {
  rest_api_id             = aws_api_gateway_rest_api.site_API.id
  resource_id             = aws_api_gateway_resource.visitor_counter.id
  http_method             = aws_api_gateway_method.get.http_method
  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = aws_lambda_function.site_lambda_func.invoke_arn
  passthrough_behavior    = "WHEN_NO_MATCH"
  content_handling        = "CONVERT_TO_TEXT"
  timeout_milliseconds    = 29000

  request_templates = {
    "application/json" = jsonencode({
      "domain_name" : "$context.domainName",
      "http_method" : "$context.httpMethod",
      "path" : "$context.path",
      "resource_path" : "$context.resourcePath",
      "resource_id" : "$context.resourceId",
      "source_ip" : "$context.identity.sourceIp",
      "user-agent" : "$context.identity.userAgent"
    })
  }
}

resource "aws_api_gateway_method_response" "get_mr_code_200" {
  rest_api_id = aws_api_gateway_rest_api.site_API.id
  resource_id = aws_api_gateway_resource.visitor_counter.id
  http_method = aws_api_gateway_method.get.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = false
  }
}

resource "aws_api_gateway_integration_response" "get_ir_code_200" {
  rest_api_id = aws_api_gateway_rest_api.site_API.id
  resource_id = aws_api_gateway_resource.visitor_counter.id
  http_method = aws_api_gateway_method.get.http_method
  status_code = aws_api_gateway_method_response.get_mr_code_200.status_code

  depends_on = [
    aws_api_gateway_integration.get_integration
  ]

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }
}

resource "aws_api_gateway_method" "options" {
  authorization = "NONE"
  http_method   = "OPTIONS"
  resource_id   = aws_api_gateway_resource.visitor_counter.id
  rest_api_id   = aws_api_gateway_rest_api.site_API.id
}

resource "aws_api_gateway_integration" "options_integration" {
  rest_api_id          = aws_api_gateway_rest_api.site_API.id
  resource_id          = aws_api_gateway_resource.visitor_counter.id
  http_method          = aws_api_gateway_method.options.http_method
  type                 = "MOCK"
  passthrough_behavior = "WHEN_NO_MATCH"
  timeout_milliseconds = 29000

  request_templates = {
    "application/json" = jsonencode({
      "statusCode" : 200
    })
  }
}

resource "aws_api_gateway_method_response" "options_mr_code_200" {
  rest_api_id = aws_api_gateway_rest_api.site_API.id
  resource_id = aws_api_gateway_resource.visitor_counter.id
  http_method = aws_api_gateway_method.options.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = false
    "method.response.header.Access-Control-Allow-Methods" = false
    "method.response.header.Access-Control-Allow-Headers" = false
  }
}

resource "aws_api_gateway_integration_response" "options_ir_code_200" {
  rest_api_id = aws_api_gateway_rest_api.site_API.id
  resource_id = aws_api_gateway_resource.visitor_counter.id
  http_method = aws_api_gateway_method.options.http_method
  status_code = aws_api_gateway_method_response.options_mr_code_200.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" : "'Content-Type,Authorization'"
    "method.response.header.Access-Control-Allow-Methods" : "'GET,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin" : "'*'"
  }
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.9"
    }
  }

  # Remote state file in S3.
  backend "s3" {
    bucket       = "carsten-singleton.com-terraform-state"
    key          = "terraform.tfstate"
    region       = "us-west-1"
    use_lockfile = true
  }
}

provider "aws" {
  region = var.aws_region
}

# CRC Hugo Post ---------------------------------------------------------------

data "external" "hash_readme" {
  program = ["./scripts/hash_readme.sh"] # PATH
}

output "readme_hash" {
  value = data.external.hash_readme.result.readme_hash
}

# ACM -------------------------------------------------------------------------

locals {
  domain_name = "carsten-singleton.com"
}

resource "aws_acm_certificate" "site_cert" {
  domain_name               = local.domain_name
  subject_alternative_names = ["${local.domain_name}", "*.${local.domain_name}"]
  validation_method         = "DNS"
  key_algorithm             = "RSA_2048"

  options {
    certificate_transparency_logging_preference = "ENABLED"
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [aws_route53_zone.primary]

  tags = var.tags
}

resource "aws_acm_certificate_validation" "site_vert_val" {
  certificate_arn         = aws_acm_certificate.site_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.site_CNAME : record.fqdn]
}

# Route 53 Domains ------------------------------------------------------------

resource "aws_route53domains_registered_domain" "site_domain" {
  domain_name = local.domain_name

  name_server {
    name = aws_route53_zone.primary.name_servers[0]
  }

  name_server {
    name = aws_route53_zone.primary.name_servers[1]
  }

  name_server {
    name = aws_route53_zone.primary.name_servers[2]
  }

  name_server {
    name = aws_route53_zone.primary.name_servers[3]
  }

  tags = var.tags
}

# Route 53 --------------------------------------------------------------------

resource "aws_route53_zone" "primary" {
  name = local.domain_name

  depends_on = [
    aws_s3_bucket.site_bucket,
    aws_s3_bucket.site_www_redirect_bucket,
    aws_cloudfront_distribution.s3_distribution
  ]

  tags = var.tags
}

# Special hosted zone ID is used when creating an alias record in Route 53 that
# points to a CloudFront distribution.

locals {
  cloudfront_hosted_zone_id = "Z2FDTNDATAQYW2"
}

resource "aws_route53_record" "site_A" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = local.domain_name
  type    = "A"
  alias {
    name                   = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id                = local.cloudfront_hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "www_A" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "www.${local.domain_name}"
  type    = "A"
  alias {
    name                   = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id                = local.cloudfront_hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "site_CNAME" {
  for_each = {
    for dvo in aws_acm_certificate.site_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 300
  type            = each.value.type
  zone_id         = aws_route53_zone.primary.zone_id
}

resource "aws_route53_record" "site_NS" {
  allow_overwrite = true
  name            = local.domain_name
  ttl             = 172800
  type            = "NS"
  zone_id         = aws_route53_zone.primary.zone_id

  records = [
    aws_route53_zone.primary.name_servers[0],
    aws_route53_zone.primary.name_servers[1],
    aws_route53_zone.primary.name_servers[2],
    aws_route53_zone.primary.name_servers[3],
  ]
}

resource "aws_route53_record" "site_SOA" {
  allow_overwrite = true
  name            = local.domain_name
  ttl             = 900
  type            = "SOA"
  zone_id         = aws_route53_zone.primary.zone_id

  records = ["${aws_route53_zone.primary.primary_name_server} awsdns-hostmaster.amazon.com. 1 7200 900 1209600 86400"]
}

# CloudFront ------------------------------------------------------------------

locals {
  s3_origin_id = "site_bucket_origin"
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name         = aws_s3_bucket_website_configuration.site_bucket_config.website_endpoint
    origin_id           = local.s3_origin_id
    connection_attempts = 3
    connection_timeout  = 10

    custom_origin_config {
      http_port                = 80
      https_port               = 443
      origin_protocol_policy   = "http-only"
      origin_ssl_protocols     = ["SSLv3", "TLSv1", "TLSv1.1", "TLSv1.2"]
      origin_read_timeout      = 30
      origin_keepalive_timeout = 5
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  http_version        = "http2"
  price_class         = "PriceClass_100"

  default_cache_behavior {
    # Cache policy: CachingOptimized (Recommended for s3)
    cache_policy_id        = "658327ea-f89d-4fab-a63d-7e88639e58f6"
    allowed_methods        = ["GET", "HEAD"]
    target_origin_id       = local.s3_origin_id
    viewer_protocol_policy = "redirect-to-https"
    cached_methods         = ["GET", "HEAD"]
    smooth_streaming       = false
    compress               = true
    grpc_config {
      enabled = false
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = false
    acm_certificate_arn            = "arn:aws:acm:us-east-1:050752609485:certificate/c2e11f7d-d9e9-40b4-b2a7-a4149003ba20"
    ssl_support_method             = "sni-only"
    minimum_protocol_version       = "TLSv1.2_2021"
  }

  aliases = [
    local.domain_name,
    "www.${local.domain_name}"
  ]

  tags = var.tags
}

# S3 --------------------------------------------------------------------------

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.site_bucket.id

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "PublicReadGetObject",
        "Effect" : "Allow",
        "Principal" : "*",
        "Action" : "s3:GetObject",
        "Resource" : "${aws_s3_bucket.site_bucket.arn}/*"
      }
    ]
  })

  depends_on = [
    aws_s3_bucket_public_access_block.pab
  ]
}

resource "aws_s3_bucket" "site_bucket" {
  bucket        = local.domain_name
  force_destroy = true

  tags = var.tags
}

resource "aws_s3_bucket_website_configuration" "site_bucket_config" {
  bucket = aws_s3_bucket.site_bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "404.html"
  }
}

resource "aws_s3_bucket_public_access_block" "pab" {
  bucket = aws_s3_bucket.site_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

data "external" "hash_hugo_site" {
  program = ["./scripts/hash_site.sh"] # PATH

  depends_on = [
    data.external.hash_readme
  ]
}

resource "terraform_data" "update_bucket_objects" {
  triggers_replace = [
    data.external.hash_hugo_site.result.site_hash,
    # Don't hash the bucket if you want to see what exactly is being modified
    # in the Terraform plan stage.
    sha1(jsonencode([
      aws_s3_bucket.site_bucket
    ]))
  ]

  provisioner "local-exec" {
    # PATH
    command = join(" ", [
      "./scripts/update_bucket.sh",
      aws_cloudfront_distribution.s3_distribution.id
    ])
  }

  depends_on = [
    terraform_data.update_SDK
  ]
}

resource "aws_s3_bucket" "site_www_redirect_bucket" {
  bucket = "www.${local.domain_name}"

  force_destroy = true

  tags = var.tags
}

resource "aws_s3_bucket_website_configuration" "site_www_redirect_bucket_config" {
  bucket = aws_s3_bucket.site_www_redirect_bucket.id

  redirect_all_requests_to {
    host_name = local.domain_name
  }
}

# CloudWatch ------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "site_lambda_log_group" {
  name              = "/aws/lambda/${local.lambda_name}"
  retention_in_days = 7
}

# Lambda ----------------------------------------------------------------------

resource "aws_iam_role" "lambda_role" {
  name = "LambdaSiteRole"

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
  name = "LambdaSitePolicy"

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
          "arn:aws:logs:${var.aws_region}:${var.aws_account_id}:log-group:/aws/lambda/${local.lambda_name}:*"
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
  lambda_name     = "visitor-count"
  lambda_src_path = "${path.root}/../lambda"            # PATH
  lambda_zip_path = "${path.root}/../lambda/lambda.zip" # PATH
}

data "external" "hash_lambda" {
  program = ["./scripts/hash_lambda.sh"] # PATH
}

resource "terraform_data" "zip_lambda" {
  triggers_replace = [
    data.external.hash_lambda.result.lambda_hash
  ]

  provisioner "local-exec" {
    command = "./scripts/zip_lambda.sh" # PATH
  }
}

# Create a lambda function
resource "aws_lambda_function" "site_lambda_func" {
  filename         = local.lambda_zip_path
  source_code_hash = data.external.hash_lambda.result.lambda_hash
  function_name    = local.lambda_name
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.13"

  depends_on = [
    aws_iam_role_policy_attachment.attach_policy_to_lambda_role,
    aws_cloudwatch_log_group.site_lambda_log_group,
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
      aws_api_gateway_rest_api.site_API,
      aws_api_gateway_stage.production_stage
    ]))
  ]

  provisioner "local-exec" {
    # PATH
    command = join(" ", [
      "./scripts/generate_sdk.sh",
      aws_api_gateway_rest_api.site_API.id,
      aws_api_gateway_stage.production_stage.stage_name
    ])
  }
}

resource "aws_api_gateway_stage" "production_stage" {
  deployment_id = aws_api_gateway_deployment.dep.id
  rest_api_id   = aws_api_gateway_rest_api.site_API.id
  stage_name    = "production"

  tags = var.tags
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
    "method.response.header.Access-Control-Allow-Headers" : "'Content-Type'"
    "method.response.header.Access-Control-Allow-Methods" : "'GET,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin" : "'*'"
  }
}

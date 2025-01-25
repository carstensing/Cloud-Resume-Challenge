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
  name = "website_lambda_policy"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
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
        ],
        "Resource" : "arn:aws:dynamodb:${var.aws_region}:${var.aws_account_id}:table/*"
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "attach_policy_to_role" {
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
resource "aws_lambda_function" "terraform_lambda_func" {
  filename         = data.archive_file.zip_python_code.output_path
  source_code_hash = filebase64sha256(data.archive_file.zip_python_code.output_path)
  function_name    = "visitor-count"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.13"

  depends_on = [
    aws_iam_role_policy_attachment.attach_policy_to_role,
  ]

  environment {
    variables = {
      "data_tbl"    = "website-data",
      "visitor_tbl" = "website-visitors"
    }
  }

  tags = var.tags
}
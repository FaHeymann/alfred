terraform {
  required_version = ">=1.2"
  required_providers {
    archive = {
      source = "hashicorp/archive"
    }
    aws = {
      source = "hashicorp/aws"
    }
  }
  backend "s3" {
    bucket = "fh-terraform-states"
    key    = "alfred"
    region = "eu-central-1"
  }
}

provider "aws" {
  region = "eu-central-1"
}

variable "token" {
}

variable "chat_id" {
}

variable "weather_api_appid" {
}

variable "todoist_api_token" {
}

data "aws_iam_policy_document" "alfred_trust_relationship" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "alfred" {
  name               = "alfred"
  assume_role_policy = data.aws_iam_policy_document.alfred_trust_relationship.json
}

data "archive_file" "alfred" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "${path.module}/alfred.zip"
}

resource "aws_lambda_function" "alfred" {
  filename                       = data.archive_file.alfred.output_path
  function_name                  = "alfred"
  role                           = aws_iam_role.alfred.arn
  handler                        = "main.main"
  runtime                        = "nodejs16.x"
  timeout                        = 60
  reserved_concurrent_executions = 1
  source_code_hash               = data.archive_file.alfred.output_base64sha256
  environment {
    variables = {
      TOKEN             = var.token
      CHAT_ID           = var.chat_id
      WEATHER_API_APPID = var.weather_api_appid
      TODOIST_API_TOKEN = var.todoist_api_token
    }
  }
}

resource "aws_lambda_permission" "allow_cloudwatch_to_trigger_lambda" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.alfred.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.alfred.arn
}

resource "aws_cloudwatch_event_rule" "alfred" {
  name        = "alfred"
  description = "Alfred"

  schedule_expression = "cron(0 5,11,16 * * ? *)"

  is_enabled = false
}

resource "aws_cloudwatch_event_target" "alfred" {
  rule = aws_cloudwatch_event_rule.alfred.name
  arn  = aws_lambda_function.alfred.arn

  input = "{}"
}


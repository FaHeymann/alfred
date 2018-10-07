terraform {
  required_version = "0.11.7"
  backend "s3" {
    bucket = "fh-terraform-states"
    key    = "alfred"
    region = "eu-central-1"
  }
}

provider "aws" {
  region  = "eu-central-1"
}

variable "token" {}
variable "chat_id" {}
variable "weather_api_appid" {}

resource "aws_iam_role" "alfred" {
  name = "alfred"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

data "archive_file" "alfred" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "${path.module}/alfred.zip"
}

resource "aws_lambda_function" "alfred" {
  filename                       = "${data.archive_file.alfred.output_path}"
  function_name                  = "alfred"
  role                           = "${aws_iam_role.alfred.arn}"
  handler                        = "main.main"
  runtime                        = "nodejs8.10"
  timeout                        = 60
  reserved_concurrent_executions = 1
  source_code_hash               = "${data.archive_file.alfred.output_base64sha256}",
  environment {
    variables = {
      TOKEN =             "${var.token}"
      CHAT_ID =           "${var.chat_id}"
      WEATHER_API_APPID = "${var.weather_api_appid}"
    }
  }
}

resource "aws_lambda_permission" "allow_cloudwatch_to_trigger_lambda" {
  statement_id   = "AllowExecutionFromCloudWatch"
  action         = "lambda:InvokeFunction"
  function_name  = "${aws_lambda_function.alfred.function_name}"
  principal      = "events.amazonaws.com"
  source_arn     = "${aws_cloudwatch_event_rule.alfred.arn}"
}

resource "aws_cloudwatch_event_rule" "alfred" {
  name = "alfred"
  description = "Alfred"

  schedule_expression = "cron(0 5,10,15 * * ? *)"
}

resource "aws_cloudwatch_event_target" "alfred" {
  rule = "${aws_cloudwatch_event_rule.alfred.name}"
  arn = "${aws_lambda_function.alfred.arn}"

  input = "{}"
}
provider "aws" {
  region = "us-west-1"
}

variable "lambda_function_name" {
  default = "my-function"
}

resource "aws_cloudwatch_log_group" "function_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.function.function_name}"
  retention_in_days = 7
  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_iam_role" "function_role" {
  name = "${var.lambda_function_name}-role"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        Action : "sts:AssumeRole",
        Effect : "Allow",
        Principal : {
          "Service" : "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_lambda_function" "function" {
  function_name = var.lambda_function_name
  runtime       = "nodejs18.x"
  handler       = "index.handler"
  filename      = "index.zip"
  role          = aws_iam_role.function_role.arn
}

resource "aws_iam_policy" "function_logging_policy" {
  name = "my-function-logging-policy"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        Action : [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Effect : "Allow",
        Resource : "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "function_logging_policy_attachment" {
  role       = aws_iam_role.function_role.id
  policy_arn = aws_iam_policy.function_logging_policy.arn
}

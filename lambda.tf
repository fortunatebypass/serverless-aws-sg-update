provider "aws" {
  region = "us-east-1"
}

resource "aws_lambda_function" "example" {
  function_name = "ServerlessExample"

  # The bucket name as created earlier with "aws s3api create-bucket"
  s3_bucket = "terraform-serverless-example77"
  s3_key    = "v1.0.0/lambda.zip"

  handler = "lambda.lambda_handler"
  runtime = "python3.6"

  role = "${aws_iam_role.lambda_exec.arn}"

  environment {
    variables = {
      SG = "${aws_security_group.git_hooks.id}"
    }
  }
}

# IAM role which dictates what other AWS services the Lambda function
# may access.
resource "aws_iam_role" "lambda_exec" {
  name = "serverless_example_lambda"

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

resource "aws_iam_role_policy" "alter_git_hooks_security_group" {
  name = "alter_git_hooks_security_group"
  role = "${aws_iam_role.lambda_exec.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
        "Effect": "Allow",
        "Action": [
            "ec2:DescribeSecurityGroups"
        ],
        "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:RevokeSecurityGroupIngress"
      ],
      "Resource": "${aws_security_group.git_hooks.arn}"
    }
  ]
}
EOF
}

resource "aws_security_group" "git_hooks" {
  name        = "git_hooks"
  description = "Allow all inbound traffic from GitHub Hooks"
}

resource "aws_cloudwatch_event_rule" "every_twelve_hours" {
    name = "every-twelve-hours"
    description = "Fires every twelve hours"
    schedule_expression = "rate(12 hours)"
}

resource "aws_cloudwatch_event_target" "check_git_hooks_every_twelve_hours" {
    rule = "${aws_cloudwatch_event_rule.every_twelve_hours.name}"
    target_id = "example"
    arn = "${aws_lambda_function.example.arn}"
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_check_git_hooks" {
    statement_id = "AllowExecutionFromCloudWatch"
    action = "lambda:InvokeFunction"
    function_name = "${aws_lambda_function.example.function_name}"
    principal = "events.amazonaws.com"
    source_arn = "${aws_cloudwatch_event_rule.every_twelve_hours.arn}"
}
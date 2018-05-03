// the role for the lambda to assume
resource "aws_iam_role" "lambda_kinesis_to_dynamo" {
  name = "CCRoleForPersonDataLambdaKinesisToDynamoDB-${terraform.workspace}"
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

// attach policy for s3, dynamodb and cloudwatch
resource "aws_iam_role_policy_attachment" "lambda_kinesis_to_dynamo-basic_execution" {
  policy_arn = "arn:aws:iam::aws:policy/AWSLambdaFullAccess"
  role = "${aws_iam_role.lambda_kinesis_to_dynamo.name}"
}
// attach lambda kinesis execution
resource "aws_iam_role_policy_attachment" "lambda_kinesis_to_dynamo-kinesis_execution" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaKinesisExecutionRole"
  role = "${aws_iam_role.lambda_kinesis_to_dynamo.name}"
}

// the lambda itself
resource "aws_lambda_function" "lambda_kinesis_to_dynamo" {
  function_name = "persons_data-kinesis_to_dynamo-${terraform.workspace}"
  handler = "index.handler"
  timeout = 60
  role = "${aws_iam_role.lambda_kinesis_to_dynamo.arn}"
  runtime = "nodejs8.10"
  filename = "${var.file-lambda_kinesis_to_dynamo}"
  source_code_hash = "${base64sha256(file(var.file-lambda_kinesis_to_dynamo))}"
  environment {
    variables {
      DYNAMODB_TABLE = "${aws_dynamodb_table.persons.name}"
    }
  }
}

// event source mapping from kinesis to lambda
resource "aws_lambda_event_source_mapping" "mapping_kinesis_to_lambda" {
  event_source_arn = "${aws_kinesis_stream.person_stream.arn}"
  function_name = "${aws_lambda_function.lambda_kinesis_to_dynamo.function_name}"
  starting_position = "LATEST"
}

// the role for the lambda to assume
resource "aws_iam_role" "lambda_s3_to_kinesis" {
  name = "CCRoleForPersonDataLambdaS3ToKinesis-${terraform.workspace}"
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

// policy to access the bucket with the data
resource "aws_iam_role_policy" "policy_access-bucket_persongenerator_data" {
  name = "CCPolicyPersonDataBucket-${aws_s3_bucket.persongenerator_data.bucket}"
  role = "${aws_iam_role.lambda_s3_to_kinesis.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:ListAllMyBuckets",
      "Resource": "arn:aws:s3:::*"
    },
    {
      "Effect": "Allow",
      "Action": [ "s3:*" ],
      "Resource": [
                  "arn:aws:s3:::${aws_s3_bucket.persongenerator_data.bucket}",
                  "arn:aws:s3:::${aws_s3_bucket.persongenerator_data.bucket}/*"
                  ]
    }
  ]
}
EOF
}

// attach basic lambda execution
resource "aws_iam_role_policy_attachment" "lambda_s3_to_kinesis-basic_execution" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role = "${aws_iam_role.lambda_s3_to_kinesis.name}"
}

data "archive_file" "lambda_s3_to_kinesis" {
  output_path = "${path.root}/lambdazips/lambda_s3_to_kinesis.zip"
  type = "zip"
  source_dir = "${var.path-lambda_s3_to_kinesis}"
}

// the lambda itself
resource "aws_lambda_function" "lambda_s3_to_kinesis" {
  function_name = "persons_data-s3_to_kinesis-${terraform.workspace}"
  handler = "index.handler"
  timeout = 60
  role = "${aws_iam_role.lambda_s3_to_kinesis.arn}"
  runtime = "nodejs8.10"
  filename = "${data.archive_file.lambda_s3_to_kinesis.output_path}"
  source_code_hash = "${data.archive_file.lambda_s3_to_kinesis.output_base64sha256}"
  environment {
    variables {
      KINESIS_STREAM = "${aws_kinesis_stream.person_stream.name}"
    }
  }
}

// allow the bucket to call the lambda
resource "aws_lambda_permission" "allow_invoke-lambda_s3_to_kinesis" {
  action = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.lambda_s3_to_kinesis.function_name}"
  principal = "s3.amazonaws.com"
  statement_id = "AllowExecutionFromS3"
  source_account = "${data.aws_caller_identity.current.account_id}"
  source_arn = "${aws_s3_bucket.persongenerator_data.arn}"
}

// define the events to have the lambda called
resource "aws_s3_bucket_notification" "s3_bucket_notification_to_lambda" {
  bucket = "${aws_s3_bucket.persongenerator_data.id}"
  lambda_function {
    events = [
      "s3:ObjectCreated:*"]
    lambda_function_arn = "${aws_lambda_function.lambda_s3_to_kinesis.arn}"
  }
}

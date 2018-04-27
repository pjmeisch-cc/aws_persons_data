//
//terraform backend configuration
//
terraform {
  backend "s3" {
    bucket = "pjmeisch-cc-terraform-bucket"
    key = "persons_data"
  }
}

data "aws_caller_identity" "current" {}

//
// bucket for the csv data
//
resource "aws_s3_bucket" "persongenerator_data" {
  region = "${var.region}"
  bucket = "${var.bucket-persongenerator_data}-${terraform.workspace}"
  acl = "private"
}

//
// lambda to read data from s3 into kinesis
//
resource "aws_iam_role" "s3_lambda_to_kinesis" {
  name = "CodecentricRoleForPersonDataS3ToKinesis-${terraform.workspace}"
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
resource "aws_iam_role_policy_attachment" "s3_lambda_to_kinesis-basic_execution" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role = "${aws_iam_role.s3_lambda_to_kinesis.name}"
}
resource "aws_iam_policy" "policy_read-persongenerator_data" {
  name = "rw_${aws_s3_bucket.persongenerator_data.bucket}"
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
resource "aws_iam_role_policy_attachment" "s3_lambda_to_kinesis-read-persongenerator_data" {
  policy_arn = "${aws_iam_policy.policy_read-persongenerator_data.arn}"
  role = "${aws_iam_role.s3_lambda_to_kinesis.name}"
}

resource "aws_lambda_function" "s3_lambda_to_kinesis" {
  function_name = "persons_data-s3_to_kinesis-${terraform.workspace}"
  handler = "index.handler"
  timeout = 60
  role = "${aws_iam_role.s3_lambda_to_kinesis.arn}"
  runtime = "nodejs8.10"
  filename = "${var.file-lambda_s3_to_kinesis}"
  source_code_hash = "${base64sha256(file(var.file-lambda_s3_to_kinesis))}"
  environment {
    variables {
      KINESIS_STREAM = "${aws_kinesis_stream.person_stream.name}"
    }
  }
}

resource "aws_lambda_permission" "allow_invoke-s3_lambda_to_kinesis" {
  action = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.s3_lambda_to_kinesis.function_name}"
  principal = "s3.amazonaws.com"
  statement_id = "AllowExecutionFromS3"
  source_account = "${data.aws_caller_identity.current.account_id}"
  source_arn = "${aws_s3_bucket.persongenerator_data.arn}"
}

resource "aws_s3_bucket_notification" "s3_bucket_notification_to_lambda" {
  bucket = "${aws_s3_bucket.persongenerator_data.id}"
  lambda_function {
    events = ["s3:ObjectCreated:*"]
    lambda_function_arn = "${aws_lambda_function.s3_lambda_to_kinesis.arn}"
  }
}

//
// kinesis data stream where the objects from the bucket csv files are fed in
//
resource "aws_kinesis_stream" "person_stream" {
  name = "person_stream-${terraform.workspace}"
  shard_count = 1
  retention_period = 24
}

resource "aws_iam_policy" "policy_write-person_stream" {
  name = "write_${aws_kinesis_stream.person_stream.name}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["kinesis:PutRecord", "kinesis:PutRecords"],
      "Resource": "${aws_kinesis_stream.person_stream.arn}"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_to_kinesis-write_person_stream" {
  policy_arn = "${aws_iam_policy.policy_write-person_stream.arn}"
  role = "${aws_iam_role.s3_lambda_to_kinesis.name}"
}

//
// elasticsearch
//
resource "aws_elasticsearch_domain" "persons" {
  domain_name = "persons-${terraform.workspace}"
  elasticsearch_version = "6.2"
  cluster_config {
    instance_count = 1
    instance_type = "m3.medium.elasticsearch"
  }
}
resource "aws_elasticsearch_domain_policy" "access_persons" {
  domain_name = "${aws_elasticsearch_domain.persons.domain_name}"
  access_policies = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {"AWS": "${data.aws_caller_identity.current.account_id}"},
      "Action": "es:*" ,
      "Resource": "${aws_elasticsearch_domain.persons.arn}"
    }
  ]
}
EOF
}

//
// kinesis firehose to elasticsearch
//
resource "aws_s3_bucket" "failed_records" {
  region = "${var.region}"
  bucket = "${var.bucket-person_kinesis_to_elastic_fails}-${terraform.workspace}"
  acl = "private"
}
resource "aws_iam_role" "firehose" {
  name = "CodecentricRoleForPersonDataKinesisFirehose-${terraform.workspace}"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "firehose.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}
resource "aws_iam_policy" "firehose" {
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
       {
          "Effect": "Allow",
          "Action": [
              "kinesis:DescribeStream",
              "kinesis:GetShardIterator",
              "kinesis:GetRecords"
          ],
          "Resource": "${aws_kinesis_stream.person_stream.arn}"
        },
        {
            "Effect": "Allow",
            "Action": [
                "es:DescribeElasticsearchDomain",
                "es:DescribeElasticsearchDomains",
                "es:DescribeElasticsearchDomainConfig",
                "es:ESHttpPost",
                "es:ESHttpPut"
            ],
          "Resource": [
              "${aws_elasticsearch_domain.persons.arn}",
              "${aws_elasticsearch_domain.persons.arn}/*"
          ]
       },
       {
          "Effect": "Allow",
          "Action": [
              "es:ESHttpGet"
          ],
          "Resource": [
              "${aws_elasticsearch_domain.persons.arn}/_all/_settings",
              "${aws_elasticsearch_domain.persons.arn}/_cluster/stats",
              "${aws_elasticsearch_domain.persons.arn}/index-name*/_mapping/type-name",
              "${aws_elasticsearch_domain.persons.arn}/_nodes",
              "${aws_elasticsearch_domain.persons.arn}/_nodes/stats",
              "${aws_elasticsearch_domain.persons.arn}/_nodes/*/stats",
              "${aws_elasticsearch_domain.persons.arn}/_stats",
              "${aws_elasticsearch_domain.persons.arn}/index-name*/_stats"
          ]
       }
    ]
}
EOF
}
resource "aws_iam_role_policy_attachment" "firehose" {
  role = "${aws_iam_role.firehose.name}"
  policy_arn = "${aws_iam_policy.firehose.arn}"
}
resource "aws_kinesis_firehose_delivery_stream" "kinesis_to_elastic" {
  name = "persons_kinesis_to_elasticsearch-${terraform.workspace}"

  kinesis_source_configuration {
    kinesis_stream_arn = "${aws_kinesis_stream.person_stream.arn}"
    role_arn = "${aws_iam_role.firehose.arn}"
  }

  destination = "elasticsearch"
  elasticsearch_configuration {
    domain_arn = "${aws_elasticsearch_domain.persons.arn}"
    index_name = "persons"
    index_rotation_period = "NoRotation"
    type_name = "person"
    role_arn = "${aws_iam_role.firehose.arn}"
    buffering_interval = 60
    s3_backup_mode = "FailedDocumentsOnly"
  }

  s3_configuration {
    bucket_arn = "${aws_s3_bucket.failed_records.arn}"
    role_arn = "${aws_iam_role.firehose.arn}"
  }
}

//
// outputs
//
output "elasticsearch_endpoint" {
  value = "${aws_elasticsearch_domain.persons.endpoint}"
}

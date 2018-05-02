// role for kinesis-firehose
resource "aws_iam_role" "firehose_to_elastic" {
  name = "CCRoleForPersonDataKinesisFirehose-${terraform.workspace}"
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

// policy to get records fromt the kinesis stream and write to elasticsearch
resource "aws_iam_policy" "firehose_to_elastic" {
  name = "CCPolicyPersonDataFirehoseToElastic-${aws_kinesis_firehose_delivery_stream.kinesis_firehose_to_elastic.name}"
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

// attach policy to role
resource "aws_iam_role_policy_attachment" "firehose_to_elastic" {
  role = "${aws_iam_role.firehose_to_elastic.name}"
  policy_arn = "${aws_iam_policy.firehose_to_elastic.arn}"
}

// the firehose delivery stream
resource "aws_kinesis_firehose_delivery_stream" "kinesis_firehose_to_elastic" {
  name = "persons_kinesis_to_elasticsearch-${terraform.workspace}"

  kinesis_source_configuration {
    kinesis_stream_arn = "${aws_kinesis_stream.person_stream.arn}"
    role_arn = "${aws_iam_role.firehose_to_elastic.arn}"
  }

  destination = "elasticsearch"
  elasticsearch_configuration {
    domain_arn = "${aws_elasticsearch_domain.persons.arn}"
    index_name = "persons"
    index_rotation_period = "NoRotation"
    type_name = "person"
    role_arn = "${aws_iam_role.firehose_to_elastic.arn}"
    buffering_interval = 60
    s3_backup_mode = "FailedDocumentsOnly"
  }

  s3_configuration {
    bucket_arn = "${aws_s3_bucket.kinesis_firehose_to_elastic_fails.arn}"
    role_arn = "${aws_iam_role.firehose_to_elastic.arn}"
  }
}

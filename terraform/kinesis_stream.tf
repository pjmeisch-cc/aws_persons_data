// kinesis data stream where the objects from the bucket csv files are fed in
resource "aws_kinesis_stream" "person_stream" {
  name = "person_stream-${terraform.workspace}"
  shard_count = 1
  retention_period = 24
}

// policy to allow writing to the stream
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

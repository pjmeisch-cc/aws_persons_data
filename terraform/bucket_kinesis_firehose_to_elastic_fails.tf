// bucket to store failed data
resource "aws_s3_bucket" "kinesis_firehose_to_elastic_fails" {
  region = "${var.region}"
  bucket = "${var.bucket-person_kinesis_to_elastic_fails}-${terraform.workspace}"
  acl = "private"
  // test project, so force_destroy is alright here
  force_destroy = true
}

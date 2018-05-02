//
// bucket for the csv data
//
resource "aws_s3_bucket" "persongenerator_data" {
  region = "${var.region}"
  bucket = "${var.bucket-persongenerator_data}-${terraform.workspace}"
  acl = "private"
  // test project, so force_destroy is alright here
  force_destroy = true
}

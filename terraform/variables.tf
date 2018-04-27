variable "region" {
  default = "eu-central-1"
}

variable "bucket-persongenerator_data" {
  default = "de.codecentric.persongenerator.data"
}
variable "bucket-person_kinesis_to_elastic_fails" {
  default = "de.codecentric.person.kinesis.to.elastic.fails"
}
variable "file-lambda_s3_to_kinesis" {
  default = "../s3_lambda_to_kinesis/s3_lambda_to_kinesis.zip"
}

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
  default = "../lambda_s3_to_kinesis/lambda_s3_to_kinesis.zip"
}
variable "file-lambda_kinesis_to_dynamo" {
  default = "../lambda_kinesis_to_dynamo/lambda_kinesis_to_dynamo.zip"
}

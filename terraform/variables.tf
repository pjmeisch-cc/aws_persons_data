variable "region" {
  default = "eu-central-1"
}

variable "bucket-persongenerator_data" {
  default = "de.codecentric.persongenerator.data"
}
variable "bucket-person_kinesis_to_elastic_fails" {
  default = "de.codecentric.person.kinesis.to.elastic.fails"
}
variable "path-lambda_s3_to_kinesis" {
  default = "../lambda_s3_to_kinesis"
}
variable "file-lambda_kinesis_to_dynamo" {
  default = "../lambda_kinesis_to_dynamo/lambda_kinesis_to_dynamo.zip"
}
variable "file-lambda_dynamo_to_apigateway" {
  default = "../lambda_dynamo_to_apigateway/lambda_dynamo_to_apigateway.zip"
}

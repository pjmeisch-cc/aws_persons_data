// the role for the lambda to assume
resource "aws_iam_role" "lambda_dynamo_to_apigateway" {
  name = "CCRoleForPersonDataLambdaDynamoDBToApiGateway-${terraform.workspace}"
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

// basic lambda execution role
resource "aws_iam_role_policy_attachment" "basic_execution" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role = "${aws_iam_role.lambda_dynamo_to_apigateway.name}"
}

// attach policy for dynamodb
resource "aws_iam_role_policy_attachment" "lambda_dynamo_to_apigateway-read_dynamo" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBReadOnlyAccess"
  role = "${aws_iam_role.lambda_dynamo_to_apigateway.name}"
}

// the lambda itself
resource "aws_lambda_function" "lambda_dynamo_to_apigateway" {
  function_name = "persons_data-dynamo_to_apigateway-${terraform.workspace}"
  handler = "index.handler"
  timeout = 60
  role = "${aws_iam_role.lambda_dynamo_to_apigateway.arn}"
  runtime = "nodejs8.10"
  filename = "${var.file-lambda_dynamo_to_apigateway}"
  source_code_hash = "${base64sha256(file(var.file-lambda_dynamo_to_apigateway))}"
  environment {
    variables {
      DYNAMODB_TABLE = "${aws_dynamodb_table.persons.name}"
      DYNAMODB_TABLE_INDEX2 = "NameIndex-${terraform.workspace}"
    }
  }
}

// allow execution from apigateway
resource "aws_lambda_permission" "apigw_lambda" {
  statement_id = "AllowExecutionFromAPIGateway"
  action = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.lambda_dynamo_to_apigateway.function_name}"
  principal = "apigateway.amazonaws.com"

  // @formatter:off
  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  source_arn = "arn:aws:execute-api:${var.region}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.persons_data.id}/*/*"
  // @formatter:on
}

// the API gateway
// API Gateway
resource "aws_api_gateway_rest_api" "persons_data" {
  name = "persons_data-${terraform.workspace}"
}
resource "aws_api_gateway_resource" "city" {
  rest_api_id = "${aws_api_gateway_rest_api.persons_data.id}"
  parent_id = "${aws_api_gateway_rest_api.persons_data.root_resource_id}"
  path_part = "city"
}
resource "aws_api_gateway_resource" "city_param" {
  rest_api_id = "${aws_api_gateway_rest_api.persons_data.id}"
  parent_id = "${aws_api_gateway_resource.city.id}"
  path_part = "{value}"
}
resource "aws_api_gateway_method" "get_city" {
  authorization = "NONE"
  http_method = "GET"
  rest_api_id = "${aws_api_gateway_rest_api.persons_data.id}"
  resource_id = "${aws_api_gateway_resource.city_param.id}"
}
resource "aws_api_gateway_integration" "get_city" {
  http_method = "${aws_api_gateway_method.get_city.http_method}"
  resource_id = "${aws_api_gateway_resource.city_param.id}"
  rest_api_id = "${aws_api_gateway_rest_api.persons_data.id}"
  type = "AWS"
  integration_http_method = "POST"
  uri = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${aws_lambda_function.lambda_dynamo_to_apigateway.arn}/invocations"
  request_templates {
    "application/json" = <<EOF
    { "field": "city", "value": "$input.params('value')" }
EOF
  }
  depends_on = ["aws_api_gateway_method.get_city"]
}
resource "aws_api_gateway_method_response" "get_city_200" {
  http_method = "${aws_api_gateway_method.get_city.http_method}"
  resource_id = "${aws_api_gateway_resource.city_param.id}"
  rest_api_id = "${aws_api_gateway_rest_api.persons_data.id}"
  status_code = "200"
  depends_on = ["aws_api_gateway_method.get_city"]
}
resource "aws_api_gateway_integration_response" "get_city_200" {
  http_method = "${aws_api_gateway_method.get_city.http_method}"
  resource_id = "${aws_api_gateway_resource.city_param.id}"
  rest_api_id = "${aws_api_gateway_rest_api.persons_data.id}"
  status_code = "${aws_api_gateway_method_response.get_city_200.status_code}"
  selection_pattern = ""
  depends_on = ["aws_api_gateway_method_response.get_city_200", "aws_api_gateway_integration.get_city"]
}
resource "aws_api_gateway_resource" "name" {
  rest_api_id = "${aws_api_gateway_rest_api.persons_data.id}"
  parent_id = "${aws_api_gateway_rest_api.persons_data.root_resource_id}"
  path_part = "name"
}
resource "aws_api_gateway_resource" "name_param" {
  rest_api_id = "${aws_api_gateway_rest_api.persons_data.id}"
  parent_id = "${aws_api_gateway_resource.name.id}"
  path_part = "{value}"
}
resource "aws_api_gateway_method" "get_name" {
  authorization = "NONE"
  http_method = "GET"
  rest_api_id = "${aws_api_gateway_rest_api.persons_data.id}"
  resource_id = "${aws_api_gateway_resource.name_param.id}"
}
resource "aws_api_gateway_integration" "get_name" {
  http_method = "${aws_api_gateway_method.get_name.http_method}"
  resource_id = "${aws_api_gateway_resource.name_param.id}"
  rest_api_id = "${aws_api_gateway_rest_api.persons_data.id}"
  type = "AWS"
  integration_http_method = "POST"
  uri = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${aws_lambda_function.lambda_dynamo_to_apigateway.arn}/invocations"
  request_templates {
    "application/json" = <<EOF
    { "field": "lastName", "value": "$input.params('value')" }
EOF
  }
  depends_on = ["aws_api_gateway_method.get_name"]
}
resource "aws_api_gateway_method_response" "get_name_200" {
  http_method = "${aws_api_gateway_method.get_name.http_method}"
  resource_id = "${aws_api_gateway_resource.name_param.id}"
  rest_api_id = "${aws_api_gateway_rest_api.persons_data.id}"
  status_code = "200"
  depends_on = ["aws_api_gateway_method.get_name"]
}
resource "aws_api_gateway_integration_response" "get_name_200" {
  http_method = "${aws_api_gateway_method.get_name.http_method}"
  resource_id = "${aws_api_gateway_resource.name_param.id}"
  rest_api_id = "${aws_api_gateway_rest_api.persons_data.id}"
  status_code = "${aws_api_gateway_method_response.get_name_200.status_code}"
  selection_pattern = ""
  depends_on = ["aws_api_gateway_method_response.get_name_200", "aws_api_gateway_integration.get_name"]
}

resource "aws_api_gateway_deployment" "persons_data" {
  rest_api_id = "${aws_api_gateway_rest_api.persons_data.id}"
  stage_name = "prod"
  depends_on = ["aws_api_gateway_integration.get_name", "aws_api_gateway_integration.get_city"]
}
output "persons_data_endpoint" {
  value = "${aws_api_gateway_deployment.persons_data.invoke_url}"
}

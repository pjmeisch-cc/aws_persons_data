// the dynamodb table to store the persons in
resource "aws_dynamodb_table" "persons" {
  hash_key = "City"
  range_key = "FullName"
  name = "persons_data-${terraform.workspace}"
  read_capacity = 10
  write_capacity = 10

  "attribute" {
    name = "City"
    type = "S"
  }

  "attribute" {
    name = "FullName"
    type = "S"
  }
}

// the dynamodb table to store the persons in
resource "aws_dynamodb_table" "persons" {
  hash_key = "city"
  range_key = "fullName"
  name = "persons_data-${terraform.workspace}"
  read_capacity = 10
  write_capacity = 10

  "attribute" {
    name = "city"
    type = "S"
  }

  "attribute" {
    name = "fullName"
    type = "S"
  }
}

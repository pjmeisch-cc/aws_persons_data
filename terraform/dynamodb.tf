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

  "attribute" {
    name = "firstName"
    type = "S"
  }

  "attribute" {
    name = "lastName"
    type = "S"
  }

  "global_secondary_index" {
    hash_key = "lastName"
    range_key = "firstName"
    read_capacity = 10
    write_capacity = 10
    name = "NameIndex-${terraform.workspace}"
    projection_type = "ALL"
  }
}

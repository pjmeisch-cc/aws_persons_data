//
//terraform backend configuration
//
terraform {
  backend "s3" {
    bucket = "de.codecentric.basf-test-pj"
    key = "persons_data"
  }
}

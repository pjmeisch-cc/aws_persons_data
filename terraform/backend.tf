//
//terraform backend configuration
//
terraform {
  backend "s3" {
    bucket = "pjmeisch-cc-terraform-bucket"
    key = "persons_data"
  }
}

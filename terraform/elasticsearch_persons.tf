// elasticsearch domain
resource "aws_elasticsearch_domain" "persons" {
  domain_name = "persons-${terraform.workspace}"
  elasticsearch_version = "6.2"
  cluster_config {
    instance_count = 1
    instance_type = "m3.medium.elasticsearch"
  }
}

// allow the user who is creating this to access ES
resource "aws_elasticsearch_domain_policy" "access_persons" {
  domain_name = "${aws_elasticsearch_domain.persons.domain_name}"
  access_policies = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {"AWS": "${data.aws_caller_identity.current.account_id}"},
      "Action": "es:*" ,
      "Resource": "${aws_elasticsearch_domain.persons.arn}"
    }
  ]
}
EOF
}

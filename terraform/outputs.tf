output "elasticsearch_endpoint" {
  value = "${aws_elasticsearch_domain.persons.endpoint}"
}

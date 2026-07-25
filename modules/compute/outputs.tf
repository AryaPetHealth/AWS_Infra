output "environment_endpoint_url" {
  value = aws_elastic_beanstalk_environment.this.endpoint_url
}

output "application_name" {
  value = aws_elastic_beanstalk_application.this.name
}

output "environment_name" {
  value = aws_elastic_beanstalk_environment.this.name
}

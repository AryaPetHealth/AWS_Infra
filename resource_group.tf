# AWS doesn't have Azure-style resource groups that resources are actually
# members of — this is a saved tag-based query that shows every resource
# tagged Project=<project_name>/Environment=<environment> together in one
# place in the console (Resource Groups & Tag Editor). All resources here
# already get those tags via provider default_tags in providers.tf.
resource "aws_resourcegroups_group" "this" {
  name = "${var.project_name}-resources-${var.environment}"
  tags = { Name = "${var.project_name}-resources-${var.environment}" }

  resource_query {
    query = jsonencode({
      ResourceTypeFilters = ["AWS::AllSupported"]
      TagFilters = [
        { Key = "Project", Values = [var.project_name] },
        { Key = "Environment", Values = [var.environment] },
      ]
    })
  }
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# --- IAM: EC2 instance role for the EB app ---

resource "aws_iam_role" "eb_ec2" {
  name = "${var.project_name}-ebstalk-${var.environment}-role"
  tags = { Name = "${var.project_name}-ebstalk-${var.environment}-role" }

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eb_web_tier" {
  role       = aws_iam_role.eb_ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
}

resource "aws_iam_role_policy" "app_permissions" {
  name = "${var.project_name}-ebstalk-${var.environment}-policy"
  role = aws_iam_role.eb_ec2.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "Textract"
        Effect   = "Allow"
        Action   = ["textract:AnalyzeDocument", "textract:DetectDocumentText"]
        Resource = "*"
      },
      {
        Sid      = "DocumentsBucket"
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject"]
        Resource = "${var.documents_bucket_arn}/*"
      },
      {
        Sid      = "ProcessingQueue"
        Effect   = "Allow"
        Action   = ["sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes"]
        Resource = var.processing_queue_arn
      },
      {
        Sid      = "ApnsPush"
        Effect   = "Allow"
        Action   = ["sns:CreatePlatformEndpoint", "sns:Publish", "sns:GetEndpointAttributes", "sns:SetEndpointAttributes"]
        Resource = "*"
      },
      {
        Sid      = "DbSecret"
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = var.db_secret_arn
      }
    ]
  })
}

resource "aws_iam_instance_profile" "eb_ec2" {
  name = "${var.project_name}-ebstalk-${var.environment}-profile"
  role = aws_iam_role.eb_ec2.name
  tags = { Name = "${var.project_name}-ebstalk-${var.environment}-profile" }
}

# --- Elastic Beanstalk ---

resource "aws_elastic_beanstalk_application" "this" {
  name = "${var.project_name}-ebstalk-${var.environment}"
  tags = { Name = "${var.project_name}-ebstalk-${var.environment}" }
}

resource "aws_elastic_beanstalk_environment" "this" {
  name                = "${var.project_name}-ebstalk-${var.environment}-env"
  application         = aws_elastic_beanstalk_application.this.name
  tags                = { Name = "${var.project_name}-ebstalk-${var.environment}-env" }
  solution_stack_name = var.eb_solution_stack_name

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "InstanceType"
    value     = var.eb_instance_type
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.eb_ec2.name
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "SecurityGroups"
    value     = var.security_group_id
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "EnvironmentType"
    value     = "SingleInstance"
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = data.aws_vpc.default.id
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = join(",", data.aws_subnets.default.ids)
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "AssociatePublicIpAddress"
    value     = "true"
  }

  dynamic "setting" {
    for_each = var.environment_variables
    content {
      namespace = "aws:elasticbeanstalk:application:environment"
      name      = setting.key
      value     = setting.value
    }
  }
}

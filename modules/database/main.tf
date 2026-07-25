data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.project_name}-rds-${var.environment}-subnets"
  subnet_ids = data.aws_subnets.default.ids
  tags       = { Name = "${var.project_name}-rds-${var.environment}-subnets" }
}

resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-${var.environment}-sg"
  description = "Allow Postgres access from the EB app"
  vpc_id      = data.aws_vpc.default.id
  tags        = { Name = "${var.project_name}-rds-${var.environment}-sg" }

  ingress {
    description     = "Postgres from EB app"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.app_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "random_password" "db" {
  length  = 32
  special = false
}

resource "aws_db_instance" "this" {
  identifier     = "${var.project_name}-rds-${var.environment}"
  engine         = "postgres"
  engine_version = "16"

  instance_class         = var.db_instance_class
  allocated_storage      = var.db_allocated_storage
  storage_type           = "gp3"
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  db_name  = var.db_name
  username = var.db_username
  password = random_password.db.result

  multi_az                  = false
  publicly_accessible       = false
  backup_retention_period   = 7
  skip_final_snapshot       = false
  final_snapshot_identifier = "${var.project_name}-rds-${var.environment}-final"
  deletion_protection       = true

  tags = { Name = "${var.project_name}-rds-${var.environment}" }
}

resource "aws_secretsmanager_secret" "db" {
  name = "${var.project_name}/rds-${var.environment}"
  tags = { Name = "${var.project_name}-rds-${var.environment}-secret" }
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id

  secret_string = jsonencode({
    username = aws_db_instance.this.username
    password = random_password.db.result
    host     = aws_db_instance.this.address
    port     = aws_db_instance.this.port
    dbname   = aws_db_instance.this.db_name
    engine   = "postgres"
  })
}

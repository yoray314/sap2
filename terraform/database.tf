resource "aws_db_subnet_group" "db" {
  name       = "${var.project}-db-subnet-group"
  subnet_ids = [for s in aws_subnet.private : s.id]
  tags       = { Name = "${var.project}-db-subnet-group" }
}

resource "aws_db_instance" "postgres" {
  identifier                   = "${var.project}-postgres"
  allocated_storage            = 20
  engine                       = "postgres"
  engine_version               = "15"
  instance_class               = var.db_instance_class
  username                     = var.db_username
  db_name                      = var.db_name
  password                     = random_password.db_password.result
  db_subnet_group_name         = aws_db_subnet_group.db.name
  vpc_security_group_ids       = [aws_security_group.db.id]
  skip_final_snapshot          = true
  publicly_accessible          = false
  deletion_protection          = true
  multi_az                     = true
  storage_encrypted            = true
  backup_retention_period = 7
  backup_window           = "02:00-03:00"
  maintenance_window      = "sun:03:00-sun:04:00"
  auto_minor_version_upgrade   = true
  tags                         = { Name = "${var.project}-postgres" }
}

resource "random_password" "db_password" {
  length  = 16
  special = false
}

resource "aws_ssm_parameter" "db_password" {
  name  = "/${var.project}/db/password"
  type  = "SecureString"
  value = random_password.db_password.result
  tags  = { Name = "${var.project}-db-password" }
}

# RDS event subscription for failover / maintenance notifications
resource "aws_db_event_subscription" "db_events" {
  name             = "${var.project}-db-events"
  sns_topic        = aws_sns_topic.alerts.arn
  source_type      = "db-instance" # broad subscription for all DB instances in account/region
  event_categories = ["failover", "failure", "maintenance", "low storage"]
  enabled          = true
}

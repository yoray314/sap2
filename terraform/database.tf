resource "aws_db_subnet_group" "db" {
  name       = "${var.project}-db-subnet-group"
  subnet_ids = [for s in aws_subnet.private : s.id]
  tags       = { Name = "${var.project}-db-subnet-group" }
}

resource "aws_db_instance" "postgres" {
  identifier              = "${var.project}-postgres"
  allocated_storage       = 20
  engine                  = "postgres"
  engine_version          = "15"
  instance_class          = var.db_instance_class
  username                = var.db_username
  db_name                 = var.db_name
  password                = random_password.db_password.result
  db_subnet_group_name    = aws_db_subnet_group.db.name
  vpc_security_group_ids  = [aws_security_group.db.id]
  skip_final_snapshot     = true
  publicly_accessible     = false
  deletion_protection     = false
  multi_az                = false
  storage_encrypted       = true
  backup_retention_period = 0
  tags                    = { Name = "${var.project}-postgres" }
}

resource "random_password" "db_password" {
  length  = 16
  special = false
}

output "db_password" {
  value     = random_password.db_password.result
  sensitive = true
}

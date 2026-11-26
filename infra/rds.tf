resource "aws_db_subnet_group" "rds" {
  name       = "${var.project_name}-rds"
  subnet_ids = aws_subnet.private[*].id
}

resource "aws_db_parameter_group" "pg" {
  name   = "${var.project_name}-pg16"
  family = "postgres16"

  parameter {
    name  = "rds.force_ssl"
    value = "1" # reject any connection that is not TLS
  }
}

resource "aws_db_instance" "postgres" {
  identifier                  = "${var.project_name}-postgres"
  engine                      = "postgres"
  engine_version              = "16"
  instance_class              = "db.t4g.micro" # cheapest ARM instance
  allocated_storage           = 20
  max_allocated_storage       = 100 # storage grows by itself up to 100 GB
  storage_type                = "gp3"
  storage_encrypted           = true
  db_name                     = var.db_name
  username                    = var.db_username
  manage_master_user_password = true # RDS stores the password in Secrets Manager
  db_subnet_group_name        = aws_db_subnet_group.rds.name
  vpc_security_group_ids      = [aws_security_group.rds.id]
  parameter_group_name        = aws_db_parameter_group.pg.name
  publicly_accessible         = false
  multi_az                    = false # set true in production for automatic failover
  backup_retention_period     = 7
  deletion_protection         = false # set true in production
  skip_final_snapshot         = true  # demo only: use false plus final_snapshot_identifier in production
}
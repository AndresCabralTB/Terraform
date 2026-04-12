variable "project_version" {
  type = string
}

variable "vpc_subnet_B_id" {
    type = string
}

variable "vpc_subnet_C_id" {
    type = string
}

locals {
  db_creds = jsondecode(aws_secretsmanager_secret_version.db_credentials.secret_string)
}

resource "aws_db_subnet_group" "terraform_db_SubnetGroup" {
  name = "project_db_subnetgroup"
  subnet_ids = [var.vpc_subnet_B_id, var.vpc_subnet_C_id]
  
}

resource "aws_kms_key" "secrets_key" {
  description             = "KMS key for RDS master user secret"
  deletion_window_in_days = 7
}

resource "aws_db_instance" "ProjectDatabasePROD" {
    allocated_storage       = 10
    availability_zone       = "us-east-1b"
    db_name                 = "TerraformDB"
    db_subnet_group_name    = aws_db_subnet_group.terraform_db_SubnetGroup.name #The subnets where the DB will be deployed
    engine                  = "mysql"
    engine_version          = "8.4.8"
    username                = local.db_creds["username"]
    #password                = local.db_creds["password"]
    manage_master_user_password = true
    master_user_secret_kms_key_id = aws_kms_key.secrets_key.id
    parameter_group_name    = "default.mysql8.4"
    identifier = "terraform-db-${var.project_version}"
    instance_class          = "db.t4g.micro"
    vpc_security_group_ids  = [aws_security_group.TerraformDB-SecurityGroup.id] #The Security groups for the DB
    skip_final_snapshot = true
}
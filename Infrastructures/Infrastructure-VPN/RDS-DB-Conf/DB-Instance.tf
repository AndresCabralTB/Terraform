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
  # db_creds = jsondecode(aws_secretsmanager_secret_version.db_credentials.secret_string) #Set variable to the secrets manager string containing the username and password
}

resource "aws_db_subnet_group" "terraform_db_SubnetGroup" {
  name = "project_db_subnetgroup"
  subnet_ids = [var.vpc_subnet_B_id, var.vpc_subnet_C_id]
  
}

#We will be using an already-existing KMS secret key - but remove this if you want to create a brand new onw
#resource "aws_kms_key" "secrets_key" {
#  description             = "KMS key for RDS master user secret ${var.project_version}"
#  deletion_window_in_days = 7
#}

#Extract the value from an existing secret 
data "aws_kms_key" "secret_key_id" {
  key_id = "96e24ab7-98ee-4746-9ec2-d63d98e5f069"
}

resource "aws_db_instance" "ProjectDatabasePROD" {
    allocated_storage       = 10
    availability_zone       = "us-east-1b"
    db_name                 = "TerraformDB"
    db_subnet_group_name    = aws_db_subnet_group.terraform_db_SubnetGroup.name #The subnets where the DB will be deployed
    engine                  = "mysql"
    engine_version          = "8.4.8"
    username                = "svc_database"
    #username                = local.db_creds["username"] #Get username from secret created - removed because
    #password                = local.db_creds["password"]
    manage_master_user_password = true
    master_user_secret_kms_key_id = data.aws_kms_key.secret_key_id.id
    parameter_group_name    = "default.mysql8.4"
    identifier = "terraform-db-${var.project_version}"
    instance_class          = "db.t4g.micro"
    vpc_security_group_ids  = [aws_security_group.TerraformDB-SecurityGroup.id] #The Security groups for the DB
    skip_final_snapshot = true
}
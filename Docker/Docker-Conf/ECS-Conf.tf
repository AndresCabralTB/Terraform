variable "aws_account_id"{
    type = string
}

variable "desired_tasks" {
    type = number
}

variable "jenkins_image_name" {
  type = string
}

variable "grafana_image_name"{
  type = string
}

variable "efs_id"{
    type = string
}

data "aws_vpc" "vpc"{
    filter {
        name   = "tag:Name"
        values = ["VPC-Terraform-${var.project_environment}"]
  }
}

data "aws_subnet" "subnet_A" {
  filter {
    name   = "tag:Name"
    values = ["VPC-Subnet-A-Terraform-${var.project_environment}"]
  }
}

data "aws_efs_file_system" "efs_tag" {
  tags = {
    Name = "efs-docker-volumes-${var.project_environment}"
  }
}

#Create the ECS Cluster for all PROD ECS Services
resource "aws_ecs_cluster" "docker-cluster" {
    name = "containers-cluster-${var.project_environment}"
}

resource "aws_security_group" "ecs_task_securitygroup" {
  name        = "ecs-task-securitygroup-${var.project_environment}"
  description = "Allow all traffic"
  vpc_id      = data.aws_vpc.vpc.id

  tags = {
    Name = "ecs-task-sg-${var.project_environment}"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ecs_task_securitygroup_ingress" {
  security_group_id = aws_security_group.ecs_task_securitygroup.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  tags = {
      Name = "IngressRule-ECS-Task-SG-${var.project_environment}"
    }
}

resource "aws_vpc_security_group_egress_rule" "ecs_task_securitygroup_egress" {
  security_group_id = aws_security_group.ecs_task_securitygroup.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
  tags = {
      Name = "EgressRule-ECS-Task-SG-${var.project_environment}"
    }
}




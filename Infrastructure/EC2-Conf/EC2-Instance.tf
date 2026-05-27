variable "project_environment" {
    type = string
}

variable "vpc_id" {
  type = string
}

variable "allowed_hosts" {
  type = list
}

#Get the subnet ID through a variable passed from the module calling
variable "subnet_A_id" {
  type = string
}

variable "subnet_B_id" {
  type = string
}

variable "TerraformDB_SecurityGroup_Id" {
  type = string
}

variable "BastionHostAMI" {
    type = string
    default = "Baseline-BastionHost-AMI"
}

variable "PrivateHostAMI" {
    type = string
    default = "Baseline-PrivateHost-AMI"
}

variable "efs_system_id" {
    type = string
}


locals {
  BastionHost_InternalName  = "bastionhost.${var.project_environment}.cabral.cloud"
  PrivateHost_InternalName  = "privatehost.${var.project_environment}.cabral.cloud"
  BastionHost_Name          = "BastionHost-Terraform-${var.project_environment}"
  PrivateHost_Name          = "PrivateHost-Terraform-${var.project_environment}"
  MOUNT_DIR                 = "/mnt/efs"
}

#Retrieve the AMI for the bastion host
data "aws_ami" "bastion_ami" {
    #most_recent = true

    filter {
    name   = "tag:Name"                  # The tag key
    values = ["${var.BastionHostAMI}"]  # The tag value
  }
}

#Retrieve the AMI for the bastion host
data "aws_ami" "privatehost_ami" {
    #most_recent = true

    filter {
    name   = "tag:Name"                  # The tag key
    values = ["${var.PrivateHostAMI}"]  # The tag value
  }
}

# Create the Security Groups
module "SecurityGroups_Module" {
  source              = "./Security-Groups-Conf"
  vpc_id                 = var.vpc_id
  allowed_hosts       = var.allowed_hosts
  TerraformDB_SecurityGroup_Id = var.TerraformDB_SecurityGroup_Id
  project_environment     = var.project_environment
}

#Fetch the instance profile created in the bootstrap workspace
data "aws_iam_instance_profile" "BastionHostProfile" {
  name = "BastionHostProfile-${var.project_environment}"
}

resource "aws_instance" "BastionHost" {
    ami                         = data.aws_ami.bastion_ami.id
    associate_public_ip_address = true
    availability_zone           = "us-east-1a"
    iam_instance_profile        =  data.aws_iam_instance_profile.BastionHostProfile.name
    instance_type               = "t2.micro"
    user_data_replace_on_change = true
    timeouts {
        create = "15m"  # Increases wait time to 15 minutes
      }
    #private_dns_name_options {
    #    enable_resource_name_dns_a_record   = true
    #    hostname_type                       = "resource-name"
    #}
    user_data = <<-EOF
        #!/bin/bash
        mkdir -p ${local.MOUNT_DIR}
        touch ${local.MOUNT_DIR}/test.txt
        mkdir /mnt/test/
        chown 1000:1000 ${local.MOUNT_DIR}
        hostnamectl set-hostname name-test.bastionhost-new-ami
        mount -t efs -o tls ${var.efs_system_id}:/ ${local.MOUNT_DIR}
    EOF

    vpc_security_group_ids      = [module.SecurityGroups_Module.BastionHostSecurityGroup_Id_Output]
    subnet_id                   = var.subnet_A_id

    tags = {
      Name = local.BastionHost_Name
    }
}

resource "aws_instance" "PrivateHost" {
    ami                         = data.aws_ami.privatehost_ami.id
    availability_zone           = "us-east-1b"
    #iam_instance_profile        =  aws_iam_instance_profile.BastionHostProfile.name
    instance_type               = "t2.micro"
    vpc_security_group_ids      = [module.SecurityGroups_Module.PrivateHostSecurityGroup_Id_Output]
    subnet_id                   = var.subnet_B_id
    timeouts {
        create = "15m"  # Increases wait time to 15 minutes
      }
    #private_dns_name_options {
    #    enable_resource_name_dns_a_record   = true
    #    hostname_type                       = "resource-name"
    #}
    user_data = <<-EOF
        #! /bin/bash
        hostnamectl set-hostname ${local.PrivateHost_InternalName}
    EOF
    tags = {
      Name = local.PrivateHost_Name
    }
}

output "BastionHost_Output_Id" {
  value = aws_instance.BastionHost.id
}

output "PrivateHost_Output_Id" {
  value = aws_instance.PrivateHost.id
}

output "BastionHost_PrivateIp_Output" {
  value = aws_instance.BastionHost.private_ip
}

output "PrivateHost_PrivateIp_Output" {
  value = aws_instance.PrivateHost.private_ip
}


output "PrivateHost_SecurityGroup_Id" {
  value = module.SecurityGroups_Module.PrivateHostSecurityGroup_Id_Output
}

output "BastionHost_SecurityGroup_Id" {
  value = module.SecurityGroups_Module.BastionHostSecurityGroup_Id_Output
}

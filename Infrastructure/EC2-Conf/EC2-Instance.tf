variable "project_version" {
    type = string
}

variable "vpc_id" {
  type = string
}

variable "cidr_ipv4_mac" {
  type = string
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


locals {
  BastionHost_InternalName = "bastionhost.cabral.cloud"
  PrivateHost_InternalName = "privatehost.cabral.cloud"
  BastionHost_Name = "BastionHost_Terraform_${var.project_version}"
  PrivateHost_Name = "PrivateHost_Terraform_${var.project_version}"

}

#Retrieve the AMI for the bastion host
data "aws_ami" "bastion_ami" {
    #most_recent = true

    filter {
    name   = "tag:Name"                  # The tag key
    values = ["Bastion Host AMI - 24/04/2026"]  # The tag value
  }
}

#Retrieve the AMI for the bastion host
data "aws_ami" "privatehost_ami" {
    #most_recent = true

    filter {
    name   = "tag:Name"                  # The tag key
    values = ["Private EC2 AMI - 17/03/2026"]  # The tag value
  }
}

# Create the Security Groups
module "SecurityGroups_Module" {
  source              = "./Security-Groups-Conf"
  vpc_id                 = var.vpc_id
  cidr_ipv4_mac       = var.cidr_ipv4_mac
  TerraformDB_SecurityGroup_Id = var.TerraformDB_SecurityGroup_Id
}

#Fetch the instance profile created in the bootstrap workspace
data "aws_iam_instance_profile" "BastionHostProfile" {
  name = "BastionHostProfile"
}

resource "aws_instance" "BastionHost" {
    ami                         = data.aws_ami.bastion_ami.id
    associate_public_ip_address = true
    availability_zone           = "us-east-1a"
    iam_instance_profile        =  data.aws_iam_instance_profile.BastionHostProfile.name
    instance_type               = "t2.micro"
    #private_dns_name_options {
    #    enable_resource_name_dns_a_record   = true
    #    hostname_type                       = "resource-name"
    #}
    user_data = <<-EOF
        #! /bin/bash
        hostnamectl set-hostname ${local.BastionHost_InternalName}
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

output "BastionHost_Output" {
  value = aws_instance.BastionHost
}

output "PrivateHost_Output" {
  value = aws_instance.PrivateHost
}

output "PrivateHost_SecurityGroup_Id" {
  value = module.SecurityGroups_Module.PrivateHostSecurityGroup_Id_Output
}

output "BastionHost_SecurityGroup_Id" {
  value = module.SecurityGroups_Module.BastionHostSecurityGroup_Id_Output
}
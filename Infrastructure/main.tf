#This file will call every resource through modules
module "VPC_Module" {
  source = "./VPC-Conf"
  project_version = var.project_version
}

module "EC2_Module" {
  source = "./EC2-Conf"
  project_version = var.project_version
  subnet_A_id = module.VPC_Module.VPC_Subnet_A_Output.id #Pass the output from the subnet in the VPC module
  subnet_B_id = module.VPC_Module.VPC_Subnet_B_Output.id #Pass the output from the subnet in the VPC module
  vpc_id = module.VPC_Module.VPC_Terraform_Output.id
  cidr_ipv4_mac = var.cidr_ipv4_mac
  TerraformDB_SecurityGroup_Id = module.RDS_Instance_Moduel.TerraformDB_SecurityGroup_Output_id
}

module "RDS_Instance_Moduel" {
  source = "./RDS-DB-Conf"
  project_version = var.project_version
  vpc_id = module.VPC_Module.VPC_Terraform_Output.id
  PrivateHostSG_ID= module.EC2_Module.PrivateHost_SecurityGroup_Id
  vpc_subnet_B_id = module.VPC_Module.VPC_Subnet_B_Output.id
  vpc_subnet_C_id = module.VPC_Module.VPC_Subnet_C_Output.id
  #db_username = var.db_username
  #db_password = var.db_password
}

#Comment out to save resources, but this part of the code will deploy a Client VPN Configuration that allows clients to connect to the VPC through a VPN
module "ClientVPN" {
  source                        = "./Client-VPN-Conf"
  subnet_A_id                   = module.VPC_Module.VPC_Subnet_A_Output.id
  subnet_A_cidr                 = module.VPC_Module.VPC_Subnet_A_Output.cidr_block
  subnet_B_id                   = module.VPC_Module.VPC_Subnet_B_Output.id
  subnet_B_cidr                 = module.VPC_Module.VPC_Subnet_B_Output.cidr_block
  subnet_C_id                   = module.VPC_Module.VPC_Subnet_C_Output.id
  subnet_C_cidr                 = module.VPC_Module.VPC_Subnet_C_Output.cidr_block
  vpn_users                     = ["andres"]
  vpc_id                        = module.VPC_Module.VPC_Terraform_Output.id
  privateHost_SecurityGroup_id  = module.EC2_Module.PrivateHost_SecurityGroup_Id
  bastionHost_SecurityGroup_id  = module.EC2_Module.BastionHost_SecurityGroup_Id
  count                         = var.enable_vpn ? 1 : 0
  project_version = var.project_version
}

module "EventBrideEC2_Module" {
  source = "./Events-Conf"
  project_version = var.project_version
  BastionHost = module.EC2_Module.BastionHost_Output.id
  PrivateHost = module.EC2_Module.PrivateHost_Output.id
  start_crontab = var.start_crontab
  stop_crontab = var.stop_crontab
}

module "Route53_Module" {
  source = "./Route-53-Conf"
  project_version = var.project_version
  vpc_id = module.VPC_Module.VPC_Terraform_Output.id
  bastionhost_private_ip = module.EC2_Module.BastionHost_Output.private_ip
  privatehost_private_ip = module.EC2_Module.PrivateHost_Output.private_ip
}

output "bastionhost_output" {
  value     = module.EC2_Module.BastionHost_Name_Output
}

output "privatehost_output" {
  sensitive = true
  value     = module.EC2_Module.PrivateHost_Name_Output
}
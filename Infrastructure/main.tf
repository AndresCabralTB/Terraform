#This file will call every resource through modules
module "VPC_Module" {
  source = "./VPC-Conf"
  project_version = var.project_version
}

module "BastionHost_Module" {
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
  PrivateHostSG_ID= module.BastionHost_Module.PrivateHost_SecurityGroup.id
  vpc_subnet_B_id = module.VPC_Module.VPC_Subnet_B_Output.id
  vpc_subnet_C_id = module.VPC_Module.VPC_Subnet_C_Output.id
  #db_username = var.db_username
  #db_password = var.db_password
}

#Comment out to save resources, but this part of the code will deploy a Client VPN Configuration that allows clients to connect to the VPC through a VPN
module "Client_VPN_Module" {
  source            = "./Client-VPN-Conf"
  subnet_A_id       = module.VPC_Module.VPC_Subnet_A_Output.id
  subnet_A_cidr     = module.VPC_Module.VPC_Subnet_A_Output.cidr_block
  subnet_B_id       = module.VPC_Module.VPC_Subnet_B_Output.id
  subnet_B_cidr     = module.VPC_Module.VPC_Subnet_B_Output.cidr_block
  vpn_users         = ["alice", "bob", "charlie"]
}

module "EventBrideEC2_Module" {
  source = "./Events-Conf"
  project_version = var.project_version
  BastionHost = module.BastionHost_Module.BastionHost_Output.id
  PrivateHost = module.BastionHost_Module.PrivateHost_Output.id
  start_crontab = var.start_crontab
  stop_crontab = var.stop_crontab
}

module "Route53_Module" {
  source = "./Route-53-Conf"
  project_version = var.project_version
  vpc_id = module.VPC_Module.VPC_Terraform_Output.id
  bastionhost_private_ip = module.BastionHost_Module.BastionHost_Output.private_ip
  privatehost_private_ip = module.BastionHost_Module.PrivateHost_Output.private_ip
}

output "vpn_user_certs" {
  sensitive = true
  value     = module.Client_VPN_Module.vpn_user_certs
}

output "ca_cert" {
  sensitive = true
  value     = module.Client_VPN_Module.ca_cert
}
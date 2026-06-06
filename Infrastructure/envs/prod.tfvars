project_environment  = "prod"
force_redeploy = true
enable_vpn = false
enable_cloudwatch_rule = true
enable_ebs = false
deploy_private_host = false

BastionHostAMI = "BastionHost-Terraform-prod-backup-20260602"
PrivateHostAMI = "PrivateHost-Terraform-prod-backup-20260602"
#Force redeploy
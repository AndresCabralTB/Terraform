project_environment  = "prod"
force_destroy = true
force_redeploy = false
enable_vpn = false
enable_cloudwatch_rule = false
enable_ebs = false
deploy_private_resources = false

BastionHostAMI = "BastionHost-Terraform-prod-backup-20260602"
PrivateHostAMI = "PrivateHost-Terraform-prod-backup-20260602"
#Force redeploy
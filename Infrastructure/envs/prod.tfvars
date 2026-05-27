allowed_hosts = ["177.240.100.3/32","177.240.135.3/32"]
project_environment  = "prod"
force_redeploy = true
backup_on_destroy = true
enable_vpn = false
enable_cloudwatch_rule = true

BastionHostAMI = "BastionHost-Terraform-prod-backup-20260527"
PrivateHostAMI = "PrivateHost-Terraform-prod-backup-20260527"
#Force redeploy
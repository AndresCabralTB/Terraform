allowed_hosts = ["177.240.100.3/32","177.240.135.3/32", "177.240.102.207/32"]
project_environment  = "test"
force_redeploy = true
backup_on_destroy = false
enable_vpn = false
enable_cloudwatch_rule = false

BastionHostAMI = "BastionHost-Terraform-prod-backup-20260601"
PrivateHostAMI = "Baseline-PrivateHost-AMI"
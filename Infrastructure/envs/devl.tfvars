allowed_hosts = ["177.240.100.3/32","177.240.135.3/32"]
project_environment  = "devl"
force_redeploy = false
backup_on_destroy = false
enable_vpn = false
enable_cloudwatch_rule = true

BastionHostAMI = "Baseline-BastionHost-AMI"
PrivateHostAMI = "Baseline-PrivateHost-AMI"
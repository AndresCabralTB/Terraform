cidr_ipv4_mac= "177.240.100.3/32"
project_environment  = "prod"
force_redeploy = true
backup_on_destroy = true
enable_vpn = false
enable_cloudwatch_rule = true

BastionHostAMI = "Baseline-BastionHost-AMI"
PrivateHostAMI = "Baseline-PrivateHost-AMI"
#Force redeploy
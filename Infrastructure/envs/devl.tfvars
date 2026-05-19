cidr_ipv4_mac= "177.240.103.120/32"
project_environment  = "devl"
force_redeploy = true

force_destroy = false
backup_on_destroy = true

enable_vpn = true
enable_cloudwatch_rule = true

BastionHostAMI = "Baseline-BastionHost-AMI"
PrivateHostAMI = "Baseline-PrivateHost-AMI"
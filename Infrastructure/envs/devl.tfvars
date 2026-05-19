cidr_ipv4_mac= "177.240.103.120/32"
project_environment  = "devl"
force_redeploy = true

force_destroy = true
backup_on_destroy = false

enable_vpn = true
enable_cloudwatch_rule = true

BastionHostAMI = "Baseline-BastionHost-AMI"
PrivateHostAMI = "Baseline-PrivateHost-AMI"
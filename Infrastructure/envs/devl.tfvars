cidr_ipv4_mac= "177.240.103.120/32"
project_environment  = "devl"
force_redeploy = false

force_destroy = true
backup_on_destroy = true

enable_vpn = false
enable_cloudwatch_rule = false

BastionHostAMI = "Baseline-BastionHost-AMI"
PrivateHostAMI = "Baseline-PrivateHost-AMI"
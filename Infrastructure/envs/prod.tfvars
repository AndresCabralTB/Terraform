cidr_ipv4_mac= "177.240.103.120/32"
project_environment  = "prod"
force_redeploy = true

force_destroy = true
backup_on_destroy = false

enable_vpn = false
enable_cloudwatch_rule = false

BastionHostAMI = "Baseline-BastionHost-AMI"
PrivateHostAMI = "Baseline-PrivateHost-AMI"
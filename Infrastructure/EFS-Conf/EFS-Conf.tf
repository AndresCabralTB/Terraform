variable "project_environment" {
    type = string
}

variable "subnet_A_id"{
    type = string
}

variable "BastionHost_SG_id"{
    type = string
}
resource "aws_efs_file_system" "efs_system" {
  creation_token = "efs-docker-volumes-${var.project_environment}"
  encrypted = true

  tags = {
    Name = "efs-docker-volumes-${var.project_environment}"
  }
}

resource "aws_efs_mount_target" "efs_mount_target" {
  file_system_id    = aws_efs_file_system.efs_system.id
  subnet_id         = var.subnet_A_id
  security_groups   = ["${var.BastionHost_SG_id}"]
}

resource "aws_efs_file_system" "efs_system_local_to_bastionhost" {
  creation_token    = "efs-local-to-bastionhost"
  #description       = "This it the EFS system to share my local code to the bastion host"
  encrypted         = true

  tags = {
    Name = "efs-local-to-bastionhost"
  }
}

resource "aws_efs_mount_target" "efs_mount_target_local" {
  file_system_id    = aws_efs_file_system.efs_system_local_to_bastionhost.id
  subnet_id         = var.subnet_A_id
  security_groups   = ["${var.BastionHost_SG_id}"]
}

output "efs_system_dns_name" {
    value = aws_efs_file_system.efs_system.dns_name
}
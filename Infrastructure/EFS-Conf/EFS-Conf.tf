variable "project_environment" {
    type = string
}

variable "subnet_A_id"{
    type = string
}
resource "aws_efs_file_system" "efs_system" {
  creation_token = "efs-docker-volumes-${var.project_environment}"

  tags = {
    Name = "efs-docker-volumes-${var.project_environment}"
  }
}

resource "aws_efs_mount_target" "efs_mount_target" {
  file_system_id = aws_efs_file_system.efs_system.id
  subnet_id      = var.subnet_A_id
}
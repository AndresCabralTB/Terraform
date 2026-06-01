variable "project_environment" {
    type = string
}

variable "BastionHost_Id"{
    type = string
}

resource "aws_ebs_volume" "bastionhost_ebs_volumes"{
    availability_zone   = "us-east-1a"
    size                = 10

    tags = {
        Name = "ebs-bh-${var.project_environment}"
    }
}

resource "aws_volume_attachment" "bastionhost_ebs_att"{
    device_name     = "/dev/sda1"
    volume_id       = aws_ebs_volume.bastionhost_ebs_volumes.id
    instance_id     = var.BastionHost_Id
}



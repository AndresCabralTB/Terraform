variable "project_environemnt" {
    type = string
}

variable "BastionHost_Id"{
    type = string
}

resource "aws_ebs_volume" "bastionhost_ebs_volumes"{
    availability_zone   = "us-east-1a"
    size                = 8
}

resource "aws_volume_attachment" "bastionhost_ebs_att"{
    device_name     = "/dev/xyz"
    volume_id       = aws_ebs_volume.bastionhost_ebs_volumes.id
    instance_id     = var.BastionHost_Id
}



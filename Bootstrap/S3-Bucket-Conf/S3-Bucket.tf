variable "project_region"{
    type = string
}

resource "aws_s3_bucket" "vpn_config_bucket"{
    bucket = "cloud-cabral-ovpn-files"
    tags = {
        Name = "cloud-cabral-ovpn-files"
    }
}

resource "aws_s3_bucket_public_access_block" "vpn_configs" {
  bucket                  = aws_s3_bucket.vpn_config_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
  depends_on              = [aws_s3_bucket.vpn_config_bucket]
}

resource "aws_s3_bucket" "jenkins-project-docker"{
    bucket = "jenkins-project-docker"
    tags = {
        Name = "jenkins-project-docker"
    }
}

resource "aws_s3_bucket" "jenkins-project-infrastructure"{
    bucket = "jenkins-project-infrastructure"
    tags = {
        Name = "jenkins-project-infrastructure"
    }
}
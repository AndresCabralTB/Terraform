variable "project_region"{
    type = string
}

resource "aws_s3_bucket" "vpn_config_bucket"{
    bucket = "cloud-cabral-ovpn-files"
    region = var.project_region

    tags = {
        Name = "cloud-cabral-ovpn-files"
    }
}

resource "aws_s3_bucket_public_access_block" "vpn_configs" {
  bucket                  = aws_s3_bucket.vpn_configs_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
  depends_on              = [aws_s3_bucket.vpn_configs_bucket]
}
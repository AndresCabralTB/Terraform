variable "project_version" {
  type = string
}

resource "aws_s3_bucket" "vpn_configs_bucket" {
  count = var.create_resource
  bucket = "cloud-cabral-ovpn-files"
  force_destroy = true
  tags = {
    Name        = "VPN Configs"
    Environment = "Dev"
    Version     = var.project_version
  }
}

resource "aws_s3_bucket_public_access_block" "vpn_configs" {
  count = var.create_resource
  bucket                  = aws_s3_bucket.vpn_configs_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
  depends_on              = [aws_s3_bucket.vpn_configs_bucket]
}
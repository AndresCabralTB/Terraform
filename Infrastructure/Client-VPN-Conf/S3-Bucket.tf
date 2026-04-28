resource "aws_s3_bucket" "vpn_configs" {
  bucket = "cloud-cabral-ovpn-files"

  tags = {
    Name        = "VPN Configs"
    Environment = "Dev"
    Version = var.project_version
  }
}

resource "aws_s3_bucket_public_access_block" "vpn_configs" {
  bucket                  = aws_s3_bucket.vpn_configs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
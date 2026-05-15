data "aws_s3_bucket" "vpn_configs_bucket" {
  bucket = "cloud-cabral-ovpn-files"
}

resource "aws_s3_object" "folder" {
  bucket = data.aws_s3_bucket.vpn_configs_bucket.id
  key    = "${var.project_version}/"  # Trailing slash makes it a folder
}
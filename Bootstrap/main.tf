module "AdminAccessGroup_Module" {
    source = "./Admin-Access-Conf"
}

module "IAMInstanceProfile_Module" {
    source = "./IAM-Instance-Profile"
}

module "S3_Bucket_Module" {
    source = "./S3-Bucket-Conf"
    project_region = var.project_region
}
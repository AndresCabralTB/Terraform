module "IAM_User_Module" {
    source = "./New-User-Conf"
    new_username = var.new_username
}

module "AdminAccessGroup_Module" {
    source = "./Admin-Access-Conf"
    iam_user_name = module..new_user_output
}

module "IAMInstanceProfile_Module" {
    source = "./IAM-Instance-Profile"
}

module "S3_Bucket_Module" {
    source = "./S3-Bucket-Conf"
    project_region = var.project_region
}

output "new_username_output" {
    value = module.IAM_User_Module.new_user_output
}
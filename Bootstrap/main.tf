module "IAM_User_Module" {
    source                  = "./New-User-Conf"
    infrastructure_user     = var.infrastructure_user
    docker_user             = var.docker_user
    project_environment     = var.project_environment
}

module "AdminAccessGroup_Module" {
    source              = "./Admin-Access-Conf"
    infrastructure_user       = module.IAM_User_Module.infrastructure_user_output
    docker_user             = module.IAM_User_Module.docker_user_output
    project_environment = var.project_environment
}

module "IAMInstanceProfile_Module" {
    source              = "./IAM-Instance-Profile"
    project_environment = var.project_environment
}

module "S3_Bucket_Module" {
    source          = "./S3-Bucket-Conf"
    project_region  = var.project_region
}

output "infrastructure_user_output" {
    value = module.IAM_User_Module.infrastructure_user_output
}

output "docker_user_output" {
    value = module.IAM_User_Module.docker_user_output
}
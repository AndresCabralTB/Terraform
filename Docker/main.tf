module "ECR_Module"{
    source                      = "./Docker-Conf"
    aws_account_id              = var.aws_account_id
    project_environment         = var.project_environment
    desired_tasks               = var.desired_tasks
    jenkins_image_name          = var.jenkins_image_name
    garafana_image_name         = var.garafana_image_name
    efs_id                      = var.efs_id #Currently not used
}
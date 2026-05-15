resource "module" "ECR_Module"{
    source = "./Docker-Conf"
    project_environment = var.project_environment
}
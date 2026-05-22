project_environment = "prod"
force_redeploy = true
force_destroy = false
desired_tasks = 2
image_name = "718254829448.dkr.ecr.us-east-1.amazonaws.com/docker-images-repo-${var.project_environment}:terraform-image-v4-amd64"
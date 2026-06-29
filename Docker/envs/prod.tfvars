aws_account_id = "718254829448"
project_environment = "prod"
force_redeploy = true
desired_tasks = 1
jenkins_image_name = "jenkins-image-linuxamd64-v8.0"
grafana_image_name = "grafana-image-v2.0"
enable_grafana = false
#efs_id = "fs-06e648d04941f658c"  #Currently not used - Instead ECS gets the Terraform data source
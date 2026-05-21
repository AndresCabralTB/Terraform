resource "aws_ecs_service" "ECS-Service" {
    name    = "Docker-container-${var.project_environment}"
    cluster = aws_ecs_cluster.docker-cluster.id
    task_definition = aws_ecs_task_definition.docker-task.arn
    desired_count = 1
    
}

resource "aws_ecs_cluster" "docker-cluster" {
    name = "docker-cluster-${var.project_environment}"

}
resource "aws_ecs_task_definition" "docker-task" {
    family = "${var.project_environment}"
    container_definitions = jsonencode([
        {
            name    =  "docker-task-${var.project_environment}"
            image   = "718254829448.dkr.ecr.us-east-1.amazonaws.com/ecr-repo-unkown:docker-image-test1"
            cpu     = 1
            memory  = 256
            essential   = true
            portMappings = [
                {
                    containerPort   = 443
                    hostPort        = 443
                }
            ]
        }
    ])

    volume {
        name        = "jenkins-volume"
        host_path   = ""
    }
}
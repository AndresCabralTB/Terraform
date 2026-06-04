#Create the Jenkins Service
resource "aws_ecs_service" "Jenkins-Service" {
    name    = "jenkins-service-${var.project_environment}"
    cluster = aws_ecs_cluster.docker-cluster.id
    task_definition = aws_ecs_task_definition.jenkins-task.arn
    desired_count = var.desired_tasks
    launch_type     = "FARGATE"  # or "EC2"
    enable_execute_command = true        # add to allow connections to the docker container
    
    
    network_configuration {                                        # block, not = {}
        assign_public_ip = true
        security_groups  = [aws_security_group.ecs_task_securitygroup.id]
        subnets          = [data.aws_subnet.subnet_A.id]             # must be a list
    }
}

# Create the task definition for the Jenkins ECS Task
resource "aws_ecs_task_definition" "jenkins-task" {
    family                   = var.project_environment
    network_mode             = "awsvpc"        # required for Fargate
    requires_compatibilities = ["FARGATE"]     # required for Fargate
    cpu                      = "1024"           # task-level, not container-level
    memory                   = "2048"           # task-level
    execution_role_arn       = aws_iam_role.ecs-task-role.arn
    task_role_arn            = aws_iam_role.ecs-task-role.arn  # runtime permissions

    volume {
        name = "jenkins-home"
        efs_volume_configuration {
            file_system_id = data.aws_efs_file_system.efs_tag.file_system_id
            root_directory = "/jenkins"
        }
    }

    container_definitions = jsonencode([
        {
        name      = "jenkins-task-${var.project_environment}"
        image     = "${var.aws_account_id}.dkr.ecr.us-east-1.amazonaws.com/docker-images-repo-${var.project_environment}:${var.jenkins_image_name}"
        cpu       = 1024
        memory    = 2048
        essential = true
        portMappings = [
            {
            containerPort = 8080
            hostPort      = 8080
            }
        ]
        
        mountPoints = [
            {
                sourceVolume  = "jenkins-home"    # must match volume name above
                containerPath = "/var/jenkins_home"
                readOnly      = false
            }
        ]
        # Logging config
        logConfiguration = {
            logDriver = "awslogs"
            options = {
            awslogs-group         = "/ecs/jenkins/${var.project_environment}"
            awslogs-region        = "us-east-1"
            awslogs-stream-prefix = "ecs"
            }
        }
        }
    ])
}

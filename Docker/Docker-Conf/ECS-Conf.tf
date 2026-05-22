variable "desired_tasks" {
    type = number
}

variable "image_name" {
  type = string
}
data "aws_vpc" "vpc"{
    filter {
        name   = "tag:Name"
        values = ["VPC-Terraform-${var.project_environment}"]
  }
}

data "aws_subnet" "subnet_A" {
  filter {
    name   = "tag:Name"
    values = ["VPC-Subnet-A-Terraform-${var.project_environment}"]
  }
}

resource "aws_security_group" "ecs_task_securitygroup" {
  name        = "ecs-task-securitygroup-${var.project_environment}"
  description = "Allow all traffic"
  vpc_id      = data.aws_vpc.vpc.id

  tags = {
    Name = "ecs-task-sg-${var.project_environment}"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ecs_task_securitygroup_ingress" {
  security_group_id = aws_security_group.ecs_task_securitygroup.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  tags = {
      Name = "IngressRule-ECS-Task-SG-${var.project_environment}"
    }
}

resource "aws_vpc_security_group_egress_rule" "ecs_task_securitygroup_egress" {
  security_group_id = aws_security_group.ecs_task_securitygroup.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
  tags = {
      Name = "EgressRule-ECS-Task-SG-${var.project_environment}"
    }
}

resource "aws_cloudwatch_log_group" "log_group" {
  name              = "/ecs/${var.project_environment}"
  retention_in_days = 30

  tags = {
    Environment = "${var.project_environment}"
    ManagedBy   = "terraform"
  }
}

resource "aws_ecs_service" "ECS-Service" {
    name    = "Docker-container-${var.project_environment}"
    cluster = aws_ecs_cluster.docker-cluster.id
    task_definition = aws_ecs_task_definition.docker-task.arn
    desired_count = var.desired_tasks
    launch_type     = "FARGATE"  # or "EC2"
    enable_execute_command = true        # add to allow connections to the docker container

    
    
    network_configuration {                                        # block, not = {}
        assign_public_ip = true
        security_groups  = [aws_security_group.ecs_task_securitygroup.id]
        subnets          = [data.aws_subnet.subnet_A.id]             # must be a list
    }
}

resource "aws_ecs_cluster" "docker-cluster" {
    name = "docker-cluster-${var.project_environment}"
}

data "aws_efs_file_system" "efs_file_system" {
  tags = {
    Name = "efs-docker-volumes-${var.project_environment}"
  }
}

resource "aws_ecs_task_definition" "docker-task" {
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
        file_system_id = data.aws_efs_file_system.efs_file_system.file_system_id 
        root_directory = "/"
        }
    }


    container_definitions = jsonencode([
        {
        name      = "docker-task-${var.project_environment}"
        image     = "${var.image_name}"
        cpu       = 1024
        memory    = 2048
        essential = true
        portMappings = [
            {
            containerPort = 443
            hostPort      = 443
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
            awslogs-group         = "/ecs/${var.project_environment}"
            awslogs-region        = "us-east-1"
            awslogs-stream-prefix = "ecs"
            }
        }
        }
    ])
}
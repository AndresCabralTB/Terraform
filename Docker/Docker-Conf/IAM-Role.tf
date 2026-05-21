resource "aws_iam_role" "ecs-task-role" {
  name = "ecs-role-${var.project_environment}"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "ECS-RolePolicy" {
    name = "ECS-RolePolicy-${var.project_environment}"
    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                # ---- Statement 1: ECS ----
                Action = ["ecs:*"]
                Effect = "Allow"
                Resource = ["*"]
            },
            {
                # ---- Statement 2: PassRole Permission ----
                Action = ["iam:PassRole"]
                Effect = "Allow"
                Resource = ["*"]
            },
            {
                # ---- Logging permissions ----
                Action = [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
                ]
                Effect   = "Allow"
                Resource = ["*"]
            },
            {
                # ---- ECR Permissions ----
                Action = ["ecr:*"]
                Effect   = "Allow"
                Resource = ["*"]
            }
            
        ]
    })
    role = aws_iam_role.ecs-task-role.id
}
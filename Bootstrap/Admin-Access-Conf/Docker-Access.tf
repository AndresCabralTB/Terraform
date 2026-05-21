#Stand-alone script to create the Admin Access Group with a few AWS Managed Policies to gain access to the most important resources for this project

variable "docker_user" {
  type = string
}

resource "aws_iam_group" "DockerAccessGroup" {
    name = "Docker-Group-${var.project_environment}"
}

resource "aws_iam_group_policy_attachment" "DockerAccessGroupPolicies" {
    group = aws_iam_group.DockerAccessGroup.id
    for_each = toset ([
        #AWS Managed
        "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess",
        "arn:aws:iam::aws:policy/AmazonECS_FullAccess",
        "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
    ])
    policy_arn = each.value
}

resource "aws_iam_user_group_membership" "DockerAccessTeam" {
  user = var.docker_user
  groups = [
    aws_iam_group.DockerAccessGroup.name
  ]
}

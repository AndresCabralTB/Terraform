variable "project_environment" {
    type = string
    default = "unkown"
}

variable "project_region" {
    type = string
    default = "us-east-1"
}

variable "desired_tasks" {
    type = number
    default = 1
}

variable "image_name" {
    type = string
    default = "718254829448.dkr.ecr.us-east-1.amazonaws.com/docker-images-repo-prod:terraform-image-v4-amd64"
}

variable "efs_id"{
    type = string
    default = ""
}

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
    default = "Image-Not-Defined"
}

variable "aws_account_id" {
    type = string
    default = "AWS Account ID not defined"
}

variable "efs_id"{
    type = string
    default = ""
}

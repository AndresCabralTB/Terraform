variable "project_region" {
    type    = string
    default = "us-east-1"
}

variable "infrastructure_user" {
    type    = string
    default = "Jenkins-Infrastructure" 
}

variable "docker_user" {
    type    = string
    default = "Jenkins-Docker" 
}

variable "project_environment" {
    type = string
    default = "Unknown"
}

variable "aws_account_id" {
    type = string
    default = "unknown"
}

#==================================
#Variables to avoid warnings

variable "force_redeploy" {
    type = bool
    default = false
}

variable "force_destroy" {
    type = bool
    default = false
}
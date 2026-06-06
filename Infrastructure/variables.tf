variable "start_crontab" {
  type      = string
  default   = "cron(0 15 * * ? *)"
}

variable "stop_crontab" {
  type      = string
  default   = "cron(30 5 * * ? *)"
}

variable "BastionHostAMI" {
    type        = string
    default     = "Baseline-BastionHost-AMI"
}

variable "PrivateHostAMI" {
    type        = string
    default     = "Baseline-PrivateHost-AMI"
}

variable "project_environment" {
    type            = string 
    default         = "unknown"
    description     = "This is the environment control"
}

variable "project_version" {
    type            = string 
    default         = "unknown"
    description     = "This is the environment control"
}

variable "enable_vpn" {
  type      = bool 
  default   = false
}

variable "enable_cloudwatch_rule" {
  type      = bool
  default   = true
}

variable "project_region" {
  type      = string
  default   = "us-east-1"
}

variable "workspace"{
  type      = string
  default   = "workspace"
}
#==================================
# Sensitive variables will be configured from Jenkins
#==================================

variable "allowed_hosts" {
  type          = list
  default       = [""]
  description   = "This is the Public IP for hosts allowed to ssh into the bastion host"
}

# Pass the variables to an environment variable with:
# terraform TF_VAR_db_username="**********"
# terraform TF_VAR_db_password="**********"
variable "db_username" {
  description = "Database master username"
  type        = string
  sensitive   = true
  default     = "test_user" #Filler so that pipeline executes
}

variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
  default     = "test_password" #Filler so that pipeline executes
}

variable "force_redeploy" {
    type        = bool
    default     = false
}

variable "force_destroy" {
    type        = bool
    default     = false
}

variable "backup_on_destroy" {
    type        = bool
    default     = true
}

variable "enable_ebs" {
    type = bool
    default = false
}

variable "deploy_private_resources"{
  type = bool
  default = true
}
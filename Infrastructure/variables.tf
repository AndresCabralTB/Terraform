variable "start_crontab" {
  type = string
  default = "cron(0 15 * * ? *)"
}

variable "stop_crontab" {
  type = string
  default = "cron(30 5 * * ? *)"
}

variable "project_version" {
    type = string 
    default = "v4"
    description = "This is the version control"
}

variable "enable_vpn" {
  type = string
  default = "false"
}

#==================================
# Sensitive variables will be configured from Jenkins
#==================================

variable "cidr_ipv4_mac" {
  type = string
  description = "This is the Public IP for my Mac"
}

# Pass the variables to an environment variable with:
# terraform TF_VAR_db_username="**********"
# terraform TF_VAR_db_password="**********"
variable "db_username" {
  description = "Database master username"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
}

variable "project_version" {
    type = string 
    default = "v4"
    description = "This is the version control"
}

variable "start_crontab" {
  type = string
  default = "cron(0 15 * * ? *)"
}

variable "stop_crontab" {
  type = string
  default = "cron(30 3 * * ? *)"
}


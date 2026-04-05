variable "project_version" {
    type = string 
    default = "v3"
    description = "This is the version control"
}

variable "cidr_ipv4_mac" {
  type = string
  default = "177.240.103.120/32"
  description = "This is the Public IP for my Mac"
}

variable "start_crontab" {
  type = string
  default = "cron(0 15 * * ? *)"
}

variable "stop_crontab" {
  type = string
  default = "cron(0 3 * * ? *)"
}
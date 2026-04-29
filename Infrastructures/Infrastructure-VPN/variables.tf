variable "start_crontab" {
  type = string
  default = "cron(0 15 * * ? *)"
}

variable "stop_crontab" {
  type = string
  default = "cron(30 5 * * ? *)"
}

variable "enable_vpn" {
  type = string
  default = "false"
}


# Resolves the current AWS partition (e.g. "aws", "aws-us-gov") and region
# dynamically — avoids hardcoding values that differ across environments.
data "aws_partition" "current" {}
data "aws_region" "current" {}

# Cron schedules for start/stop — defaulting to 15:00 UTC (start) and 03:00 UTC (stop).
# Override these per environment via tfvars to match working hours.
variable "start_crontab" {
  type    = string
}
variable "stop_crontab" {
  type    = string
}

# EventBridge rule that fires on the start schedule.
# role_arn grants EventBridge permission to invoke the SSM automation target.
resource "aws_cloudwatch_event_rule" "StartBastion" {
  name                = "StartBastionHostEventRule"
  schedule_expression = var.start_crontab
  state               = "ENABLED"
  role_arn            = aws_iam_role.EventBridgeRole.arn

  tags = {
    Name = "StartBastionEventRule-${var.project_version}"
  }
}

# Mirror of StartBastion — fires on the stop schedule.
resource "aws_cloudwatch_event_rule" "StopBastion" {
  name                = "StopBastionHostEventRule"
  schedule_expression = var.stop_crontab
  state               = "ENABLED"
  role_arn            = aws_iam_role.EventBridgeRole.arn

  tags = {
    Name = "StopBastionEventRule-${var.project_version}"
  }
}

# Connects StartBastion rule → SSM AWS-StartEC2Instance runbook.
# - arn: targets the SSM automation document (account-less ARN — AWS-managed docs live in AWS's account).
# - input: passes the instance ID and the role SSM should assume during execution (AutomationAssumeRole).
# - role_arn: the role EventBridge uses to call ssm:StartAutomationExecution.
resource "aws_cloudwatch_event_target" "StartBastionTarget" {
  arn  = "arn:${data.aws_partition.current.partition}:ssm:${data.aws_region.current.name}::automation-definition/AWS-StartEC2Instance"
  rule = aws_cloudwatch_event_rule.StartBastion.name

  input = jsonencode({
    "InstanceId"           : ["${var.BastionHost}"],
    "AutomationAssumeRole" : ["${aws_iam_role.EventBridgeRole.arn}"]
  })

  role_arn = aws_iam_role.EventBridgeRole.arn
}

# Mirror of StartBastionTarget — routes StopBastion rule → AWS-StopEC2Instance runbook.
resource "aws_cloudwatch_event_target" "StopBastionTarget" {
  arn  = "arn:${data.aws_partition.current.partition}:ssm:${data.aws_region.current.name}::automation-definition/AWS-StopEC2Instance"
  rule = aws_cloudwatch_event_rule.StopBastion.name

  input = jsonencode({
    "InstanceId"           : ["${var.BastionHost}"],
    "AutomationAssumeRole" : ["${aws_iam_role.EventBridgeRole.arn}"]
  })

  role_arn = aws_iam_role.EventBridgeRole.arn
}
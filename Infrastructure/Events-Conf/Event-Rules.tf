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

variable "BastionHost" {
    type = string
}

variable "PrivateHost" {
    type = string
}

# EventBridge rule that fires on the start schedule.
# role_arn grants EventBridge permission to invoke the SSM automation target.
resource "aws_cloudwatch_event_rule" "StartEC2Instances" {
  name                = "StartEC2InstancesEventRule-${var.project_environment}"
  schedule_expression = var.start_crontab
  state               = "ENABLED"
  #role_arn            = aws_iam_role.EventBridgeRole.arn #Not needed as it's declared in the target

  tags = {
    Name = "StartEC2InstancesEventRule-${var.project_environment}"
  }
}

# Connects StartBastion rule → SSM AWS-StartEC2Instance runbook.
# - arn: targets the SSM automation document (account-less ARN — AWS-managed docs live in AWS's account).
# - input: passes the instance ID and the role SSM should assume during execution (AutomationAssumeRole).
# - role_arn: the role EventBridge uses to call ssm:StartAutomationExecution.
resource "aws_cloudwatch_event_target" "StartEC2InstancesTarget" {
  arn  = "arn:${data.aws_partition.current.partition}:ssm:${data.aws_region.current.name}::automation-definition/AWS-StartEC2Instance"
  rule = aws_cloudwatch_event_rule.StartEC2Instances.name

  input = jsonencode({
    "InstanceId"           : ["${var.BastionHost}", "${var.PrivateHost}"],
    "AutomationAssumeRole" : ["${aws_iam_role.EventBridgeRole.arn}"]
  })

  role_arn = aws_iam_role.EventBridgeRole.arn
}

# DO YOU ALWAYS NEED BOTH A RULE AND A TARGET?
# ---------------------------------------------
# Yes, always. They are separate concerns:
#   - Rule  → defines WHEN (schedule or event pattern)
#   - Target → defines WHAT and HOW (destination + input payload + permissions)
# A rule can have MULTIPLE targets, e.g.:
#   StartBastion rule
#     ├── Target 1: Start EC2 instances (SSM Automation)
#     ├── Target 2: Post Slack notification (Lambda)
#     └── Target 3: Log the event (CloudWatch Logs)
# A rule with no target is valid in AWS/Terraform but fires into the void — easy misconfiguration to miss.
# The AWS API itself separates PutRule and PutTargets as distinct calls, so Terraform models them
# as distinct resources (aws_cloudwatch_event_rule + aws_cloudwatch_event_target).

# Mirror of StartBastion — fires on the stop schedule.
resource "aws_cloudwatch_event_rule" "StopEC2Instances" {
  name                = "StopEC2InstancesEventRule-${var.project_environment}"
  schedule_expression = var.stop_crontab
  state               = "ENABLED"
  #role_arn            = aws_iam_role.EventBridgeRole.arn #Not needed as it's declared in the target

  tags = {
    Name = "StopEC2InstancesEventRule-${var.project_environment}"
  }
}

# Mirror of StartBastionTarget — routes StopBastion rule → AWS-StopEC2Instance runbook.
resource "aws_cloudwatch_event_target" "StopEC2InstancesTarget" {
  arn  = "arn:${data.aws_partition.current.partition}:ssm:${data.aws_region.current.name}::automation-definition/AWS-StopEC2Instance"
  rule = aws_cloudwatch_event_rule.StopEC2Instances.name

  input = jsonencode({
    "InstanceId"           : ["${var.BastionHost}", "${var.PrivateHost}"],
    "AutomationAssumeRole" : ["${aws_iam_role.EventBridgeRole.arn}"]
  })

  role_arn = aws_iam_role.EventBridgeRole.arn
}

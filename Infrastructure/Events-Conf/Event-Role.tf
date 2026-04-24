variable "project_version" {
    type = string
}

resource  "aws_iam_role" "EventBridgeRole" {
    assume_role_policy = jsonencode({
        Version = "2012-10-17",
        Statement = [
            {
                Effect = "Allow"
                Principal = {
                    Service = [
                        "events.amazonaws.com",
                        "ssm.amazonaws.com"
                        ]
                }
                Action = "sts:AssumeRole"
            }
        ]
    })
}

resource "aws_iam_role_policy" "EventBridgeRolePolicy" {
    name = "EventBridgeRolePolicy-${var.project_version}"
    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                # ---- Statement 1: SSM Automation Permission ----
                # ssm:StartAutomationExecution = the API call that triggers an SSM runbook.
                # A runbook is a pre-built set of automated steps — AWS-StopEC2Instance
                # and AWS-StartEC2Instance are AWS-managed runbooks that handle
                # verifying, stopping/starting, and confirming the instance state.
                # Resource uses document/ ARN format — even though EventBridge targets
                # use automation-definition/, IAM permission checks use document/ internally.
                # automation-execution/* allows tracking the execution status after it starts.
                Action = "ssm:StartAutomationExecution"
                Effect = "Allow"
                Resource = [
                    "arn:aws:ssm:*:*:document/AWS-StopEC2Instance",
                    "arn:aws:ssm:*:*:document/AWS-StartEC2Instance",
                    "arn:aws:ssm:*:*:automation-execution/*"
                ]
            },
            {
                # ---- Statement 2: EC2 Permission ----
                # Even though SSM executes the runbook, the role itself still needs
                # direct EC2 permissions — SSM acts on behalf of this role, so AWS
                # checks these permissions against the role, not SSM.
                # Scoped to specific instance ARNs in production for least privilege:
                # - !Sub arn:${AWS::Partition}:ec2:${AWS::Region}:${AWS::AccountId}:instance/${BastionHost}
                # - !Sub arn:${AWS::Partition}:ec2:${AWS::Region}:${AWS::AccountId}:instance/${PrivateHost}
                Action = [
                    "ec2:StartInstances",
                    "ec2:StopInstances"
                ]
                Effect = "Allow"
                Resource = [
                    "*"
                ]
            },
            {
                # ---- Statement 3: PassRole Permission ----
                # iam:PassRole allows EventBridge to hand this role to SSM.
                # Without it, EventBridge can call SSM but SSM rejects the role handoff.
                # This is required any time EventBridge delegates work to a service
                # that needs a role to act on your behalf (SSM, ECS, CodePipeline etc.)
                # Scoped to this specific role only — not all roles in the account.
                Action = [
                    "iam:PassRole"
                ]
                Effect = "Allow"
                Resource = [
                    "*"
                ]
            }
            
        ]
    })
    role = aws_iam_role.EventBridgeRole.id
}

output "EventBridgeRoleOutputARN" {
    value = aws_iam_role.EventBridgeRole.arn
}
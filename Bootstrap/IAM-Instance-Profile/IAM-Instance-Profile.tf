data "aws_caller_identity" "current" {}  # Gets Account ID
data "aws_partition" "current" {}        # Gets partition (aws, aws-cn, aws-us-gov)
data "aws_region" "current" {}           # Gets current region

resource "aws_iam_role" "SSMSessionManagerRole" {
    name = "RoleBastionHost"
    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Action = "sts:AssumeRole"
                Effect = "Allow"
                Principal = {
                    Service = "ec2.amazonaws.com" //EC2 Can assume this role
                }
            }
        ]
    })
    max_session_duration = 3600
    tags = {
      name = "RoleBastionHost"
    }
}

resource "aws_iam_role_policy_attachment" "AmazonEC2FullAccess" {
    role = aws_iam_role.SSMSessionManagerRole.name
    for_each = toset ([
        "arn:aws:iam::aws:policy/AmazonEC2FullAccess",
        "arn:aws:iam::aws:policy/EC2InstanceConnect"
    ])
    policy_arn = each.value
}

resource "aws_iam_role_policy" "BastionHostRolePolicy" {
    name = "BastionHost_Policy"
    role = aws_iam_role.SSMSessionManagerRole.id
    # Terraform's "jsonencode" function converts a
    # Terraform expression result to valid JSON syntax.
    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                # Action: open a new SSM terminal session
                # Resource: scoped to any EC2 instance, using the approved session document only
                Action = "ssm:StartSession"
                Effect = "Allow"
                Resource = [
                    "arn:aws:ec2:*:*:instance/*",                         # any EC2 instance
                    "arn:aws:ssm:*:*:document/SSM-SessionManagerRunShell"  # approved session document
                ]
            },
            {
                # Action: open the encrypted data channel that carries keystrokes and terminal output
                # Resource: scoped to sessions owned by the calling user only — cannot hijack other sessions
                Action = [
                    #"ssmmessages:CreateControlChannel",  
                    #"ssmmessages:CreateDataChannel",     
                    #"ssmmessages:OpenControlChannel",    
                    "ssmmessages:OpenDataChannel"        
                    ]
                Effect = "Allow"
                Resource = "arn:${data.aws_partition.current.partition}:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:session/*"
            },
            {
                # Action: read-only visibility into sessions and instance connectivity
                # Resource: * required — describe actions cannot be scoped to specific resources
                Action = [
                    "ssm:DescribeSessions", 
                    "ssm:GetConnectionStatus",
                    "ssm:DescribeInstanceProperties",
                    "ec2:DescribeInstances"
                    ]
                Effect = "Allow"
                Resource = "*"
            },
            {
                # Action: end or resume a session
                # Resource: scoped to the calling user's own sessions only — cannot terminate others
                Action = [
                    "ssm:TerminateSession", 
                    "ssm:ResumeSession"
                    ]
                Effect = "Allow"
                Resource = "arn:${data.aws_partition.current.partition}:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:session/*"
            },
            {
                # Action: generate a KMS data key for encrypting session data
                # Resource: scoped to any KMS key — tighten to a specific key ARN in production
                Action = "kms:GenerateDataKey"
                Effect = "Allow"
                Resource = "arn:aws:kms:*:*:key/*"
            }
        ]
    })
}

#Create the instance profile and assign it the role to take
resource "aws_iam_instance_profile" "BastionHostProfile" {
    name = "BastionHostProfile"
    role = aws_iam_role.SSMSessionManagerRole.name
}

#Output the Bastion Role instance - this is not needed because the EC2 is in the same module
output "BastionHostRoleInstanceProfileOutput" {
  value = aws_iam_instance_profile.BastionHostProfile.name
}

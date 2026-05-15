#Stand-alone script to create the Admin Access Group with a few AWS Managed Policies to gain access to the most important resources for this project

variable "iam_user_name" {
  type = string
}

resource "aws_iam_group" "AdminAccessGroup" {
    name = "AdminAccessGroup"
}

resource "aws_iam_group_policy_attachment" "AdminAccessGroupPolicies" {
    group = aws_iam_group.AdminAccessGroup.id
    for_each = toset ([
        #AWS Managed
               # --- Compute ---
        "arn:aws:iam::aws:policy/AmazonEC2FullAccess",        # Full EC2 management — instances, AMIs, key pairs
        "arn:aws:iam::aws:policy/EC2InstanceConnect",         # Allows browser-based SSH via EC2 Instance Connect
        "arn:aws:iam::aws:policy/AmazonRDSFullAccess",        # Full RDS management — instances, snapshots, parameter groups
        "arn:aws:iam::aws:policy/AmazonS3FullAccess",         # Full S3 access — buckets, objects, policies
        "arn:aws:iam::718254829448:policy/AWSSecretsManager_ReadAccessOnly",  # Read-only — can retrieve secrets but not modify them
        "arn:aws:iam::aws:policy/AWSCloudShellFullAccess",    # Browser-based terminal access to AWS CLI
        "arn:aws:iam::aws:policy/IAMUserChangePassword",      # Allows users to change their own password only
        "arn:aws:iam::718254829448:policy/AdminAccess_Policy",
        "arn:aws:iam::718254829448:policy/New_Systems_Manager_Policy"
    ])
    policy_arn = each.value
}

resource "aws_iam_user_group_membership" "AdminAccessTeam" {
  user = var.iam_user_name
  groups = [
    aws_iam_group.AdminAccessGroup.name
  ]
}

#Stand-alone script to create the Admin Access Group with a few AWS Managed Policies to gain access to the most important resources for this project
data "aws_caller_identity" "current" {}

data "aws_iam_user" "current_user" {
  user_name = regex("[^/]+$", data.aws_caller_identity.current.arn)
}

resource "aws_iam_group" "AdminAccessGroup" {
    name = "AdminAccessGroup"
}


resource "aws_iam_group_policy_attachment" "AdminAccessGroupPolicies" {
    group = aws_iam_group.AdminAccessGroup.id
    for_each = toset ([
        #AWS Managed
        "arn:aws:iam::aws:policy/AmazonEC2FullAccess",
        "arn:aws:iam::aws:policy/EC2InstanceConnect",
        "arn:aws:iam::aws:policy/AmazonRDSFullAccess",
        "arn:aws:iam::aws:policy/AmazonS3FullAccess",
        "arn:aws:iam::aws:policy/AWSCloudShellFullAccess",
        "arn:aws:iam::aws:policy/AWSCertificateManagerFullAccess",
        "arn:aws:iam::aws:policy/AmazonEventBridgeFullAccess",
        "arn:aws:iam::aws:policy/AmazonRoute53FullAccess",
        "arn:aws:iam::aws:policy/IAMFullAccess",
        #Customer Managed
        "arn:aws:iam::718254829448:policy/AWSSecretsManager_ReadAccessOnly",
        "arn:aws:iam::718254829448:policy/New_Systems_Manager_Policy"
    ])
    policy_arn = each.value
}

resource "aws_iam_group_membership" "AdminAccessTeam" {
  name = "AdminAccessTeam"

  users = [
    data.aws_iam_user.current_user.user_name
  ]

  group = aws_iam_group.AdminAccessGroup.name
}

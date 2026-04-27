/*
Jenkins Plugins:
- GitHub plugin
- Pipeline As YAML (Incubated)
*/

pipeline {
    agent any
    triggers {
        pollSCM('H/5 * * * *')
    }
    environment {
        AWS_ACCESS_KEY_ID         = credentials('aws_access_key_id')
        AWS_SECRET_ACCESS_KEY     = credentials('aws_secret_access_key')
        AWS_DEFAULT_REGION        = 'us-east-1'
        TF_TOKEN_app_terraform_io = credentials('terraform-cloud-token')
        TF_VAR_cidr_ipv4_mac      = credentials('cidr_ipv4_mac')
        TF_VAR_project_version    = "${BUILD_ID}"
        DELETE_INFRASTRUCTURE     = 'true'
        ENABLE_VPN                = 'true'
    }
    stages {

        stage('Generate secrets.tf') {
            steps {
                sh '''
cat > Infrastructure/secrets.tf << EOF
variable "cidr_ipv4_mac" {
  type        = string
  description = "This is the Public IP for my Mac"
}
variable "project_version" {
  type        = string
  description = "This is the version control"
}
EOF
'''
            }
        }

        stage('Terraform VPN Enabled') {
            when {
                expression { return env.ENABLE_VPN == 'true' && env.DELETE_INFRASTRUCTURE == 'false' }
            }
            steps {
                sh 'cd Infrastructure && terraform init && terraform plan && terraform apply --auto-approve'
            }
        }

        stage('Terraform VPN Disabled') {
            when {
                expression { return env.ENABLE_VPN == 'false' && env.DELETE_INFRASTRUCTURE == 'false' }
            }
            steps {
                sh 'cd Infrastructure-NoVPN && terraform init && terraform plan && terraform apply --auto-approve'
            }
        }

        stage('Terraform Destroy VPN Enabled') {
            when {
                expression { return env.ENABLE_VPN == 'true' && env.DELETE_INFRASTRUCTURE == 'true' }
            }
            steps {
                sh 'cd Infrastructure && terraform init && terraform destroy --auto-approve'
            }
        }

        stage('Terraform Destroy VPN Disabled') {
            when {
                expression { return env.ENABLE_VPN == 'false' && env.DELETE_INFRASTRUCTURE == 'true' }
            }
            steps {
                sh 'cd Infrastructure-NoVPN && terraform init && terraform destroy --auto-approve'
            }
        }

    }
}
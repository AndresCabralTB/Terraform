/*
Jenkins Plugins 
- Github plugin
- Pipeline As YAML (Incubated)
*/

pipeline {
    agent any
    triggers{
        pollSCM('H/5 * * * *')
    }
    environment {
        AWS_ACCESS_KEY_ID         = credentials('aws_access_key_id')
        AWS_SECRET_ACCESS_KEY     = credentials('aws_secret_access_key')
        AWS_DEFAULT_REGION        = 'us-east-1'
        TF_TOKEN_app_terraform_io = credentials('terraform-cloud-token')
        TF_VAR_cidr_ipv4_mac      = credentials('cidr_ipv4_mac')
        Delete_infrastructure     = 'true'
        Enable_VPN                = 'true'
        PROJECT_VERSION           = "${BUILD_ID}"
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
    type = string 
    default = "${env.Project_version}"
    description = "This is the version control"
}
EOF
'''
            }
        }
        stage('Terraform VPN Enabled') {
            when {
                expression { return env.Enable_VPN == 'true' && env.Delete_infrastructure == 'false'}
            }
            steps {
                sh '''
                cd Infrastructure && terraform init
                terraform plan
                terraform apply --auto-approve
                '''

            }
        }
        stage('Terraform VPN Disabled') {
            when {
                expression { return env.Enable_VPN == 'false' && env.Delete_infrastructure == 'false'}
            }
            steps {
                sh '''
                cd Infrastructure-NoVPN && terraform init
                terraform plan
                terraform apply --auto-approve
                '''

            }
        }
        stage('Terraform Destroy VPN Enabled') {
            when {
                expression { return env.Enable_VPN == 'true' && return env.DELETE == 'true' }
            }
            steps {
                sh 'cd Infrastructure && terraform destroy --auto-approve'
            }
        }
        stage('Terraform Destroy VPN Disabled') {
            when {
                expression { return env.Enable_VPN == 'false' && return env.DELETE == 'true' }
            }
            steps {
                sh 'cd Infrastructure-NoVPN && terraform destroy --auto-approve'
            }
        }
    }
}
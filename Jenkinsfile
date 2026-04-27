pipeline {
    agent any
    environment {
        AWS_ACCESS_KEY_ID     = credentials('aws_access_key_id')
        AWS_SECRET_ACCESS_KEY = credentials('aws_secret_access_key')
        AWS_DEFAULT_REGION    = 'us-east-1'
        TF_TOKEN_app_terraform_io = credentials('terraform-cloud-token')
        TF_VAR_cidr_ipv4_mac = credentials('cidr_ipv4_mac')
    }
    stages {
        stage('Terraform Init') {
            steps {
                // Jenkins already checked out your repo here:
                sh 'cd Infrastructure && terraform init'
            }
        }
        stage('Terraform Plan') {
            steps {
                sh 'cd Infrastructure && terraform plan'
            }
        }
        stage('Terraform Apply') {
            steps {
                sh 'cd Infrastructure && terraforma apply -auto-approve'
            }
        }
    }
}
//Force new pipeline ${BUILD_ID} - New terraform token
pipeline {
    agent any
    environment {
        AWS_ACCESS_KEY_ID         = credentials('aws-access-key-id')
        AWS_SECRET_ACCESS_KEY     = credentials('aws-secret-access-key')
        AWS_DEFAULT_REGION        = 'us-east-1'
        TF_TOKEN_app_terraform_io = credentials('terraform-cloud-token')
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
                sh 'cd Infrastructure && terraform apply -auto-approve'
            }
        }
    }
}
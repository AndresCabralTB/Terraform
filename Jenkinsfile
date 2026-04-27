pipeline {
    agent any
    environment {
        AWS_ACCESS_KEY_ID     = credentials('aws_access_key_id')
        AWS_SECRET_ACCESS_KEY = credentials('aws_secret_access_key')
        AWS_DEFAULT_REGION    = 'us-east-1'
        TF_TOKEN_app_terraform_io = credentials('terraform-cloud-token')
    }
    stages {
        stage('Terraform Init') {
            steps {
                sh 'cd /app/Infrastructure && terraform init'
            }
        }
        stage('Terraform Directory') {
            steps {
                sh 'cd /app/Infrastructure'
            }
        }
        stage('Terraform Plan') {
            steps {
                sh 'terraform plan'
            }
        }
        stage('Terraform Apply') {
            steps {
                sh 'cd /app/Infrastructure && terraform apply -auto-approve'
            }
        }
        stage('Pipeline Version') {
            steps {
                sh 'echo "This is build version ${BUILD_ID}"'
            }
        }
    }
}
//Force new pipeline ${BUILD_ID} - New terraform token
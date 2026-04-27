pipeline {
    agent any
    environment {
        AWS_ACCESS_KEY_ID     = credentials('aws_access_key_id')
        AWS_SECRET_ACCESS_KEY = credentials('aws_secret_access_key')
        AWS_DEFAULT_REGION    = 'us-east-1'
    }
    stages {
        stage('Deploy Terraform Infrastructure') {
            steps {
                sh '''
                cd /app/Infrastructure/
                terraform init
                terraform apply -auto-approve
                '''
            }
        }
        stage('Pipeline Version') {
            steps {
                sh 'echo "This is build version ${BUILD_ID}"'
            }
        }
    }
}
//Force new pipeline ${BUILD_ID}
pipeline {
    agent any
    environment {
        AWS_ACCESS_KEY_ID     = credentials('aws-access-key-id')
        AWS_SECRET_ACCESS_KEY = credentials('aws-secret-access-key')
        AWS_DEFAULT_REGION    = 'us-east-1'
    }
    stages {
        stage('Checkout') {
            steps {
                git url: 'https://github.com/AndresCabralTB/Terraform.git',
                    credentialsId: 'github-credentials',
                    branch: 'main'
            }
        }
        stage('List S3 Files') {
            steps {
                sh 'aws s3 ls'
            }
        }
        stage('Pipeline Version') {
            steps {
                sh 'echo "This is build version ${BUILD_ID}"'
            }
        }
    }
}
//Force pipeline ${BUILD_ID}
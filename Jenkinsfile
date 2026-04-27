pipeline {
    agent any
    environment {
        AWS_ACCESS_KEY_ID     = credentials('aws_access_key_id')
        AWS_SECRET_ACCESS_KEY = credentials('aws_secret_access_key')
        AWS_DEFAULT_REGION    = 'us-east-1'
    }
    stages {
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
pipeline {
    agent any
    triggers{
        cron('H 8 * * *')
    }
    environment {
        AWS_ACCESS_KEY_ID         = credentials('aws_access_key_id')
        AWS_SECRET_ACCESS_KEY     = credentials('aws_secret_access_key')
        AWS_DEFAULT_REGION        = 'us-east-1'
        TF_TOKEN_app_terraform_io = credentials('terraform-cloud-token')
        TF_VAR_cidr_ipv4_mac      = credentials('cidr_ipv4_mac')
        DELETE                    = 'false'
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
EOF
'''
            }
        }

        stage('Terraform Init') {
            steps {
                sh 'cd Infrastructure && terraform init'
            }
        }

        stage('Terraform Plan') {
            when {
                expression { return env.DELETE == 'false' }
            }
            steps {
                sh 'cd Infrastructure && terraform plan'
            }
        }

        stage('Terraform Apply') {
            when {
                expression { return env.DELETE == 'false' }
            }
            steps {
                sh 'cd Infrastructure && terraform apply --auto-approve'
            }
        }

        stage('Terraform Destroy') {
            when {
                expression { return env.DELETE == 'true' }
            }
            steps {
                sh 'cd Infrastructure && terraform destroy --auto-approve'
            }
        }
    }
}
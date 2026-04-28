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
        TF_TOKEN_app_terraform_io = credentials('terraform-cloud-token')
        TF_VAR_cidr_ipv4_mac      = credentials('cidr_ipv4_mac')
        TF_VAR_project_version    = "${BUILD_ID}"
    }
    stages {

        stage('Load Configuration Values') {
            script{
                def config = readYaml file: 'config.yaml'
                env.ENABLE_VPN = config.ENABLE_VPN
                env.DELETE_INFRASTRUCTURE = config.DELETE_INFRASTRUCTURE
            }
        }

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
                //Create .ovpn file for users
                sh '''
                aws ec2 export-client-vpn-client-configuration \
                    --client-vpn-endpoint-id $(aws ec2 describe-client-vpn-endpoints \
                        --query 'ClientVpnEndpoints[0].ClientVpnEndpointId' \
                        --output text) \
                    --output text > downloaded.ovpn
                '''
                sh 'cd Infrastructure/VPN-CONF/ && ./generate_ovpn.sh alice Infrastructure/downloaded.ovpn'
                sh 'aws s3 cp Infrastructure/VPN-CONF/alice.ovpn s3://cloud-cabral-ovpn-files/vpn-configs/alice.ovpn'
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
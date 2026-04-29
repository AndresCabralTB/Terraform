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
            steps{
                script{
                    def config = readYaml file: 'config.yaml'
                    env.ENABLE_VPN = config.ENABLE_VPN
                    env.DELETE_INFRASTRUCTURE = config.DELETE_INFRASTRUCTURE
                    env.AWS_DEFAULT_REGION = config.AWS_DEFAULT_REGION
                    env.HOME_DIR = "Infrastructures/Infrastructure-VPN"
                    env.TF_VAR_enable_vpn = config.ENABLE_VPN
                }
            }
        }

        stage('Generate secrets.tf') {
            steps {
                sh """
cat > "${env.HOME_DIR}"/secrets.tf << 'EOF'
variable "cidr_ipv4_mac" {
  type        = string
  description = "This is the Public IP for my Mac"
}
variable "project_version" {
  type        = string
  description = "This is the version control"
}

variable "enable_vpn" {
  type = string
  default = "false"
}
EOF
"""
            }
        }

        stage('Terraform Init') {
            steps {
                sh "cd $env.HOME_DIR && terraform init && terraform apply --auto-approve"
            }
        }
        stage('Terraform Apply') {
            when {
                expression { return env.DELETE_INFRASTRUCTURE == "false" }
            }
            steps {
                sh "cd $env.HOME_DIR && terraform apply --auto-approve"
            }
        }
        stage('OVPN File Configuration') {
            when {
                expression { return env.ENABLE_VPN == 'true' && env.DELETE_INFRASTRUCTURE == 'false' }
            }
            steps{
                //Create .ovpn file for users
                sh """ 
                cd "${env.HOME_DIR}/Client-VPN-Conf/" 

                ENDPOINT_ID=\$(aws ec2 describe-client-vpn-endpoints \
                    --query 'ClientVpnEndpoints[0].ClientVpnEndpointId' \
                    --output text)

                aws ec2 export-client-vpn-client-configuration \
                    --client-vpn-endpoint-id \$ENDPOINT_ID \
                    --output text > downloaded.ovpn
                """
                sh "echo Current directory passed to ./generate_ovpn.sh - $env.WORKSPACE/$env.HOME_DIR/"
                sh "cd $env.HOME_DIR/Client-VPN-Conf/ && ./generate_ovpn.sh alice downloaded.ovpn $env.WORKSPACE/$env.HOME_DIR"
                sh "aws s3 cp $env.HOME_DIR/Client-VPN-Conf/alice.ovpn s3://cloud-cabral-ovpn-files/vpn-configs/alice.ovpn"
            }
        }

        stage('Destroy OVPN Files') {
            when {
                expression { return env.ENABLE_VPN == 'true' && env.DELETE_INFRASTRUCTURE == 'true' }
            }
            steps {
                sh "cd $env.HOME_DIR/Client-VPN-Conf/ && rm -rf *.ovpn"
            }
        }

        stage('Terraform Destroy') {
            when {
                expression { return env.DELETE_INFRASTRUCTURE == "true" }
            }
            steps {
                sh "cd $env.HOME_DIR && terraform init && terraform destroy --auto-approve"
            }
        }

    }
    post {
        success {
            echo 'Pipeline completed successfully'
        }
        unsuccessful {
            script {
                if(env.DELETE_INFRASTRUCTURE == "true"){
                    sh "cd $env.HOME_DIR && terraform init && terraform destroy --auto-approve"
                } else {
                    echo "Pipeline failed - Skipping destroy"
                }
                
            }
        }
        changed {
            echo 'Environment changed'
        }
    }
}
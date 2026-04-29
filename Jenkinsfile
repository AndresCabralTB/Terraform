/*
Jenkins Plugins:
- GitHub plugin
- Pipeline As YAML (Incubated)
*/

def createSecretsTF() {
    if(env.DELETE_INFRASTRUCTURE == "false"){
        def home_dir = env.HOME_DIR
        sh """
cat > ${home_dir}/secrets.tf << 'EOF'
variable "cidr_ipv4_mac" {
    type        = string
    description = "This is the Public IP for my Mac"
}

variable "project_version" {
    type        = string
    description = "This is the version control"
}
EOF
"""
    } else {
        sh 'echo Skipping secrets.tf creation as infrastructure is marked for deletion'
    }
}

def planTerraform(){
    if(env.DELETE_INFRASTRUCTURE=="false"){
        sh "cd $env.HOME_DIR && terraform init && terraform plan && terraform apply --auto-approve"
    } else {
        sh 'echo Skipping Terraform plan and apply as infrastructure is marked for deletion'
    }
}

def configureOVPNFiles(){
    if(env.DELETE_INFRASTRUCTURE == "false"){
        if(env.ENABLE_VPN == "true"){
    sh 'pwd'
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
    sh "cd $env.HOME_DIR/Client-VPN-Conf/ && ./generate_ovpn.sh alice downloaded.ovpn"
    sh "aws s3 cp $env.HOME_DIR/Client-VPN-Conf/alice.ovpn s3://cloud-cabral-ovpn-files/vpn-configs/alice.ovpn"
    } else{
    sh 'echo VPN is disabled - Skipping OVPN Configuration'
    }
    } else{
    sh 'echo Skipping OVPN configuration as infrastructure is marked for deletion'
    }
}

def destroyInfrastructure() {
    if (env.ENABLE_VPN == 'true') {
        sh "cd $env.HOME_DIR/Client-VPN-Conf/ && rm -rf *.ovpn"
    }
    sh "cd $env.HOME_DIR && terraform init && terraform destroy --auto-approve"
}

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
                    env.HOME_DIR = (env.ENABLE_VPN == "true")
                        ? "Infrastructures/Infrastructure-VPN"
                        : "Infrastructures/Infrastructure-NoVPN"
                }
            }
        }
        stage('Generate secrets.tf') {
            steps { createSecretsTF() }
        }

        stage('Terraform Plan') {
            steps { planTerraform() }
        }
        stage('OVPN File Configuration') {
            steps{ configureOVPNFiles() }
        }

        stage('Terraform Destroy') {
            steps { destroyInfrastructure()}
        }
    }
    post {
        success {
            echo 'Pipeline completed successfully'
        }
        unsuccessful {
            script { 
                if (env.DELETE_INFRASTRUCTURE == 'true') {
                    destroyInfrastructure()
                } else {
                    echo 'Pipeline failed but DELETE_INFRASTRUCTURE is false — skipping auto-destroy.'
                }
             }
        }
        changed {
            echo 'Environment changed'
        }
    }
}
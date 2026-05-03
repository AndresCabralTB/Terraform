/*
Jenkins Plugins:
- GitHub plugin
- Pipeline As YAML (Incubated)
*/

// We set up a webhook to our repository so that when we push our code, Jenkins Git Plugin detects the push and begins the pipeline using the repository 
// This trigger only kicks git-plugin internal polling algo for every incoming event against matched repo.
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
        NGROK_TOKEN               = credentials('ngrok-token')
    }
    stages {
        stage('Load Configuration Values') {
            steps{
                script{
                    def config = readYaml file: 'config.yaml'
                    env.ENABLE_VPN = config.ENABLE_VPN
                    env.DELETE_INFRASTRUCTURE = config.DELETE_INFRASTRUCTURE
                    env.AWS_DEFAULT_REGION = config.AWS_DEFAULT_REGION
                    env.HOME_DIR = "Infrastructure"
                    env.TF_VAR_enable_vpn = config.ENABLE_VPN
                    env.ONLY_A_GIT_UPDATE = config.ONLY_A_GIT_UPDATE
                }
            }
        }

        stage('Update Code Only'){
            when {
                expression { return env.ONLY_A_GIT_UPDATE == 'true' && env.ENABLE_VPN == 'false' && env.DELETE_INFRASTRUCTURE == 'false'}
            }
            steps{
                sh "echo This is only an update to git main - no changes were made to the Infrastructure"
            
            }
        }
        
        stage('Terraform Init') {
            when {
                expression { return env.ONLY_A_GIT_UPDATE == 'false' }
            }
            steps {
                sh "cd $env.HOME_DIR && terraform init && terraform plan "
            }
        }

        stage('Terraform Init') {
            when {
                expression { return env.ONLY_A_GIT_UPDATE == 'false' }
            }
            steps {
                sh "cd $env.HOME_DIR && terraform plan "
            }
        }

        stage('Terraform Apply') {
            when {
                branch 'main'
                expression { return env.DELETE_INFRASTRUCTURE == "false" && env.ONLY_A_GIT_UPDATE == 'false' }
            }
            steps {
                sh "cd $env.HOME_DIR && terraform apply --auto-approve"
            }
        }
        stage('OVPN File Configuration') {
            when {
                expression { return env.ENABLE_VPN == 'true' && env.DELETE_INFRASTRUCTURE == 'false' && env.ONLY_A_GIT_UPDATE == 'false' }
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
                expression { return env.ENABLE_VPN == 'true' && env.DELETE_INFRASTRUCTURE == 'true' && env.ONLY_A_GIT_UPDATE == 'false' }
            }
            steps {
                sh "cd $env.HOME_DIR/Client-VPN-Conf/ && rm -rf *.ovpn"
            }
        }

        stage('Terraform Destroy') {
            when {
                expression { return env.DELETE_INFRASTRUCTURE == "true" && env.ONLY_A_GIT_UPDATE == 'false' }
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
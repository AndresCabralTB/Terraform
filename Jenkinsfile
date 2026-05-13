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
        //Tokens are in .env, but they need to be configured in JENKINS UI
        AWS_ACCESS_KEY_ID         = credentials('AWS_ACCESS_KEY_ID')
        AWS_SECRET_ACCESS_KEY     = credentials('AWS_SECRET_ACCESS_KEY')
        TF_TOKEN_app_terraform_io = credentials('TERRAFORM_CLOUD_TOKEN')
        TF_VAR_cidr_ipv4_mac      = credentials('cidr_ipv4_mac')
        TF_VAR_project_version    = "${BUILD_ID}-prod"
        NGROK_TOKEN               = credentials('NGROK_TOKEN')
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
                    env.TF_VAR_project_region = config.AWS_DEFAULT_REGION
                    env.DEPLOY_RESOURCES = config.DEPLOY_RESOURCES
                    
                }
            }
        }

        stage('Update Code Only'){
            when {
                expression { return env.DEPLOY_RESOURCES == 'false' && env.DELETE_INFRASTRUCTURE == 'false'}
            }
            steps{
                sh "echo This is only an update to git branch - no changes were made to the Infrastructure"
            }
        }
        
        stage('Terraform Init') {
            steps {
                sh "cd $env.HOME_DIR && terraform init && terraform plan "
            }
        }

        stage('Terraform Plan') {
            steps {
                sh "cd $env.HOME_DIR && terraform plan "
            }
        }

        stage('Terraform Apply') {
            when {
                allOf{
                    branch 'main'
                    expression { return env.DEPLOY_RESOURCES == 'true' && env.DELETE_INFRASTRUCTURE == "false" }
                }
            }
            steps {
                sh "cd $env.HOME_DIR && terraform apply --auto-approve"
            }
        }
        stage('OVPN File Configuration') {
            when {
                allOf{
                    branch 'main'
                    expression { return env.DEPLOY_RESOURCES == 'true' && env.ENABLE_VPN == 'true' && env.DELETE_INFRASTRUCTURE == 'false' }
                }
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
                //sh "cd $env.HOME_DIR/Client-VPN-Conf/ && ./generate_ovpn.sh alice downloaded.ovpn $env.WORKSPACE/$env.HOME_DIR"
                //sh "aws s3 cp $env.HOME_DIR/Client-VPN-Conf/alice.ovpn s3://cloud-cabral-ovpn-files/vpn-configs/alice.ovpn"
            }
        }

        stage('Destroy OVPN Files') {
            when {
                allOf{
                    branch 'main'
                    expression { return env.ENABLE_VPN == 'true' && env.DELETE_INFRASTRUCTURE == 'true' }
                }
            }
            steps {
                sh "cd $env.HOME_DIR/Client-VPN-Conf/ && rm -rf *.ovpn"
            }
        }

        stage('Terraform Destroy') {
            when {
                allOf{
                    branch 'main'
                    expression { return env.DELETE_INFRASTRUCTURE == "true"}
                }
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
                if(env.DELETE_INFRASTRUCTURE == "false"){
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
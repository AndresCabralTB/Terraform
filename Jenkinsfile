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
        HOME_DIR = "Infrastructure"
        AWS_ACCESS_KEY_ID         = credentials('AWS_ACCESS_KEY_ID')
        AWS_SECRET_ACCESS_KEY     = credentials('AWS_SECRET_ACCESS_KEY')
        NGROK_TOKEN               = credentials('NGROK_TOKEN')
        TF_VAR_project_version    = "${BUILD_ID}-prod"
        TF_VAR_workspace          = "${WORKSPACE}"

    }
    stages {
        stage('Terraform Init') {
            steps {
                sh """
                    cd ${env.HOME_DIR}
                    terraform init
                    terraform workspace select ${env.BRANCH_NAME} || terraform workspace new ${env.BRANCH_NAME}
                """
            }
        }

        stage('Terraform Plan') {
            steps {
                sh "cd ${env.HOME_DIR} && terraform plan -var-file=envs/${env.BRANCH_NAME}.tfvars"
            }
        }

        stage('Terraform Apply') {
            when {
                anyOf {
                    branch 'main'
                }
            }
            steps {
                sh "cd ${env.HOME_DIR} && terraform apply -var-file=envs/${env.BRANCH_NAME}.tfvars --auto-approve"
            }
        }
        stage('OVPN File Configuration') {
            when {
                allOf{
                    branch 'main'
<<<<<<< Updated upstream
                    expression { return env.DEPLOY_RESOURCES == 'true' && env.ENABLE_VPN == 'true' && env.DELETE_INFRASTRUCTURE == 'false' }
=======
                    expression{
                        //read tfvars to check if VPN is enabled
                        def tfvars = readFile("${env.HOME_DIR}/envs/main.tfvars")
                        return tfvars.contains('enable_vpn = true')
                    }
>>>>>>> Stashed changes
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
                    branch 'destroy'
                    expression{
                        //read tfvars to check if VPN is enabled
                        def tfvars = readFile("${env.HOME_DIR}/envs/main.tfvars")
                        return tfvars.contains('enable_vpn = true')
                    }
                }
            }
            steps {
                sh """
                    cd ${env.HOME_DIR}/Client-VPN-Conf/
                    rm -rf *.ovpn
                """
            }
        }

        stage('Terraform Destroy') {
            when {
                allOf{
                    branch 'destroy'
                }
            }
            steps {
                sh """
                    cd ${env.HOME_DIR}
                    terraform workspace select main
                    terraform destroy -var-file=envs/main.tfvars --auto-approve
                """
            }
        }
    }
    post {
        success {
            echo 'Pipeline completed successfully'
        }
        unsuccessful {
            script {
<<<<<<< Updated upstream
                if(env.DELETE_INFRASTRUCTURE == "true"){
                    sh "cd $env.HOME_DIR && terraform init && terraform destroy --auto-approve"
=======
                if (env.BRANCH_NAME == 'main') {
                    sh "cd ${env.HOME_DIR} && terraform destroy --auto-approve -var-file=envs/main.tfvars"
>>>>>>> Stashed changes
                } else {
                    echo "Pipeline failed on ${env.BRANCH_NAME} - skipping destroy"
                }
            }
        }
        changed {
            echo 'Environment changed'
        }
    }
}
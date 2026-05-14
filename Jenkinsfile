/*
Jenkins Plugins:
- GitHub plugin
- Pipeline As YAML (Incubated)
*/

// We set up a webhook to our repository so that when we push our code, Jenkins Git Plugin detects the push and begins the pipeline using the repository 
// This trigger only kicks git-plugin internal polling algo for every incoming event against matched repo.
pipeline {
    agent any
    parameters {
        booleanParam(
            name: 'RUN_DESTROY',
            defaultValue: true,
            description: 'Check this only when you want to destroy infrastructure.'
        )
    }
    environment {
        //Tokens are in .env, but they need to be configured in JENKINS UI
        HOME_DIR = "Infrastructure"
        AWS_ACCESS_KEY_ID         = credentials('AWS_ACCESS_KEY_ID')
        AWS_SECRET_ACCESS_KEY     = credentials('AWS_SECRET_ACCESS_KEY')
        NGROK_TOKEN               = credentials('NGROK_TOKEN')
        TF_VAR_workspace          = "${WORKSPACE}"
        TF_VAR_project_region     = "us-east-1"
    }
    stages {
        
        stage( 'Resolve Environment') {
            steps{
                script {

                    def branchEnvMap = [
                        'main': 'prod',
                        'devl': 'devl',
                        'test': 'test',
                        'trng': 'trng'
                    ]

                    env.DEPLOY_ENV = branchEnvMap[env.BRANCH_NAME] ?: 'unknown'
                    env.PIPELINE_MODE = params.RUN_DESTROY ? 'destroy' : 'deploy'

                    echo "Branch: ${env.BRANCH_NAME}"
                    echo "Deploy environment: ${env.DEPLOY_ENV}"
                    echo "Pipeline mode: ${env.PIPELINE_MODE}"

                    if (env.DEPLOY_ENV == 'unknown') {
                        error "Branch ${env.BRANCH_NAME} is not mapped to a deployable environment."
                    }

                    echo "Branch: ${env.BRANCH_NAME}"
                    echo "Deploy environment: ${env.DEPLOY_ENV}"
                }
            }
        }

        stage('Terraform Init') {
            steps {
                sh """
                    cd ${env.HOME_DIR}
                    chmod -R +rx *
                    terraform init
                    terraform workspace select ${env.DEPLOY_ENV} || terraform workspace new ${env.DEPLOY_ENV}
                """
            }
        }

        stage('Terraform Plan') {
            when {
                expression {
                    env.PIPELINE_MODE == 'deploy'
                }
            }
            steps {
                sh """
                    cd ${env.HOME_DIR}
                    terraform plan -var-file=envs/${env.DEPLOY_ENV}.tfvars
                """
            }
        }

        stage('Terraform Apply') {
            when {
                expression {
                    env.PIPELINE_MODE == 'deploy'
                }
            }
            steps {
                sh """
                    cd ${env.HOME_DIR}
                    terraform apply -var-file=envs/${env.DEPLOY_ENV}.tfvars --auto-approve
                """
            }
        }

        stage('OVPN File Configuration') {
            when {
                allOf {
                    expression { env.PIPELINE_MODE == 'deploy' }
                    expression{
                        //read tfvars to check if VPN is enabled
                        def tfvars = readFile("${env.HOME_DIR}/envs/${env.DEPLOY_ENV}.tfvars")
                        return tfvars.contains('enable_vpn = true')
                    }
                }
            }
            steps{
                //Create .ovpn file for users
                sh """ 
                cd "${env.HOME_DIR}/Client-VPN-Conf/" 

                ENDPOINT_ID=\$(aws ec2 describe-client-vpn-endpoints \
                    --region "${env.TF_VAR_project_region}" \
                    --query 'ClientVpnEndpoints[0].ClientVpnEndpointId' \
                    --output text)

                aws ec2 export-client-vpn-client-configuration \
                    --region "${env.TF_VAR_project_region}" \
                    --client-vpn-endpoint-id \$ENDPOINT_ID \
                    --output text > downloaded.ovpn
                """
                sh "cd $env.HOME_DIR/Client-VPN-Conf/ && ./generate_ovpn.sh andres downloaded.ovpn ${env.WORKSPACE}/${env.HOME_DIR}"
                sh "aws s3 cp $env.HOME_DIR/Client-VPN-Conf/andres.ovpn s3://cloud-cabral-ovpn-files/vpn-configs/andres.ovpn"
            }
        }

        stage('Terraform Destroy Plan') {
            when {
                anyOf{
                    expression {
                        env.PIPELINE_MODE == 'destroy'
                    }
                }
            }
            steps {
                sh """
                    cd ${env.HOME_DIR}
                    terraform workspace select ${env.DEPLOY_ENV}

                    terraform plan \
                        -destroy \
                        -var-file=envs/${env.DEPLOY_ENV}.tfvars \
                        -out=destroy.tfplan

                    terraform apply -auto-approve destroy.tfplan
                """
            }                          
        }
    }
    post {
        success {
            echo "Pipeline ${env.DEPLOY_ENV} completed successfully"
        }
        unsuccessful {
            echo "Pipeline failed on ${env.DEPLOY_ENV} - skipping automatic destroy"
        }
        changed {
            echo 'Environment changed'
        }
    }
}
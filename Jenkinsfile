/*
Jenkins Plugins:
- GitHub plugin
- Pipeline As YAML (Incubated)
*/

// We set up a webhook to our repository so that when we push our code, Jenkins Git Plugin detects the push and begins the pipeline using the repository 
// This trigger only kicks git-plugin internal polling algo for every incoming event against matched repo.
pipeline {
    agent any
    //triggers {
        //pollSCM('H/5 * * * *')
    //}
    environment {
        //Tokens are in .env, but they need to be configured in JENKINS UI
        HOME_DIR = "Infrastructure"
        AWS_ACCESS_KEY_ID         = credentials('AWS_ACCESS_KEY_ID')
        AWS_SECRET_ACCESS_KEY     = credentials('AWS_SECRET_ACCESS_KEY')
        NGROK_TOKEN               = credentials('NGROK_TOKEN')
        TF_VAR_project_version    = "prod"
        TF_VAR_workspace          = "${WORKSPACE}"
        TF_VAR_project_region     = "us-east-1"
    }
    stages {
        stage('Terraform Init') {
            steps {
                sh """
                    cd ${env.HOME_DIR}
                    chmod -R +rx *
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
                    expression{
                        //read tfvars to check if VPN is enabled
                        def tfvars = readFile("${env.HOME_DIR}/envs/main.tfvars")
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

        stage('Terraform Destroy') {
    when {
        allOf {
            branch 'destroy'
        }
    }
    steps {
        sh """
            cd ${env.HOME_DIR}
            terraform workspace select main

            echo "Fetching Client VPN Endpoint ID from Terraform state..."
            ENDPOINT_ID=\$(terraform output -raw ClientVPN_Endpoint_Output 2>&1)

            if [ \$? -ne 0 ]; then
                echo "ERROR: Failed to get ClientVPN_Endpoint_Output from Terraform state"
                echo "Output was: \$ENDPOINT_ID"
                exit 1
            fi

            if [ -z "\$ENDPOINT_ID" ] || [ "\$ENDPOINT_ID" = "null" ] || [ "\$ENDPOINT_ID" = "None" ]; then
                echo "WARNING: No Client VPN Endpoint found in state, skipping deletion..."
            else
                echo "Found Client VPN Endpoint: \$ENDPOINT_ID"
                echo "Disassociating network associations first..."
                aws ec2 describe-client-vpn-target-networks \
                    --client-vpn-endpoint-id \$ENDPOINT_ID \
                    --query 'ClientVpnTargetNetworks[*].AssociationId' \
                    --output text | tr '\\t' '\\n' | while read ASSOC_ID; do
                        if [ -n "\$ASSOC_ID" ]; then
                            echo "Disassociating: \$ASSOC_ID"
                            aws ec2 disassociate-client-vpn-target-network \
                                --client-vpn-endpoint-id \$ENDPOINT_ID \
                                --association-id \$ASSOC_ID
                        fi
                done

                echo "Waiting for disassociations to complete..."
                sleep 60

                echo "Deleting Client VPN Endpoint: \$ENDPOINT_ID"
                aws ec2 delete-client-vpn-endpoint --client-vpn-endpoint-id \$ENDPOINT_ID

                echo "Waiting for endpoint deletion..."
                sleep 30
            fi

            echo "Running Terraform destroy..."
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
                if (env.BRANCH_NAME == 'main') {
                    sh """
                        cd ${env.HOME_DIR}
                        terraform workspace select main

                        echo "Fetching Client VPN Endpoint ID from Terraform state..."
                        ENDPOINT_ID=\$(terraform output -raw ClientVPN_Endpoint_Output 2>&1)

                        if [ \$? -ne 0 ]; then
                            echo "ERROR: Failed to get ClientVPN_Endpoint_Output from Terraform state"
                            echo "Output was: \$ENDPOINT_ID"
                            exit 1
                        fi

                        if [ -z "\$ENDPOINT_ID" ] || [ "\$ENDPOINT_ID" = "null" ] || [ "\$ENDPOINT_ID" = "None" ]; then
                            echo "WARNING: No Client VPN Endpoint found in state, skipping deletion..."
                        else
                            echo "Found Client VPN Endpoint: \$ENDPOINT_ID"
                            echo "Disassociating network associations first..."
                            aws ec2 describe-client-vpn-target-networks \
                                --client-vpn-endpoint-id \$ENDPOINT_ID \
                                --query 'ClientVpnTargetNetworks[*].AssociationId' \
                                --output text | tr '\\t' '\\n' | while read ASSOC_ID; do
                                    if [ -n "\$ASSOC_ID" ]; then
                                        echo "Disassociating: \$ASSOC_ID"
                                        aws ec2 disassociate-client-vpn-target-network \
                                            --client-vpn-endpoint-id \$ENDPOINT_ID \
                                            --association-id \$ASSOC_ID
                                    fi
                            done

                            echo "Waiting for disassociations to complete..."
                            sleep 60

                            echo "Deleting Client VPN Endpoint: \$ENDPOINT_ID"
                            aws ec2 delete-client-vpn-endpoint --client-vpn-endpoint-id \$ENDPOINT_ID

                            echo "Waiting for endpoint deletion..."
                            sleep 30
                        fi

                        echo "Running Terraform destroy..."
                        terraform destroy -var-file=envs/main.tfvars --auto-approve
                    """
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
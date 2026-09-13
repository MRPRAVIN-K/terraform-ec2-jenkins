pipeline {

    agent {
        label 'dynamic-agent'
    }

    options {
        disableConcurrentBuilds()
        timestamps()
        skipDefaultCheckout(false)
    }

    parameters {
        choice(
            name: 'ACTION',
            choices: ['BUILD', 'DESTROY'],
            description: 'BUILD = create/build resources. DESTROY = create/verify resources and then destroy them.'
        )
    }

    environment {
        AWS_DEFAULT_REGION = 'us-east-1'
        AWS_REGION         = 'us-east-1'

        TF_IN_AUTOMATION = 'true'

        DOCKER_IMAGE_NAME = 'dynamic-ec2-app'
        DOCKER_IMAGE_TAG  = 'latest'

        AGENT_AMI_ID = 'ami-0d305d10799df0056'
    }

    stages {

        // ============================================================
        // CHECK AGENT
        // ============================================================

        stage('Check Agent') {
            steps {

                echo 'Running pipeline on Jenkins dynamic EC2 agent'

                sh '''
                    set -e

                    echo "======================================"
                    echo "CHECK DYNAMIC AGENT"
                    echo "======================================"

                    echo ""
                    echo "Hostname:"
                    hostname

                    echo ""
                    echo "Current User:"
                    whoami

                    echo ""
                    echo "Working Directory:"
                    pwd

                    echo ""
                    echo "Agent AMI configured in Jenkins:"
                    echo "${AGENT_AMI_ID}"

                    echo ""
                    echo "Java:"
                    java -version

                    echo ""
                    echo "Disk:"
                    df -h /

                    echo ""
                    echo "Memory:"
                    free -h

                    echo ""
                    echo "======================================"
                    echo "AGENT CHECK COMPLETED"
                    echo "======================================"
                '''
            }
        }


        // ============================================================
        // VERIFY TOOLS
        // No installation here because verify-tools AMI already
        // contains all required tools.
        // ============================================================

        stage('Verify Tools') {
            steps {

                sh '''
                    set -e

                    echo "======================================"
                    echo "VERIFY REQUIRED TOOLS"
                    echo "======================================"

                    echo ""
                    echo "===== JAVA ====="
                    java -version

                    echo ""
                    echo "===== GIT ====="
                    git --version

                    echo ""
                    echo "===== TERRAFORM ====="
                    terraform version

                    echo ""
                    echo "===== AWS CLI ====="
                    aws --version

                    echo ""
                    echo "===== DOCKER ====="
                    docker --version

                    echo ""
                    echo "===== DOCKER SERVICE ====="
                    sudo systemctl is-active docker

                    echo ""
                    echo "===== ANSIBLE ====="
                    ansible --version | head -n 1

                    echo ""
                    echo "===== CURL ====="
                    curl --version | head -n 1

                    echo ""
                    echo "===== UNZIP ====="
                    unzip -v | head -n 1

                    echo ""
                    echo "======================================"
                    echo "ALL REQUIRED TOOLS ARE AVAILABLE"
                    echo "======================================"
                '''
            }
        }


        // ============================================================
        // AWS IDENTITY
        // ============================================================

        stage('Check AWS Identity') {
            steps {

                sh '''
                    set -e

                    echo "======================================"
                    echo "AWS IDENTITY"
                    echo "======================================"

                    echo ""
                    echo "AWS CLI:"
                    aws --version

                    echo ""
                    echo "AWS Region:"
                    echo "${AWS_DEFAULT_REGION}"

                    echo ""
                    echo "AWS Caller Identity:"
                    aws sts get-caller-identity

                    echo ""
                    echo "======================================"
                    echo "AWS AUTHENTICATION SUCCESSFUL"
                    echo "======================================"
                '''
            }
        }


        // ============================================================
        // DEBUG TERRAFORM STATE
        // ============================================================

        stage('Debug Terraform State') {
            steps {

                dir('terraform') {

                    sh '''
                        set -e

                        echo "======================================"
                        echo "DEBUG TERRAFORM STATE"
                        echo "======================================"

                        echo ""
                        echo "Hostname:"
                        hostname

                        echo ""
                        echo "Terraform Version:"
                        terraform version

                        echo ""
                        echo "Terraform Workspace:"
                        terraform workspace show

                        echo ""
                        echo "Terraform Directory:"
                        pwd

                        echo ""
                        echo "Terraform Files:"
                        ls -lah

                        echo ""
                        echo "Terraform State File:"
                        if [ -f terraform.tfstate ]; then
                            ls -lh terraform.tfstate
                        else
                            echo "terraform.tfstate NOT FOUND"
                        fi

                        echo ""
                        echo "Terraform State List:"
                        if [ -f terraform.tfstate ]; then
                            terraform state list || true
                        else
                            echo "No local Terraform state available."
                        fi

                        echo ""
                        echo "======================================"
                        echo "TERRAFORM STATE DEBUG COMPLETED"
                        echo "======================================"
                    '''
                }
            }
        }


        // ============================================================
        // TERRAFORM INIT
        // ============================================================

        stage('Terraform Init') {
            steps {

                dir('terraform') {

                    sh '''
                        set -e

                        echo "======================================"
                        echo "TERRAFORM INIT"
                        echo "======================================"

                        terraform init -input=false

                        echo ""
                        echo "Terraform init completed successfully."

                        echo "======================================"
                        echo "TERRAFORM INIT COMPLETED"
                        echo "======================================"
                    '''
                }
            }
        }


        // ============================================================
        // TERRAFORM VALIDATE
        // ============================================================

        stage('Terraform Validate') {
            steps {

                dir('terraform') {

                    sh '''
                        set -e

                        echo "======================================"
                        echo "TERRAFORM VALIDATE"
                        echo "======================================"

                        terraform validate

                        echo ""
                        echo "Terraform configuration is valid."

                        echo "======================================"
                        echo "TERRAFORM VALIDATE SUCCESSFUL"
                        echo "======================================"
                    '''
                }
            }
        }


        // ============================================================
        // TERRAFORM PLAN
        // ============================================================

        stage('Terraform Plan') {
            steps {

                dir('terraform') {

                    sh '''
                        set -e

                        echo "======================================"
                        echo "TERRAFORM PLAN"
                        echo "======================================"

                        terraform plan -input=false

                        echo ""
                        echo "Terraform plan completed successfully."

                        echo "======================================"
                        echo "TERRAFORM PLAN COMPLETED"
                        echo "======================================"
                    '''
                }
            }
        }


        // ============================================================
        // TERRAFORM APPLY
        // ============================================================

        stage('Build Infrastructure') {
            when {
                expression {
                    params.ACTION == 'BUILD' || params.ACTION == 'DESTROY'
                }
            }

            steps {

                dir('terraform') {

                    sh '''
                        set -e

                        echo "======================================"
                        echo "BUILD INFRASTRUCTURE"
                        echo "======================================"

                        terraform apply \
                            -input=false \
                            -auto-approve

                        echo ""
                        echo "Terraform Outputs:"
                        terraform output

                        echo ""
                        echo "======================================"
                        echo "TERRAFORM APPLY COMPLETED"
                        echo "======================================"
                    '''
                }
            }
        }


        // ============================================================
        // GET ECR REPOSITORY
        // ============================================================

        stage('Get ECR Repository') {
            steps {

                script {

                    env.ECR_REPO = sh(
                        script: '''
                            cd terraform
                            terraform output -raw ecr_repository_url
                        ''',
                        returnStdout: true
                    ).trim()

                    echo "======================================"
                    echo "ECR REPOSITORY"
                    echo "======================================"

                    echo "ECR Repository:"
                    echo "${env.ECR_REPO}"

                    if (!env.ECR_REPO?.trim()) {
                        error("ECR repository URL is empty")
                    }
                }
            }
        }


        // ============================================================
        // GET EC2 PUBLIC IP
        // ============================================================

        stage('Get EC2 IP') {
            steps {

                script {

                    env.EC2_PUBLIC_IP = sh(
                        script: '''
                            cd terraform
                            terraform output -raw public_ip
                        ''',
                        returnStdout: true
                    ).trim()

                    echo "======================================"
                    echo "EC2 PUBLIC IP"
                    echo "======================================"

                    echo "EC2 Public IP:"
                    echo "${env.EC2_PUBLIC_IP}"

                    if (!env.EC2_PUBLIC_IP?.trim()) {
                        error("EC2 public IP is empty")
                    }
                }
            }
        }


        // ============================================================
        // DOCKER BUILD
        // ============================================================

        stage('Docker Build') {
            steps {

                sh '''
                    set -e

                    echo "======================================"
                    echo "DOCKER BUILD"
                    echo "======================================"

                    echo ""
                    echo "Docker Version:"
                    sudo docker --version

                    echo ""
                    echo "Docker Service:"
                    sudo systemctl is-active docker

                    echo ""
                    echo "Dockerfile:"
                    ls -l Dockerfile

                    echo ""
                    echo "Building Docker Image:"
                    echo "${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}"

                    sudo docker build \
                        -t "${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}" \
                        .

                    echo ""
                    echo "Docker images:"
                    sudo docker images

                    echo ""
                    echo "======================================"
                    echo "DOCKER BUILD COMPLETED"
                    echo "======================================"
                '''
            }
        }


        // ============================================================
        // ECR LOGIN
        // ============================================================

        stage('ECR Login') {
            steps {

                sh '''
                    set -e

                    echo "======================================"
                    echo "ECR LOGIN"
                    echo "======================================"

                    ECR_REGISTRY="${ECR_REPO%%/*}"

                    echo ""
                    echo "ECR Registry:"
                    echo "${ECR_REGISTRY}"

                    echo ""
                    echo "AWS Account:"
                    aws sts get-caller-identity \
                        --query Account \
                        --output text

                    echo ""
                    echo "Logging in to ECR..."

                    aws ecr get-login-password \
                        --region "${AWS_DEFAULT_REGION}" |
                    sudo docker login \
                        --username AWS \
                        --password-stdin "${ECR_REGISTRY}"

                    echo ""
                    echo "======================================"
                    echo "ECR LOGIN SUCCESSFUL"
                    echo "======================================"
                '''
            }
        }


        // ============================================================
        // DOCKER TAG
        // ============================================================

        stage('Docker Tag') {
            steps {

                sh '''
                    set -e

                    echo "======================================"
                    echo "DOCKER TAG"
                    echo "======================================"

                    ECR_IMAGE="${ECR_REPO}:${DOCKER_IMAGE_TAG}"

                    echo ""
                    echo "Local Image:"
                    echo "${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}"

                    echo ""
                    echo "ECR Image:"
                    echo "${ECR_IMAGE}"

                    sudo docker tag \
                        "${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}" \
                        "${ECR_IMAGE}"

                    echo ""
                    echo "Tagged images:"
                    sudo docker images

                    echo ""
                    echo "======================================"
                    echo "DOCKER TAG COMPLETED"
                    echo "======================================"
                '''
            }
        }


        // ============================================================
        // PUSH IMAGE
        // ============================================================

        stage('Push Image to ECR') {
            steps {

                sh '''
                    set -e

                    echo "======================================"
                    echo "PUSH IMAGE TO ECR"
                    echo "======================================"

                    ECR_IMAGE="${ECR_REPO}:${DOCKER_IMAGE_TAG}"

                    echo ""
                    echo "Pushing:"
                    echo "${ECR_IMAGE}"

                    sudo docker push "${ECR_IMAGE}"

                    echo ""
                    echo "======================================"
                    echo "IMAGE PUSHED TO ECR"
                    echo "======================================"
                '''
            }
        }


        // ============================================================
        // VERIFY ECR IMAGE
        // ============================================================

        stage('Verify ECR Image') {
            steps {

                sh '''
                    set -e

                    echo "======================================"
                    echo "VERIFY ECR IMAGE"
                    echo "======================================"

                    aws ecr describe-images \
                        --repository-name "${DOCKER_IMAGE_NAME}" \
                        --region "${AWS_DEFAULT_REGION}"

                    echo ""
                    echo "======================================"
                    echo "ECR IMAGE VERIFIED"
                    echo "======================================"
                '''
            }
        }


        // ============================================================
        // WAIT FOR SSH
        // ============================================================

        stage('Wait For SSH') {
            steps {

                sshagent(credentials: ['Ogust-26']) {

                    script {

                        int maxAttempts = 30
                        int attempt = 1
                        boolean connected = false

                        while (attempt <= maxAttempts) {

                            echo "SSH attempt ${attempt}/${maxAttempts}"

                            int result = sh(
                                script: """
                                    set +e

                                    ssh \
                                        -o ConnectTimeout=5 \
                                        -o StrictHostKeyChecking=no \
                                        -o UserKnownHostsFile=/dev/null \
                                        ubuntu@${env.EC2_PUBLIC_IP} \
                                        'echo SSH connection successful'

                                    exit \$?
                                """,
                                returnStatus: true
                            )

                            if (result == 0) {
                                echo "SSH connection successful"
                                connected = true
                                break
                            }

                            echo "EC2 SSH not ready yet..."
                            sleep time: 10, unit: 'SECONDS'

                            attempt++
                        }

                        if (!connected) {
                            error("EC2 SSH connection failed after ${maxAttempts} attempts")
                        }
                    }
                }
            }
        }


        // ============================================================
        // CREATE ANSIBLE INVENTORY
        // ============================================================

        stage('Create Ansible Inventory') {
            steps {

                sh '''
                    set -e

                    echo "======================================"
                    echo "CREATE ANSIBLE INVENTORY"
                    echo "======================================"

                    mkdir -p ansible

                    cat > ansible/inventory.ini <<EOF
[server]
${EC2_PUBLIC_IP} ansible_user=ubuntu
EOF

                    echo ""
                    echo "Ansible Inventory:"
                    cat ansible/inventory.ini

                    echo ""
                    echo "======================================"
                    echo "ANSIBLE INVENTORY CREATED"
                    echo "======================================"
                '''
            }
        }


        // ============================================================
        // RUN ANSIBLE
        // ============================================================

        stage('Run Ansible') {
            steps {

                sshagent(credentials: ['Ogust-26']) {

                    sh '''
                        set -e

                        echo "======================================"
                        echo "RUN ANSIBLE"
                        echo "======================================"

                        ansible-playbook \
                            -i ansible/inventory.ini \
                            ansible/setup.yml \
                            --private-key "${HOME}/.ssh/id_rsa"

                        echo ""
                        echo "======================================"
                        echo "ANSIBLE COMPLETED"
                        echo "======================================"
                    '''
                }
            }
        }


        // ============================================================
        // VERIFY SERVER
        // ============================================================

        stage('Verify Server') {
            steps {

                sshagent(credentials: ['Ogust-26']) {

                    sh '''
                        set -e

                        echo "======================================"
                        echo "VERIFY DEPLOYED SERVER"
                        echo "======================================"

                        ssh \
                            -o ConnectTimeout=10 \
                            -o StrictHostKeyChecking=no \
                            -o UserKnownHostsFile=/dev/null \
                            ubuntu@${EC2_PUBLIC_IP} '
                                echo "===== SERVER ====="
                                hostname

                                echo ""
                                echo "===== USER ====="
                                whoami

                                echo ""
                                echo "===== DOCKER ====="
                                docker --version || true

                                echo ""
                                echo "===== DOCKER CONTAINERS ====="
                                sudo docker ps || true

                                echo ""
                                echo "===== DISK ====="
                                df -h /

                                echo ""
                                echo "===== MEMORY ====="
                                free -h

                                echo ""
                                echo "===== SERVER VERIFICATION COMPLETED ====="
                            '

                        echo ""
                        echo "======================================"
                        echo "SERVER VERIFIED SUCCESSFULLY"
                        echo "======================================"
                    '''
                }
            }
        }


        // ============================================================
        // DESTROY
        // ============================================================

        stage('Destroy Infrastructure') {
            when {
                expression {
                    params.ACTION == 'DESTROY'
                }
            }

            steps {

                dir('terraform') {

                    sh '''
                        set -e

                        echo "======================================"
                        echo "DESTROY INFRASTRUCTURE"
                        echo "======================================"

                        echo ""
                        echo "Destroying Terraform-managed resources..."

                        terraform destroy \
                            -input=false \
                            -auto-approve

                        echo ""
                        echo "======================================"
                        echo "DESTROY COMPLETED"
                        echo "======================================"

                        echo "Terraform-managed resources deleted."
                    '''
                }
            }
        }
    }


    // ================================================================
    // POST ACTIONS
    // ================================================================

    post {

        success {

            echo """
======================================
PIPELINE SUCCESS
======================================

ACTION:
${params.ACTION}

Dynamic Agent AMI:
${env.AGENT_AMI_ID}

ECR Repository:
${env.ECR_REPO}

EC2 Public IP:
${env.EC2_PUBLIC_IP}

Pipeline completed successfully.
======================================
"""
        }

        failure {

            echo """
======================================
PIPELINE FAILED
======================================

ACTION:
${params.ACTION}

Dynamic Agent AMI:
${env.AGENT_AMI_ID}

Please check the Jenkins console log
for the failed stage.

======================================
"""
        }

        always {

            echo "======================================"
            echo "PIPELINE EXECUTION COMPLETED"
            echo "======================================"
        }
    }
}

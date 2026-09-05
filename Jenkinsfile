```groovy
pipeline {

    agent {
        label 'dynamic-agent'
    }

    parameters {
        choice(
            name: 'ACTION',
            choices: [
                'BUILD',
                'DESTROY'
            ],
            description: 'BUILD = create and keep resources. DESTROY = create, verify, then destroy resources.'
        )
    }

    environment {
        AWS_DEFAULT_REGION = 'us-east-1'
        AWS_REGION = 'us-east-1'
        TF_IN_AUTOMATION = 'true'

        DOCKER_IMAGE_NAME = 'dynamic-ec2-app'
        DOCKER_IMAGE_TAG = 'latest'
    }

    stages {

        // ============================================================
        // CHECK AGENT
        // ============================================================

        stage('Check Agent') {
            steps {

                echo 'Running Terraform, Docker, ECR and Ansible from Jenkins dynamic EC2 agent'

                sh '''
                    set -e

                    echo "======================================"
                    echo "CHECK AGENT"
                    echo "======================================"

                    echo "Hostname:"
                    hostname

                    echo "User:"
                    whoami

                    echo "Working directory:"
                    pwd

                    echo "Java:"
                    java -version
                '''
            }
        }


        // ============================================================
        // CHECK REQUIRED TOOLS
        // ============================================================

        stage('Check Required Tools') {
            steps {

                sh '''
                    set -e

                    echo "======================================"
                    echo "CHECK REQUIRED TOOLS"
                    echo "======================================"

                    echo ""
                    echo "Java:"
                    java -version

                    echo ""
                    echo "Terraform:"
                    terraform version

                    echo ""
                    echo "Ansible:"
                    ansible --version | head -1

                    echo ""
                    echo "AWS CLI:"
                    aws --version

                    echo ""
                    echo "Docker:"
                    docker --version

                    echo ""
                    echo "Git:"
                    git --version

                    echo ""
                    echo "Docker service:"
                    sudo systemctl is-active docker

                    echo ""
                    echo "======================================"
                    echo "ALL REQUIRED TOOLS ARE AVAILABLE"
                    echo "======================================"
                '''
            }
        }


        // ============================================================
        // TERRAFORM INIT
        // ============================================================

        stage('Terraform Init') {
            steps {

                dir('terraform') {

                    sh '''
                        set -eux

                        echo "======================================"
                        echo "TERRAFORM INIT"
                        echo "======================================"

                        echo "Hostname:"
                        hostname

                        echo "User:"
                        whoami

                        echo "Workspace:"
                        pwd

                        echo "Terraform:"
                        which terraform
                        terraform version

                        echo "Terraform files:"
                        ls -la

                        echo "Running terraform init..."

                        terraform init -input=false

                        echo "Terraform init completed successfully."
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

                        terraform plan
                    '''
                }
            }
        }


        // ============================================================
        // TERRAFORM APPLY
        // ============================================================

        stage('Build Infrastructure') {
            steps {

                dir('terraform') {

                    sh '''
                        set -e

                        echo "======================================"
                        echo "TERRAFORM APPLY"
                        echo "======================================"

                        terraform apply -auto-approve

                        echo "======================================"
                        echo "TERRAFORM APPLY COMPLETED"
                        echo "======================================"
                    '''
                }
            }
        }


        // ============================================================
        // GET ECR URL
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

                    echo "ECR Repository URL:"
                    echo "${env.ECR_REPO}"
                }
            }
        }


        // ============================================================
        // CHECK AWS IDENTITY
        // ============================================================

        stage('Check AWS Identity') {
            steps {

                sh '''
                    set -e

                    echo "======================================"
                    echo "AWS IDENTITY"
                    echo "======================================"

                    aws sts get-caller-identity

                    echo "AWS Region:"
                    echo "$AWS_DEFAULT_REGION"
                '''
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

                    echo "Dockerfile:"
                    ls -l Dockerfile

                    echo "index.html:"
                    ls -l index.html

                    echo "Building Docker image..."

                    sudo docker build \
                        -t ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG} \
                        .

                    echo "======================================"
                    echo "DOCKER IMAGE CREATED"
                    echo "======================================"

                    sudo docker images
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

                    AWS_ACCOUNT_ID=$(aws sts get-caller-identity \
                        --query Account \
                        --output text)

                    echo "AWS Account:"
                    echo "$AWS_ACCOUNT_ID"

                    aws ecr get-login-password \
                        --region "$AWS_DEFAULT_REGION" | \
                    sudo docker login \
                        --username AWS \
                        --password-stdin "$ECR_REPO"

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

                    sudo docker tag \
                        ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG} \
                        ${ECR_REPO}:${DOCKER_IMAGE_TAG}

                    echo "Tagged image:"
                    echo "${ECR_REPO}:${DOCKER_IMAGE_TAG}"

                    echo "Docker images:"
                    sudo docker images
                '''
            }
        }


        // ============================================================
        // PUSH TO ECR
        // ============================================================

        stage('Push Image to ECR') {
            steps {

                sh '''
                    set -e

                    echo "======================================"
                    echo "PUSH IMAGE TO ECR"
                    echo "======================================"

                    sudo docker push \
                        ${ECR_REPO}:${DOCKER_IMAGE_TAG}

                    echo "======================================"
                    echo "IMAGE PUSHED SUCCESSFULLY"
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
                        --image-ids imageTag="${DOCKER_IMAGE_TAG}" \
                        --region "$AWS_DEFAULT_REGION"

                    echo "======================================"
                    echo "ECR IMAGE VERIFIED SUCCESSFULLY"
                    echo "======================================"
                '''
            }
        }


        // ============================================================
        // GET EC2 IP
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
                }
            }
        }


        // ============================================================
        // WAIT FOR SSH
        // ============================================================

        stage('Wait For SSH') {
            steps {

                script {

                    echo "Waiting for SSH on ${env.EC2_PUBLIC_IP}"

                    timeout(time: 5, unit: 'MINUTES') {

                        waitUntil {

                            def result

                            sshagent(credentials: ['Ogust-26']) {

                                result = sh(
                                    script: """
                                        ssh-keyscan -H ${env.EC2_PUBLIC_IP} >> ~/.ssh/known_hosts 2>/dev/null || true

                                        ssh \
                                            -o ConnectTimeout=5 \
                                            -o StrictHostKeyChecking=no \
                                            ubuntu@${env.EC2_PUBLIC_IP} \
                                            'echo SSH connection successful'
                                    """,
                                    returnStatus: true
                                )
                            }

                            if (result == 0) {

                                echo "SSH connection successful"

                                return true
                            }

                            echo "EC2 SSH not ready yet..."

                            sleep 10

                            return false
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

                sh """
                    set -e

                    echo "======================================"
                    echo "CREATE ANSIBLE INVENTORY"
                    echo "======================================"

                    cat > ansible/inventory.ini <<EOF
[server]
${env.EC2_PUBLIC_IP} ansible_user=ubuntu
EOF

                    echo "Ansible inventory:"
                    cat ansible/inventory.ini
                """
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
                        echo "ANSIBLE PING"
                        echo "======================================"

                        ansible \
                            -i ansible/inventory.ini \
                            server \
                            -m ping

                        echo "======================================"
                        echo "RUNNING ANSIBLE PLAYBOOK"
                        echo "======================================"

                        ansible-playbook \
                            -i ansible/inventory.ini \
                            ansible/setup.yml
                    '''
                }
            }
        }


        // ============================================================
        // VERIFY EC2 SERVER
        // ============================================================

        stage('Verify Server') {
            steps {

                sshagent(credentials: ['Ogust-26']) {

                    sh """
                        set -e

                        echo "======================================"
                        echo "VERIFY SERVER"
                        echo "======================================"

                        ssh \
                            -o StrictHostKeyChecking=no \
                            ubuntu@${env.EC2_PUBLIC_IP} \
                            '
                            echo "===== SERVER ====="
                            hostname

                            echo "===== OS ====="
                            cat /etc/os-release | grep PRETTY_NAME

                            echo "===== JAVA ====="
                            java -version

                            echo "===== TERRAFORM ====="
                            terraform version

                            echo "===== ANSIBLE ====="
                            ansible --version | head -1

                            echo "===== AWS CLI ====="
                            aws --version

                            echo "===== DOCKER ====="
                            sudo docker --version

                            echo "===== DOCKER STATUS ====="
                            sudo systemctl is-active docker
                            '
                    """
                }
            }
        }


        // ============================================================
        // DESTROY
        // ============================================================

        stage('Destroy') {

            when {

                expression {
                    return params.ACTION == 'DESTROY'
                }
            }

            steps {

                dir('terraform') {

                    sh '''
                        set -e

                        echo "======================================"
                        echo "DESTROY STARTED"
                        echo "======================================"

                        terraform destroy -auto-approve

                        echo "======================================"
                        echo "DESTROY COMPLETED"
                        echo "======================================"

                        echo "EC2, ECR and Terraform-managed resources deleted."
                    '''
                }
            }
        }
    }


    // ================================================================
    // POST
    // ================================================================

    post {

        success {

            echo """
            ==========================================
            PIPELINE SUCCESS
            ==========================================

            Terraform infrastructure: SUCCESS
            ECR repository: SUCCESS
            Docker image build: SUCCESS
            ECR login: SUCCESS
            Docker push: SUCCESS
            ECR image verification: SUCCESS
            Ansible configuration: SUCCESS
            EC2 verification: SUCCESS

            Docker Image:
            ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}

            ECR Repository:
            ${env.ECR_REPO}

            EC2 Public IP:
            ${env.EC2_PUBLIC_IP}

            Action:
            ${params.ACTION}

            ==========================================
            """
        }

        failure {

            echo """
            ==========================================
            PIPELINE FAILED
            ==========================================

            Check the failed stage in Jenkins Console Output.

            ==========================================
            """
        }

        always {

            echo "Pipeline execution completed."
        }
    }
}
```

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
        // INSTALL REQUIRED TOOLS
        // ============================================================

        stage('Install Required Tools') {
            steps {

                sh '''
                    set -e

                    echo "======================================"
                    echo "INSTALL REQUIRED TOOLS"
                    echo "======================================"

                    echo "Waiting for Ubuntu startup..."
                    sleep 20

                    echo "======================================"
                    echo "UPDATE APT"
                    echo "======================================"

                    sudo DEBIAN_FRONTEND=noninteractive \
                        apt-get \
                        -o DPkg::Lock::Timeout=300 \
                        update -y


                    echo "======================================"
                    echo "INSTALL BASIC PACKAGES"
                    echo "======================================"

                    sudo DEBIAN_FRONTEND=noninteractive \
                        apt-get \
                        -o DPkg::Lock::Timeout=300 \
                        install -y \
                        wget \
                        unzip \
                        curl \
                        jq \
                        ansible \
                        ca-certificates \
                        gnupg \
                        lsb-release


                    # ====================================================
                    # AWS CLI V2
                    # ====================================================

                    echo "======================================"
                    echo "INSTALL AWS CLI V2"
                    echo "======================================"

                    if command -v aws >/dev/null 2>&1; then

                        echo "AWS CLI already installed."

                    else

                        cd /tmp

                        rm -f awscliv2.zip

                        echo "Downloading AWS CLI v2..."

                        curl -fsSL \
                            "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" \
                            -o awscliv2.zip

                        echo "Extracting AWS CLI..."

                        rm -rf /tmp/aws

                        unzip -q awscliv2.zip

                        echo "Installing AWS CLI..."

                        sudo /tmp/aws/install

                        rm -rf /tmp/aws
                        rm -f /tmp/awscliv2.zip

                    fi


                    echo "AWS CLI version:"
                    aws --version


                    # ====================================================
                    # DOCKER
                    # ====================================================

                    echo "======================================"
                    echo "INSTALL DOCKER"
                    echo "======================================"

                    if command -v docker >/dev/null 2>&1; then

                        echo "Docker already installed."

                    else

                        echo "Installing Docker..."

                        sudo install -m 0755 -d /etc/apt/keyrings

                        sudo curl -fsSL \
                            https://download.docker.com/linux/ubuntu/gpg \
                            -o /etc/apt/keyrings/docker.asc

                        sudo chmod a+r /etc/apt/keyrings/docker.asc

                        echo \
                            "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
                            | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

                        sudo DEBIAN_FRONTEND=noninteractive \
                            apt-get \
                            -o DPkg::Lock::Timeout=300 \
                            update -y

                        sudo DEBIAN_FRONTEND=noninteractive \
                            apt-get \
                            -o DPkg::Lock::Timeout=300 \
                            install -y \
                            docker-ce \
                            docker-ce-cli \
                            containerd.io \
                            docker-buildx-plugin \
                            docker-compose-plugin

                    fi


                    echo "Starting Docker..."

                    sudo systemctl enable docker
                    sudo systemctl start docker

                    sudo systemctl is-active docker

                    echo "Docker version:"
                    sudo docker --version


                    # ====================================================
                    # TERRAFORM
                    # ====================================================

                    echo "======================================"
                    echo "INSTALL TERRAFORM"
                    echo "======================================"

                    if command -v terraform >/dev/null 2>&1; then

                        echo "Terraform already installed."

                    else

                        TERRAFORM_VERSION="1.13.3"

                        cd /tmp

                        echo "Downloading Terraform ${TERRAFORM_VERSION}..."

                        wget -q \
                            https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip

                        sudo unzip -o \
                            terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
                            -d /usr/local/bin/

                        rm -f terraform_${TERRAFORM_VERSION}_linux_amd64.zip

                    fi


                    # ====================================================
                    # VERIFY TOOLS
                    # ====================================================

                    echo "======================================"
                    echo "VERIFY TOOLS"
                    echo "======================================"

                    echo "AWS CLI:"
                    aws --version

                    echo "Docker:"
                    sudo docker --version

                    echo "Terraform:"
                    terraform version

                    echo "Ansible:"
                    ansible --version

                    echo "======================================"
                    echo "ALL REQUIRED TOOLS READY"
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
                        set -e

                        echo "======================================"
                        echo "TERRAFORM INIT"
                        echo "======================================"

                        terraform init
                    '''
                }
            }
        }


        // ============================================================
        // DEBUG TERRAFORM
        // ============================================================

        stage('Debug Terraform Files') {
            steps {

                dir('terraform') {

                    sh '''
                        set -e

                        echo "======================================"
                        echo "TERRAFORM FILES"
                        echo "======================================"

                        pwd

                        echo "----- FILE LIST -----"
                        ls -la

                        echo "----- main.tf -----"
                        cat main.tf

                        echo "----- outputs.tf -----"
                        cat outputs.tf

                        echo "----- TERRAFORM RESOURCES -----"

                        grep -R 'resource "aws_instance"' . || true
                        grep -R 'resource "aws_ecr_repository"' . || true
                        grep -R 'resource "aws_iam_role"' . || true
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

                        echo "===== DOCKER ====="
                        docker --version

                        echo "===== DOCKER STATUS ====="
                        systemctl is-active docker
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

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
                echo 'Running pipeline on Jenkins dynamic EC2 agent'

                sh '''
                    set -e

                    echo "======================================"
                    echo "CHECK AGENT"
                    echo "======================================"

                    echo "Hostname:"
                    hostname

                    echo ""
                    echo "User:"
                    whoami

                    echo ""
                    echo "Working Directory:"
                    pwd

                    echo ""
                    echo "Java:"
                    java -version

                    echo ""
                    echo "Kernel:"
                    uname -a

                    echo ""
                    echo "Disk:"
                    df -h /
                '''
            }
        }


        // ============================================================
        // INSTALL / CHECK REQUIRED TOOLS
        // ============================================================

        stage('Check Required Tools') {
            steps {
                sh '''
                    set -e

                    echo "======================================"
                    echo "CHECK / INSTALL REQUIRED TOOLS"
                    echo "======================================"

                    echo ""
                    echo "===== JAVA ====="
                    java -version


                    echo ""
                    echo "===== GIT ====="

                    if command -v git >/dev/null 2>&1; then
                        git --version
                    else
                        echo "Git not found. Installing..."
                        sudo apt-get update -y
                        sudo apt-get install -y git
                        git --version
                    fi


                    echo ""
                    echo "===== CURL / UNZIP ====="

                    sudo apt-get update -y
                    sudo apt-get install -y curl unzip wget gnupg


                    echo ""
                    echo "===== AWS CLI ====="

                    if command -v aws >/dev/null 2>&1; then

                        echo "AWS CLI already installed:"
                        aws --version

                    else

                        echo "AWS CLI not found. Installing AWS CLI v2..."

                        cd /tmp

                        rm -rf aws awscliv2.zip

                        curl -fsSL \
                            "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" \
                            -o awscliv2.zip

                        unzip -q awscliv2.zip

                        sudo ./aws/install

                        rm -rf aws awscliv2.zip

                        echo "AWS CLI installed:"
                        aws --version

                    fi


                    echo ""
                    echo "===== TERRAFORM ====="

                    if command -v terraform >/dev/null 2>&1; then

                        echo "Terraform already installed:"
                        terraform version

                    else

                        echo "Terraform not found. Installing Terraform..."

                        TERRAFORM_VERSION="1.16.0"

                        cd /tmp

                        rm -f terraform_${TERRAFORM_VERSION}_linux_amd64.zip
                        rm -f terraform

                        wget -q \
                            https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip

                        unzip -o \
                            terraform_${TERRAFORM_VERSION}_linux_amd64.zip

                        sudo mv terraform /usr/local/bin/terraform

                        sudo chmod +x /usr/local/bin/terraform

                        rm -f terraform_${TERRAFORM_VERSION}_linux_amd64.zip

                        echo "Terraform installed:"
                        terraform version

                    fi


                    echo ""
                    echo "===== DOCKER ====="

                    if command -v docker >/dev/null 2>&1; then

                        echo "Docker already installed:"
                        docker --version

                    else

                        echo "Docker not found. Installing Docker..."

                        sudo apt-get update -y

                        sudo apt-get install -y docker.io

                        sudo systemctl enable docker
                        sudo systemctl start docker

                        echo "Docker installed:"
                        docker --version

                    fi


                    echo ""
                    echo "===== DOCKER SERVICE ====="

                    if sudo systemctl is-active --quiet docker; then
                        echo "Docker service is running"
                    else
                        echo "Docker service is not running. Starting..."
                        sudo systemctl start docker
                    fi

                    sudo systemctl is-active docker


                    echo ""
                    echo "===== ANSIBLE ====="

                    if command -v ansible >/dev/null 2>&1; then

                        echo "Ansible already installed:"
                        ansible --version

                    else

                        echo "Ansible not found. Installing Ansible..."

                        sudo apt-get update -y
                        sudo apt-get install -y ansible

                        echo "Ansible installed:"
                        ansible --version

                    fi


                    echo ""
                    echo "======================================"
                    echo "ALL REQUIRED TOOLS ARE READY"
                    echo "======================================"

                    echo ""
                    echo "AWS CLI:"
                    aws --version

                    echo ""
                    echo "Terraform:"
                    terraform version

                    echo ""
                    echo "Docker:"
                    docker --version

                    echo ""
                    echo "Ansible:"
                    ansible --version | head -1
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

                    aws --version

                    echo ""
                    echo "AWS Region:"
                    echo "$AWS_DEFAULT_REGION"

                    echo ""
                    echo "AWS Caller Identity:"

                    aws sts get-caller-identity

                    echo ""
                    echo "AWS credentials are working successfully."
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

                        echo "Hostname:"
                        hostname

                        echo ""
                        echo "User:"
                        whoami

                        echo ""
                        echo "Workspace:"
                        pwd

                        echo ""
                        echo "Terraform:"
                        terraform version

                        echo ""
                        echo "Terraform Files:"
                        ls -la

                        echo ""
                        echo "Running terraform init..."

                        terraform init -input=false

                        echo ""
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

                        echo ""
                        echo "Terraform configuration is valid."
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

                        terraform apply \
                            -input=false \
                            -auto-approve

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

                    echo "ECR Repository URL:"
                    echo "${env.ECR_REPO}"
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

                    echo "${env.EC2_PUBLIC_IP}"
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

                    echo "Docker:"
                    sudo docker --version

                    echo ""
                    echo "Dockerfile:"
                    ls -l Dockerfile

                    echo ""
                    echo "index.html:"
                    ls -l index.html

                    echo ""
                    echo "Building Docker image..."

                    sudo docker build \
                        -t ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG} \
                        .

                    echo ""
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

                    echo ""
                    echo "ECR Repository:"
                    echo "$ECR_REPO"

                    echo ""
                    echo "Logging into ECR..."

                    aws ecr get-login-password \
                        --region "$AWS_DEFAULT_REGION" | \
                    sudo docker login \
                        --username AWS \
                        --password-stdin "$ECR_REPO"

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

                    sudo docker tag \
                        ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG} \
                        ${ECR_REPO}:${DOCKER_IMAGE_TAG}

                    echo "Tagged image:"
                    echo "${ECR_REPO}:${DOCKER_IMAGE_TAG}"

                    echo ""
                    echo "Docker images:"

                    sudo docker images
                '''
            }
        }


        // ============================================================
        // PUSH IMAGE TO ECR
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

                    echo ""
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

                    echo ""
                    echo "======================================"
                    echo "ECR IMAGE VERIFIED SUCCESSFULLY"
                    echo "======================================"
                '''
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

                    mkdir -p ansible

                    cat > ansible/inventory.ini <<EOF
[server]
${env.EC2_PUBLIC_IP} ansible_user=ubuntu
EOF

                    echo ""
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

                        echo ""
                        echo "======================================"
                        echo "RUNNING ANSIBLE PLAYBOOK"
                        echo "======================================"

                        ansible-playbook \
                            -i ansible/inventory.ini \
                            ansible/setup.yml

                        echo ""
                        echo "======================================"
                        echo "ANSIBLE COMPLETED SUCCESSFULLY"
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

                    sh """
                        set -e

                        echo "======================================"
                        echo "VERIFY SERVER"
                        echo "======================================"

                        ssh \
                            -o ConnectTimeout=10 \
                            -o StrictHostKeyChecking=no \
                            ubuntu@${env.EC2_PUBLIC_IP} \
                            '
                            echo "===== SERVER ====="
                            hostname

                            echo ""
                            echo "===== PRIVATE IP ====="
                            hostname -I

                            echo ""
                            echo "===== OS ====="
                            grep PRETTY_NAME /etc/os-release

                            echo ""
                            echo "===== JAVA ====="
                            java -version

                            echo ""
                            echo "===== TERRAFORM ====="
                            terraform version

                            echo ""
                            echo "===== ANSIBLE ====="
                            ansible --version | head -1

                            echo ""
                            echo "===== AWS CLI ====="
                            aws --version

                            echo ""
                            echo "===== DOCKER ====="
                            sudo docker --version

                            echo ""
                            echo "===== DOCKER STATUS ====="
                            sudo systemctl is-active docker

                            echo ""
                            echo "===== DOCKER CONTAINERS ====="
                            sudo docker ps
                            '

                        echo ""
                        echo "======================================"
                        echo "SERVER VERIFICATION SUCCESSFUL"
                        echo "======================================"
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
            ==========================================
                     PIPELINE SUCCESS
            ==========================================

            Dynamic Jenkins Agent : SUCCESS
            Required Tools        : SUCCESS
            AWS Authentication    : SUCCESS
            Terraform Init        : SUCCESS
            Terraform Validate    : SUCCESS
            Terraform Plan        : SUCCESS
            Terraform Apply       : SUCCESS

            ECR Repository:
            ${env.ECR_REPO}

            Docker Build          : SUCCESS
            ECR Login             : SUCCESS
            Docker Push           : SUCCESS
            ECR Verification      : SUCCESS

            SSH Connection        : SUCCESS
            Ansible Configuration : SUCCESS
            Server Verification   : SUCCESS

            Action:
            ${params.ACTION}

            EC2 Public IP:
            ${env.EC2_PUBLIC_IP}

            Docker Image:
            ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}

            ==========================================
                     PIPELINE COMPLETED
            ==========================================
            """
        }


        failure {

            echo """
            ==========================================
                     PIPELINE FAILED
            ==========================================

            Check the failed stage in the Jenkins
            Console Output.

            ==========================================
            """
        }


        always {

            echo "Pipeline execution completed."
        }
    }
}
```

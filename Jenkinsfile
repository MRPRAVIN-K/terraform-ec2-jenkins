pipeline {

    agent {
        label 'dynamic-agent'
    }

    options {
        disableConcurrentBuilds()
        timestamps()
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

                    echo ""
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
                    echo "===== JAVA ====="
                    java -version

                    echo ""
                    echo "===== TERRAFORM ====="

                    if command -v terraform >/dev/null 2>&1; then
                        terraform version
                    else
                        echo "ERROR: Terraform is NOT installed on this AMI"
                        exit 1
                    fi

                    echo ""
                    echo "===== AWS CLI ====="

                    if command -v aws >/dev/null 2>&1; then
                        aws --version
                    else
                        echo "ERROR: AWS CLI is NOT installed on this AMI"
                        exit 1
                    fi

                    echo ""
                    echo "===== DOCKER ====="

                    if command -v docker >/dev/null 2>&1; then
                        docker --version
                    else
                        echo "ERROR: Docker is NOT installed on this AMI"
                        exit 1
                    fi

                    echo ""
                    echo "===== DOCKER SERVICE ====="

                    if sudo systemctl is-active --quiet docker; then
                        echo "Docker service is running"
                    else
                        echo "Docker service is not running."
                        echo "Starting Docker..."

                        sudo systemctl start docker

                        if sudo systemctl is-active --quiet docker; then
                            echo "Docker service started successfully"
                        else
                            echo "ERROR: Docker service could not be started"
                            exit 1
                        fi
                    fi

                    echo ""
                    echo "===== ANSIBLE ====="

                    if command -v ansible >/dev/null 2>&1; then
                        ansible --version | head -n 1
                    else
                        echo "ERROR: Ansible is NOT installed on this AMI"
                        exit 1
                    fi

                    echo ""
                    echo "===== GIT ====="

                    if command -v git >/dev/null 2>&1; then
                        git --version
                    else
                        echo "ERROR: Git is NOT installed on this AMI"
                        exit 1
                    fi

                    echo ""
                    echo "===== CURL ====="

                    if command -v curl >/dev/null 2>&1; then
                        curl --version | head -n 1
                    else
                        echo "ERROR: curl is NOT installed on this AMI"
                        exit 1
                    fi

                    echo ""
                    echo "===== UNZIP ====="

                    if command -v unzip >/dev/null 2>&1; then
                        unzip -v | head -n 1
                    else
                        echo "ERROR: unzip is NOT installed on this AMI"
                        exit 1
                    fi

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
                    echo "$AWS_DEFAULT_REGION"

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
                        echo "JENKINS TERRAFORM DEBUG"
                        echo "======================================"

                        echo ""
                        echo "CURRENT DIRECTORY:"
                        pwd

                        echo ""
                        echo "TERRAFORM VERSION:"
                        terraform version

                        echo ""
                        echo "TERRAFORM WORKSPACE:"

                        terraform workspace show

                        echo ""
                        echo "TERRAFORM FILES:"
                        ls -lah

                        echo ""
                        echo "TERRAFORM STATE FILE:"

                        if [ -f terraform.tfstate ]; then
                            ls -lh terraform.tfstate
                        else
                            echo "terraform.tfstate NOT FOUND"
                        fi

                        echo ""
                        echo "TERRAFORM STATE LIST:"

                        if [ -f terraform.tfstate ]; then
                            terraform state list || true
                        else
                            echo "No local terraform.tfstate available."
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

                        echo ""
                        echo "Hostname:"
                        hostname

                        echo ""
                        echo "User:"
                        whoami

                        echo ""
                        echo "Working Directory:"
                        pwd

                        echo ""
                        echo "Terraform Version:"
                        terraform version

                        echo ""
                        echo "Terraform Files:"
                        ls -lah

                        echo ""
                        echo "Running terraform init..."

                        terraform init -input=false

                        echo ""
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

                        echo ""
                        echo "Terraform Outputs:"
                        terraform output
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
                    echo "Docker:"
                    sudo docker --version

                    echo ""
                    echo "Docker Service:"
                    sudo systemctl is-active docker

                    echo ""
                    echo "Dockerfile:"
                    ls -l Dockerfile

                    echo ""
                    echo "index.html:"
                    ls -l index.html

                    echo ""
                    echo "Building Docker image..."

                    sudo docker build \
                        -t "${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}" \
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

                    echo ""
                    echo "AWS Account:"
                    echo "$AWS_ACCOUNT_ID"

                    echo ""
                    echo "ECR Repository:"
                    echo "$ECR_REPO"

                    ECR_REGISTRY="${ECR_REPO%%/*}"

                    echo ""
                    echo "ECR Registry:"
                    echo "$ECR_REGISTRY"

                    echo ""
                    echo "Logging into ECR..."

                    aws ecr get-login-password \
                        --region "$AWS_DEFAULT_REGION" | \
                    sudo docker login \
                        --username AWS \
                        --password-stdin "$ECR_REGISTRY"

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
                        "${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}" \
                        "${ECR_REPO}:${DOCKER_IMAGE_TAG}"

                    echo ""
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
                        "${ECR_REPO}:${DOCKER_IMAGE_TAG}"

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
                                        set +e

                                        mkdir -p ~/.ssh
                                        touch ~/.ssh/known_hosts

                                        ssh-keyscan \
                                            -H \
                                            ${env.EC2_PUBLIC_IP} \
                                            >> ~/.ssh/known_hosts 2>/dev/null || true

                                        ssh \
                                            -o ConnectTimeout=5 \
                                            -o StrictHostKeyChecking=no \
                                            -o UserKnownHostsFile=/dev/null \
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
                            -o UserKnownHostsFile=/dev/null \
                            ubuntu@${env.EC2_PUBLIC_IP} '
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

                        echo ""
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

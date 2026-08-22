pipeline {

    agent {
        label 'dynamic-agent'
    }

    environment {
        AWS_DEFAULT_REGION = 'us-east-1'
        TF_IN_AUTOMATION = 'true'
    }

    stages {

        stage('Check Agent') {
            steps {
                echo 'Running Terraform and Ansible from Jenkins dynamic EC2 agent'

                sh '''
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

        stage('Install Required Tools') {
            steps {
                sh '''
                    set -e

                    echo "Installing required packages..."

                    sudo apt-get update -y
                    sudo apt-get install -y \
                        wget \
                        unzip \
                        curl \
                        software-properties-common \
                        gnupg \
                        lsb-release \
                        ansible

                    echo "Installing Terraform..."

                    TERRAFORM_VERSION="1.13.3"

                    if ! command -v terraform >/dev/null 2>&1; then
                        cd /tmp

                        wget -q \
                          https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip

                        sudo unzip -o \
                          terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
                          -d /usr/local/bin/

                        rm -f terraform_${TERRAFORM_VERSION}_linux_amd64.zip
                    fi

                    echo "Terraform version:"
                    terraform version

                    echo "Ansible version:"
                    ansible --version
                '''
            }
        }

        stage('Terraform Init') {
            steps {
                dir('terraform') {
                    sh '''
                        terraform init
                    '''
                }
            }
        }

        stage('Terraform Validate') {
            steps {
                dir('terraform') {
                    sh '''
                        terraform validate
                    '''
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                dir('terraform') {
                    sh '''
                        terraform plan
                    '''
                }
            }
        }

        stage('Create EC2 Server') {
            steps {
                dir('terraform') {
                    sh '''
                        terraform apply -auto-approve
                    '''
                }
            }
        }

        stage('Get EC2 IP') {
            steps {
                script {

                    def ip = sh(
                        script: '''
                            cd terraform
                            terraform output -raw public_ip
                        ''',
                        returnStdout: true
                    ).trim()

                    env.EC2_PUBLIC_IP = ip

                    echo "Created EC2 Public IP: ${env.EC2_PUBLIC_IP}"
                }
            }
        }

        stage('Wait For SSH') {
            steps {
                script {

                    timeout(time: 5, unit: 'MINUTES') {

                        waitUntil {

                            def result = sh(
                                script: """
                                    ssh-keyscan -H ${env.EC2_PUBLIC_IP} >> ~/.ssh/known_hosts 2>/dev/null || true

                                    ssh -o ConnectTimeout=5 \
                                        -o StrictHostKeyChecking=no \
                                        ubuntu@${env.EC2_PUBLIC_IP} \
                                        'echo SSH connection successful'
                                """,
                                returnStatus: true
                            )

                            if (result == 0) {
                                echo "SSH connection successful"
                                return true
                            }

                            echo "Waiting for EC2 SSH..."
                            sleep 10

                            return false
                        }
                    }
                }
            }
        }

        stage('Create Ansible Inventory') {
            steps {

                sh """
                    cat > ansible/inventory.ini <<EOF
[server]
${env.EC2_PUBLIC_IP} ansible_user=ubuntu
EOF

                    echo "Ansible inventory:"
                    cat ansible/inventory.ini
                """
            }
        }

        stage('Run Ansible') {
            steps {

                sshagent(credentials: ['Ogust-26']) {

                    sh '''
                        set -e

                        echo "Testing Ansible connectivity..."

                        ansible \
                            -i ansible/inventory.ini \
                            server \
                            -m ping

                        echo "Running Ansible configuration..."

                        ansible-playbook \
                            -i ansible/inventory.ini \
                            ansible/setup.yml
                    '''
                }
            }
        }

        stage('Verify Server') {
            steps {

                sshagent(credentials: ['Ogust-26']) {

                    sh """
                        echo "Checking final server..."

                        ssh \
                            -o StrictHostKeyChecking=no \
                            ubuntu@${env.EC2_PUBLIC_IP} \
                            'echo "===== SERVER ====="; hostname; echo "===== JAVA ====="; java -version; echo "===== DOCKER ====="; docker --version; echo "===== DOCKER STATUS ====="; systemctl is-active docker'
                    """
                }
            }
        }
    }

    post {

        success {
            echo """
            ==========================================
            SUCCESS
            ==========================================
            EC2 server created by Terraform
            Server configured by Ansible
            Java 21 installed
            Docker installed
            Docker service started

            Public IP:
            ${env.EC2_PUBLIC_IP}

            ==========================================
            """
        }

        failure {
            echo """
            ==========================================
            PIPELINE FAILED
            ==========================================
            Check the stage that failed.
            ==========================================
            """
        }

        always {
            echo "Pipeline execution completed."
        }
    }
}

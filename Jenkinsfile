pipeline {

    agent {
        label 'dynamic-agent'
    }

    parameters {
        booleanParam(
            name: 'DESTROY_AFTER_BUILD',
            defaultValue: false,
            description: 'Destroy the Terraform EC2 after Ansible configuration and verification'
        )
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


        stage('Install Required Tools') {
            steps {
                sh '''
                    set -e

                    echo "======================================"
                    echo "INSTALL REQUIRED TOOLS"
                    echo "======================================"

                    echo "Waiting for Ubuntu package manager..."

                    for i in {1..30}; do

                        if sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 || \
                           sudo fuser /var/lib/dpkg/lock >/dev/null 2>&1 || \
                           sudo fuser /var/lib/apt/lists/lock >/dev/null 2>&1; then

                            echo "APT/DPKG is currently busy..."
                            echo "Waiting 10 seconds..."
                            sleep 10

                        else

                            echo "APT/DPKG lock is available."
                            break

                        fi

                        if [ "$i" -eq 30 ]; then
                            echo "ERROR: APT/DPKG lock is still busy after 5 minutes."
                            exit 1
                        fi

                    done

                    echo "Updating package lists..."

                    sudo apt-get update -y

                    echo "Installing required packages..."

                    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
                        wget \
                        unzip \
                        curl \
                        software-properties-common \
                        gnupg \
                        lsb-release \
                        ansible

                    echo "======================================"
                    echo "CHECKING ANSIBLE"
                    echo "======================================"

                    ansible --version

                    echo "======================================"
                    echo "CHECKING TERRAFORM"
                    echo "======================================"

                    if command -v terraform >/dev/null 2>&1; then

                        echo "Terraform already installed."

                    else

                        echo "Terraform not found. Installing..."

                        TERRAFORM_VERSION="1.13.3"

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

                    echo "======================================"
                    echo "REQUIRED TOOLS READY"
                    echo "======================================"
                '''
            }
        }


        stage('Terraform Init') {
            steps {
                dir('terraform') {
                    sh '''
                        echo "======================================"
                        echo "TERRAFORM INIT"
                        echo "======================================"

                        terraform init
                    '''
                }
            }
        }


        stage('Terraform Validate') {
            steps {
                dir('terraform') {
                    sh '''
                        echo "======================================"
                        echo "TERRAFORM VALIDATE"
                        echo "======================================"

                        terraform validate
                    '''
                }
            }
        }


        stage('Terraform Plan') {
            steps {
                dir('terraform') {
                    sh '''
                        echo "======================================"
                        echo "TERRAFORM PLAN"
                        echo "======================================"

                        terraform plan
                    '''
                }
            }
        }


        stage('Build') {
            steps {
                dir('terraform') {
                    sh '''
                        echo "======================================"
                        echo "BUILD STARTED"
                        echo "Creating EC2 using Terraform"
                        echo "======================================"

                        terraform apply -auto-approve

                        echo "======================================"
                        echo "BUILD COMPLETED"
                        echo "======================================"
                    '''
                }
            }
        }


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

                    echo "Created EC2 Public IP: ${env.EC2_PUBLIC_IP}"
                }
            }
        }


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
        stage('Create Ansible Inventory') {
            steps {

                sh """
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


        stage('Verify Server') {
            steps {

                sshagent(credentials: ['Ogust-26']) {

                    sh """
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


        stage('Destroy') {

            when {
                expression {
                    return params.DESTROY_AFTER_BUILD
                }
            }

            steps {
                dir('terraform') {

                    sh '''
                        echo "======================================"
                        echo "DESTROY STARTED"
                        echo "======================================"

                        terraform destroy -auto-approve

                        echo "======================================"
                        echo "DESTROY COMPLETED"
                        echo "EC2 SERVER DELETED"
                        echo "======================================"
                    '''
                }
            }
        }
    }


    post {

        success {
            echo """
            ==========================================
            PIPELINE SUCCESS
            ==========================================

            EC2 created by Terraform
            Ansible configuration completed
            Java 21 installed
            Docker installed
            Docker verified

            EC2 Public IP:
            ${env.EC2_PUBLIC_IP}

            Destroy selected:
            ${params.DESTROY_AFTER_BUILD}

            ==========================================
            """
        }

        failure {
            echo """
            ==========================================
            PIPELINE FAILED
            ==========================================

            Check the failed stage in Jenkins console.

            ==========================================
            """
        }

        always {
            echo "Pipeline execution completed."
        }
    }
}

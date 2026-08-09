pipeline {
    agent {
        label 'dynamic-agent'
    }

    stages {
        stage('Checkout') {
            steps {
                echo 'Code checked out successfully'
                checkout scm
            }
        }

        stage('Build') {
            steps {
                echo 'Build stage started'
                sh 'hostname'
                sh 'whoami'
                sh 'pwd'
                sh 'ls -la'
            }
        }

        stage('Test') {
            steps {
                echo 'Test stage completed successfully'
            }
        }
    }

    post {
        always {
            echo 'Pipeline execution finished'
        }

        success {
            echo 'Pipeline completed successfully'
        }

        failure {
            echo 'Pipeline failed'
        }
    }
}

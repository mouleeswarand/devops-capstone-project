pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Terraform Format') {
            steps {
                dir('terraform-jenkins-infra') {
                    sh 'terraform fmt -check -recursive'
                }
            }
        }

        stage('Terraform Init') {
            steps {
                dir('terraform-jenkins-infra') {
                    sh 'terraform init -input=false'
                }
            }
        }

        stage('Terraform Validate') {
            steps {
                dir('terraform-jenkins-infra') {
                    sh 'terraform validate'
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                withCredentials([
                    string(
                        credentialsId: 'jenkins-admin-cidr',
                        variable: 'TF_VAR_admin_cidr'
                    )
                ]) {
                    dir('terraform-jenkins-infra') {
                        sh '''
                            terraform plan \
                              -input=false \
                              -lock-timeout=5m \
                              -out=tfplan
                            terraform show -no-color tfplan > tfplan.txt
                        '''
                    }
                }

                dir('terraform-jenkins-infra') {
                    sh '''
                        echo "Checking Terraform plan files..."
                        ls -lh tfplan tfplan.txt
                        test -s tfplan
                        test -s tfplan.txt
                    '''
                }

                archiveArtifacts(
                    archiveArtifacts artifacts: 'terraform-jenkins-infra/tfplan*', fingerprint: true, allowEmptyArchive: false
                )
            }
        }
    }

    post {
        success {
            echo 'Jenkins Terraform plan completed successfully.'
        }
        failure {
            echo 'Terraform pipeline failed. Check the console output.'
        }
    }
}
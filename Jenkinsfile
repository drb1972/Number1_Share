pipeline {
    agent any
    stages {
        stage('Check Password') {
            steps {
                sh "rexx start pass"
            }
        }
        stage('Alloc') {
            steps {
                sh "rexx start alloc"
            }
        }
        stage('Upload') {
            steps {
                sh "rexx start upload"
            }
        }
        stage('Test in TEST UK') {
            steps {
                sh "rexx start testt_uk"
            }
        }
        stage('Test in TEST US') {
            steps {
                sh "rexx start testt_us"
            }
        }
                stage('Install in PROD') {
            steps {
                sh "rexx start install"
            }
        }
                stage('Test in PROD UK') {
            steps {
                sh "rexx start testp_uk"
            }
        }
                stage('Test in PROD UK') {
            steps {
                sh "rexx start testp_uk"
            }
        }
    }
}
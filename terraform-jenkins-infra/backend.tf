terraform {
  backend "s3" {
    bucket       = "devops-capstone-jenkins-tfstate-625228299204-us-east-1"
    key          = "jenkins/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
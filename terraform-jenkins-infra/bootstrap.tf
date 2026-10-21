
data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "jenkins_tfstate" {
  bucket = "devops-capstone-jenkins-tfstate-625228299204-us-east-1"

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name        = "devops-capstone-jenkins-tfstate"
    Project     = "devops-capstone"
    ManagedBy   = "Terraform"
    Environment = "lab"
  }
}

resource "aws_s3_bucket_versioning" "jenkins_tfstate" {
  bucket = aws_s3_bucket.jenkins_tfstate.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "jenkins_tfstate" {
  bucket = aws_s3_bucket.jenkins_tfstate.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "jenkins_tfstate" {
  bucket = aws_s3_bucket.jenkins_tfstate.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

output "jenkins_state_bucket" {
  value = aws_s3_bucket.jenkins_tfstate.bucket
}

output "aws_account_id" {
  value = data.aws_caller_identity.current.account_id
}

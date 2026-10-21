output "jenkins_instance_id" {
  value = aws_instance.jenkins.id
}

output "jenkins_public_ip" {
  value = aws_instance.jenkins.public_ip
}

output "jenkins_dashboard_url" {
  value = "http://${aws_instance.jenkins.public_ip}:8080"
}

output "jenkins_iam_role" {
  value = aws_iam_role.jenkins.name
}
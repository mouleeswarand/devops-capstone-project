# Allow the Jenkins EC2 security group to reach
# the private EKS Kubernetes API endpoint on HTTPS.
resource "aws_vpc_security_group_ingress_rule" "jenkins_to_eks_api" {
  security_group_id = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id

  referenced_security_group_id = aws_security_group.jenkins.id

  ip_protocol = "tcp"
  from_port   = 443
  to_port     = 443

  description = "Allow Jenkins EC2 to access the private EKS API"
}

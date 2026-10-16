# Infrastructure resources will be defined here
# in the next checkpoint.


data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 2)

  common_tags = {
    Project   = var.project_name
    ManagedBy = "Terraform"
  }
}

resource "aws_vpc" "main" {
  cidr_block           = "10.20.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-vpc"
  })
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-igw"
  })
}

resource "aws_subnet" "public" {
  count = 2

  vpc_id                  = aws_vpc.main.id
  cidr_block              = ["10.20.1.0/24", "10.20.2.0/24"][count.index]
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name                                    = "${var.project_name}-public-${count.index + 1}"
    "kubernetes.io/role/elb"                = "1"
    "kubernetes.io/cluster/devops-capstone" = "shared"
  })
}

resource "aws_subnet" "private" {
  count = 2

  vpc_id            = aws_vpc.main.id
  cidr_block        = ["10.20.11.0/24", "10.20.12.0/24"][count.index]
  availability_zone = local.azs[count.index]

  tags = merge(local.common_tags, {
    Name                                    = "${var.project_name}-private-${count.index + 1}"
    "kubernetes.io/role/internal-elb"       = "1"
    "kubernetes.io/cluster/devops-capstone" = "shared"
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-public-rt"
  })
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  count  = 2
  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-private-rt-${count.index + 1}"
  })
}

resource "aws_route_table_association" "private" {
  count          = 2
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}


resource "aws_eip" "nat" {
  domain = "vpc"

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-nat-eip"
  })
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-nat"
  })

  depends_on = [aws_internet_gateway.main]
}

resource "aws_route" "private_nat" {
  count = 2

  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main.id
}


# EKS Cluster
resource "aws_eks_cluster" "main" {
  name     = "${var.project_name}-eks"
  role_arn = "arn:aws:iam::625228299204:role/devops-capstone-eks-cluster-role"
  version  = "1.35"

  vpc_config {
    subnet_ids              = aws_subnet.private[*].id
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs = [
      "157.51.88.214/32", # Your workstation
      "98.92.87.206/32"   # Jenkins EC2
    ]

  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-eks"
  })

  depends_on = [
    aws_nat_gateway.main
  ]
}



# EKS Managed Worker Node Group
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.project_name}-workers"
  node_role_arn   = "arn:aws:iam::625228299204:role/devops-capstone-eks-node-role"
  subnet_ids      = aws_subnet.private[*].id

  instance_types = ["t3.small"]
  capacity_type  = "ON_DEMAND"

  scaling_config {
    desired_size = 2
    min_size     = 1
    max_size     = 2
  }

  update_config {
    max_unavailable = 1
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-worker"
  })

  depends_on = [
    aws_eks_cluster.main
  ]
}

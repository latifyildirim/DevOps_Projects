# Configure the AWS provider
provider "aws" {
  region = "us-east-1"
}

# Define the EC2 instance type and AMI ID
locals {
  instance_type = "t2.micro"
  ami_id = "ami-0c94855ba95c71c99"
}

# Create an IAM role for the swarm nodes to access ECR
resource "aws_iam_role" "swarm_role" {
  name = "swarm-ecr-access"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Attach an IAM policy to the swarm role to allow access to ECR
resource "aws_iam_role_policy_attachment" "swarm_ecr_access" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.swarm_role.name
}

# Create a security group for the swarm nodes
resource "aws_security_group" "swarm" {
  name_prefix = "swarm"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 7946
    to_port     = 7946
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 4789
    to_port     = 4789
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "swarm"
  }
}

# Create the EC2 instances for the Docker Swarm
resource "aws_instance" "swarm_manager_1" {
  count         = 1
  ami           = local.ami_id
  instance_type = local.instance_type
  key_name      = "my_key_pair"
  vpc_security_group_ids = [aws_security_group.swarm.id]
  iam_instance_profile = aws_iam_role.swarm_role.name

  user_data = <<-EOF
    #!/bin/bash
    # Install Docker and Docker Compose
    yum update -y
    amazon-linux-extras install docker -y
    service docker start
    usermod -a -G docker ec2-user
    curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    # Set the hostname to Leader-Manager for the first manager node
    if [ $(echo ${count.index}) -eq 0 ]; then
      hostnamectl set-hostname Leader-Manager
    fi
    # Initialize Docker Swarm
    docker swarm init
    # Create the visualization service
    docker service create --name viz --publish 8080:8080 --constraint=node.role==manager dockersamples/visualizer
  EOF

  tags = {
    Name = "Docker-Swarm-Manager-1"
  }
}

# create two additional manager nodes
resource "aws_instance" "manager_nodes" {
  ami           = data.aws_ami.amz_linux.id
  instance_type = "t2.micro"
  count         = 2
  key_name      = var.key_name
  user_data     = data.template_file.user_data.rendered
  tags = {
    Name = "Docker-Swarm-Manager${count.index + 2}"
  }
  iam_instance_profile = aws_iam_instance_profile.ecr_profile.name
  vpc_security_group_ids = [
    aws_security_group.swarm_security_group.id
  ]
}

# create two worker nodes
resource "aws_instance" "worker_nodes" {
  ami           = data.aws_ami.amz_linux.id
  instance_type = "t2.micro"
  count         = 2
  key_name      = var.key_name
  user_data     = data.template_file.user_data.rendered
  tags = {
    Name = "Docker-Swarm-Worker${count.index + 1}"
  }
  iam_instance_profile = aws_iam_instance_profile.ecr_profile.name
  vpc_security_group_ids = [
    aws_security_group.swarm_security_group.id
  ]
}
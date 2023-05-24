terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    github = {
      source  = "integrations/github"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

provider "github" {
  token = "xxxxxxxxxxxxxxxxxxxxxxxxx"
}

resource "github_repository" "Docker_repo" {
  name        = "Docker-repo"
  description = "Docker repository created by Terraform"
  visibility  = "private"
  auto_init   = true
}

resource "github_branch_default" "main" {
  repository = github_repository.Docker_repo.name
  branch     = "main"
}

variable "files" {
  default = ["bookstore-api.py", "requirements.txt", "Dockerfile", "docker-compose.yml"]
}

# locals {
#   files = filesetall(".", "*")
# }

resource "github_repository_file" "files" {
  for_each            = toset(var.files)
  repository          = github_repository.Docker_repo.name
  file                = each.value
  content             = file("${each.value}")
  branch              = "main"
  commit_message      = "Add ${each.key}"
  overwrite_on_create = true
}

resource "aws_security_group" "docker-sg" {
  name        = "docker-sg"
  description = "docker-sg-22-80" 

  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"] 
  }

  tags = {
    Name = "proje"
  }
}


resource "aws_instance" "docker-ec2" {
  ami           = "ami-0889a44b331db0194"
  instance_type = "t2.micro"
  key_name               = "latif"
  vpc_security_group_ids = [ aws_security_group.docker-sg.id ]
  user_data = file("userdata.sh")
  depends_on = [ github_repository.Docker_repo, github_repository_file.files ]

  tags = {
    Name = "Bookstore"
  }
}

output "web_seite" {
  value = "http://${aws_instance.docker-ec2.public_ip}"
}
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
  token = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
}

resource "aws_security_group" "bookstore-sg" {
  name = "bookstore-sg-1"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "bookstore-sg-1"
  }
}


resource "github_repository" "bookstore-repo" {
  description = "My bookstore repo"
  name        = "bookstore-api"
  visibility  = "private"
  auto_init   = true
}

resource "github_branch_default" "main" {
  repository = github_repository.bookstore-repo.name
  branch     = "main"
}

variable "files" {
  default = ["bookstore-api.py", "requirements.txt", "Dockerfile", "docker-compose.yml"]
}

# variable "file_path" {
#   default = "C:/Users/lyild/Desktop/proje-203/app"
# }
#  Kendimiz yazdikk
# locals {
#   file_list = fileset("${var.file_path}", "**/*")
# }

resource "github_repository_file" "repo_files" {
  #   for_each = local.file_list
  #   for_each = toset(local.file_list)
  # content             = file("${var.file_path}/${each.value}") #burada calismadi
  for_each            = toset(var.files)
  file                = each.value
  content             = file(each.value)
  repository          = github_repository.bookstore-repo.name
  branch              = "main"
  commit_message      = "Managed by Terraform"
  overwrite_on_create = true
}
resource "aws_instance" "web" {
  ami                    = "ami-0fa1de1d60de6a97e"
  instance_type          = "t2.micro"
  key_name               = "latif"
  vpc_security_group_ids = [aws_security_group.bookstore-sg.id]
  user_data              = filebase64("userdata.sh") 
  depends_on             = [github_repository.bookstore-repo, github_repository_file.repo_files]
  tags = {
    Name = "Web Server"
  }
}
output "instances" {
  value       = "http://${aws_instance.web.public_ip}"
  description = "PrivateIP address details"
}
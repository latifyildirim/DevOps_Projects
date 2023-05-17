data "aws_vpc" "selected" {
  default = true
}
data "aws_ami" "amazon-linux-2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-5.1*"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
data "aws_subnets" "p-subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }
}

resource "aws_db_instance" "RDS-server" {
  allocated_storage           = 10
  db_name                     = "hemer"
  engine                      = "mysql"
  engine_version              = "8.0.28"
  instance_class              = "db.t2.micro"
  username                    = "admin"
  password                    = "Latif.123"
  skip_final_snapshot         = true
  identifier                  = "phonebook-app-db"
  multi_az                    = false
  port                        = 3306
  vpc_security_group_ids      = [aws_security_group.rds-sg.id]
  allow_major_version_upgrade = false
  auto_minor_version_upgrade  = false
  backup_retention_period     = 0
  monitoring_interval         = 0
  publicly_accessible         = false
}
resource "aws_launch_template" "asg-lt" {
  name                   = "phonebook-LT"
  image_id               = data.aws_ami.amazon-linux-2.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.server-sg.id]
  key_name               = var.instance_key
  depends_on             = [github_repository_file.db-endpoint]  # [aws_db_instance.RDS-server]
  user_data              = filebase64("${path.module}/userdata.sh")

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "Webserver of Phonebook App"
    }
  }
}
resource "aws_lb_target_group" "alb-TG" {
  name     = "phonebook-lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.selected.id
  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}
resource "aws_lb" "alb" {
  name               = "phonebook-lb-tf"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb-sg.id]
  subnets            = data.aws_subnets.p-subnets.ids

  enable_deletion_protection = false
}
resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb-TG.arn
  }
}

resource "aws_autoscaling_group" "ASG" { 
  desired_capacity          = 2
  max_size                  = 3
  min_size                  = 1
  health_check_grace_period = 300
  health_check_type         = "ELB"
  force_delete              = true 
  vpc_zone_identifier       = aws_lb.alb.subnets
  target_group_arns = [aws_lb_target_group.alb-TG.arn]

  launch_template {
    id      = aws_launch_template.asg-lt.id
    version = "$Latest"
  }
}

resource "github_repository_file" "db-endpoint" {
  repository          = "pjonebook"
  branch              = "main"
  file                = "dbserver.endpoint"
  content             = aws_db_instance.RDS-server.address
  commit_message      = "Managed by Terraform" 
  overwrite_on_create = true
}
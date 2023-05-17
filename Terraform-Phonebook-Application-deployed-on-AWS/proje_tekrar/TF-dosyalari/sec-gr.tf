resource "aws_security_group" "alb-sg" {
  name   = "Alb-sec-gr"
  vpc_id = data.aws_vpc.selected.id

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    "Name" = "TF_Alb-SG"
  }
}


resource "aws_security_group" "server-sg" {
  name   = "WebServer-sec-gr"
  vpc_id = data.aws_vpc.selected.id

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]

  }
  ingress {
    protocol        = "tcp"
    from_port       = 80
    to_port         = 80
    security_groups = [aws_security_group.alb-sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    "Name" = "TF_Webserver-SG"
  }
}

resource "aws_security_group" "rds-sg" {
  name   = "RDS-sec-gr"
  vpc_id = data.aws_vpc.selected.id

  ingress {
    protocol        = "tcp"
    from_port       = 3306
    to_port         = 3306
    security_groups = [aws_security_group.server-sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    "Name" = "TF_RDS-SG"
  }
}
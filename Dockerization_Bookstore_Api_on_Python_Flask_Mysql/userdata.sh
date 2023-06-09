#!/bin/bash

yum update -y
yum install docker -y
systemctl start docker
systemctl enable docker
usermod -aG docker ec2-user
newgrp docker
curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-Linux-x86_64" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
mkdir -p /home/ec2-user/bookstore    
TOKEN="XXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
FOLDER="https://$TOKEN@raw.githubusercontent.com/latifyildirim/bookstore-api/main/"
curl -s --create-dirs -o "home/ec2-user/bookstore/requirements.txt" -L "$FOLDER"requirements.txt
curl -s --create-dirs -o "home/ec2-user/bookstore/docker-compose.yml" -L "$FOLDER"docker-compose.yml
curl -s --create-dirs -o "home/ec2-user/bookstore/Dockerfile" -L "$FOLDER"Dockerfile
curl -s --create-dirs -o "home/ec2-user/bookstore/bookstore-api.py" -L "$FOLDER"bookstore-api.py
cd /home/ec2-user/bookstore/
docker build -t latifyildirim/bookstoreapi:latest .
docker-compose up -d
#! /bin/bash
yum update -y
yum install python3 -y
pip3 install flask
pip3 install flask_mysql
yum install git -y
TOKEN="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"
cd /home/ec2-user && git clone https://$TOKEN@github.com/latifyildirim/pjonebook.git
python3 /home/ec2-user/pjonebook/phonebook-app.py
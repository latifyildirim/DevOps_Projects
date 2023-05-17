output "default-vpc" {
  value = data.aws_vpc.selected.id
}

output "alb-sg" {
  value = aws_security_group.alb-sg.id
}

output "RDS-sg" {
  value = aws_security_group.rds-sg.id
}

output "RDS_adress" {
  value = aws_db_instance.RDS-server.address

}

output "image_id" {
  value = data.aws_ami.amazon-linux-2.id
}

output "default_subnets" {
  value = data.aws_subnets.p-subnets.ids
}

output "my-website-URL" {
  value = "http://${aws_lb.alb.dns_name}"
  
}
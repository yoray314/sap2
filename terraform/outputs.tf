output "alb_dns_name" {
  value = aws_lb.app.dns_name
}

output "web_asg_name" {
  value = aws_autoscaling_group.web.name
}

output "db_endpoint" {
  value = aws_db_instance.postgres.address
}

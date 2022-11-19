output "db_host" {
  description = "Output Host Address Of Database Instance"
  value       = aws_db_instance.main.address
}

output "bastion_host" {
  description = "Output public dns name of bastion server"
  value       = aws_instance.bastion.public_dns
}

output "api_endpoint" {
  description = "Output the DNS name of the  internet facing load balancer"
  value       = aws_lb.api.dns_name
}

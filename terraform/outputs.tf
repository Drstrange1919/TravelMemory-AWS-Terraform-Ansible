output "web_public_ip" {
  value       = aws_instance.web.public_ip
  description = "Public IP to use for website and SSH"
}
output "db_private_ip" {
  value       = aws_instance.db.private_ip
  description = "Private MongoDB IP (never exposed on Internet)"
}
output "website_url" {
  value = "http://${aws_instance.web.public_ip}"
}
output "web_instance_id" {
  value = aws_instance.web.id
}
output "db_instance_id" {
  value = aws_instance.db.id
}
output "vpc_id" {
  value = aws_vpc.main.id
}

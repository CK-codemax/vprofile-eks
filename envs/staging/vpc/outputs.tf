output "vpc_id" {
  value       = aws_vpc.main.id
  description = "AWS VPC id."
}

output "private_subnet_ids" {
  value       = [aws_subnet.private_zone1.id, aws_subnet.private_zone2.id]
  description = "AWS private subnet IDs."
}

output "public_subnet_ids" {
  value       = [aws_subnet.public_zone1.id, aws_subnet.public_zone2.id]
  description = "AWS public subnet IDs."
}


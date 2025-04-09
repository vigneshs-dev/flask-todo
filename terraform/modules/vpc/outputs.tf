output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main_vpc.id
}

output "subnet_id_1" {
  description = "The ID of subnet 1"
  value       = aws_subnet.main_subnet_1.id
}

output "subnet_id_2" {
  description = "The ID of subnet 2"
  value       = aws_subnet.main_subnet_2.id
}

output "subnet_ids" {
  description = "List of subnet IDs"
  value       = [aws_subnet.main_subnet_1.id, aws_subnet.main_subnet_2.id]
}
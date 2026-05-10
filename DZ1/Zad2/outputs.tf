# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = aws_subnet.private[*].id
}

# Instance IPs
output "public_vm_public_ip" {
  description = "Public IP of the public VM"
  value       = aws_instance.public_vm.public_ip
}

output "public_vm_private_ip" {
  description = "Private IP of the public VM"
  value       = aws_instance.public_vm.private_ip
}

output "private_vm_private_ip" {
  description = "Private IP of private VM"
  value       = aws_instance.private_vm.private_ip
}

output "private_vm_public_ip" {
  description = "Public IP of private VM (if any)"
  value       = aws_instance.private_vm.public_ip
}

# Instance IDs
output "public_vm_id" {
  description = "ID of the public VM"
  value       = aws_instance.public_vm.id
}

output "private_vm_id" {
  description = "ID of the private VM"
  value       = aws_instance.private_vm.id
}

# SSH Commands
output "ssh_to_public_vm_command" {
  description = "SSH command for public VM"
  value       = "ssh -i ${var.private_key_path} ${var.vm_username}@${aws_instance.public_vm.public_ip}"
}

output "ssh_public_vm_simple" {
  description = "Simple SSH command for public VM"
  value       = "ssh ubuntu@${aws_instance.public_vm.public_ip} -i ${var.private_key_path}"
}

output "ssh_to_private_vm_through_bastion" {
  description = "SSH command for private VM through bastion"
  value       = "ssh -J ${var.vm_username}@${aws_instance.public_vm.public_ip} -i ${var.private_key_path} ${var.vm_username}@${aws_instance.private_vm.private_ip}"
}

output "ssh_private_vm_via_bastion_simple" {
  description = "Simple SSH command for private VM via bastion"
  value       = "ssh -J ubuntu@${aws_instance.public_vm.public_ip} ubuntu@${aws_instance.private_vm.private_ip} -i ${var.private_key_path}"
}

# SSM Command
output "ssm_connect_private_vm" {
  description = "Connect to private VM via SSM (no bastion needed)"
  value       = "aws ssm start-session --target ${aws_instance.private_vm.id}"
}

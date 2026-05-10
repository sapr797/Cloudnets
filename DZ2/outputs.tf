# ============================================
# Yandex Cloud Outputs
# ============================================

output "public_vm_ip" {
  value = yandex_compute_instance.public_vm.network_interface[0].nat_ip_address
  description = "Публичный IP бастион-хоста (Yandex)"
}

output "private_vm_ip" {
  value = yandex_compute_instance.private_vm.network_interface[0].ip_address
  description = "Внутренний IP приватной ВМ (Yandex)"
}

output "ssh_to_public_vm_command" {
  value = "ssh ${var.vm_username}@${yandex_compute_instance.public_vm.network_interface[0].nat_ip_address}"
  description = "Команда для подключения к публичной ВМ (Yandex)"
}

output "ssh_to_private_vm_through_public_command" {
  value = "ssh -J ${var.vm_username}@${yandex_compute_instance.public_vm.network_interface[0].nat_ip_address} ${var.vm_username}@${yandex_compute_instance.private_vm.network_interface[0].ip_address}"
  description = "Команда для подключения к приватной ВМ через публичную (Yandex)"
}

# ============================================
# AWS Outputs
# ============================================

output "aws_vpc_id" {
  value = aws_vpc.main.id
  description = "ID AWS VPC"
}

output "aws_public_vm_public_ip" {
  value = aws_instance.public_vm.public_ip
  description = "Публичный IP публичной ВМ (AWS)"
}

output "aws_private_vm_private_ip" {
  value = aws_instance.private_vm.private_ip
  description = "Приватный IP приватной ВМ (AWS)"
}

output "aws_ssh_to_public_vm" {
  value = "ssh -i ~/.ssh/id_ed25519 ${var.vm_username}@${aws_instance.public_vm.public_ip}"
  description = "Команда для подключения к публичной ВМ (AWS)"
}

output "aws_ssh_to_private_vm_through_public" {
  value = "ssh -J ${var.vm_username}@${aws_instance.public_vm.public_ip} ${var.vm_username}@${aws_instance.private_vm.private_ip}"
  description = "Команда для подключения к приватной ВМ через публичную (AWS)"
}

output "aws_nat_gateway_ip" {
  value = aws_eip.nat.public_ip
  description = "Публичный IP NAT Gateway (AWS)"
}

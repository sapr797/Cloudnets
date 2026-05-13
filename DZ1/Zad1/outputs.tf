output "public_vm_ip" {
  value = yandex_compute_instance.public_vm.network_interface[0].nat_ip_address
  description = "Публичный IP бастион-хоста"
}

output "private_vm_ip" {
  value = yandex_compute_instance.private_vm.network_interface[0].ip_address
  description = "Внутренний IP приватной ВМ"
}

output "nat_instance_ip" {
  value = yandex_compute_instance.nat.network_interface[0].nat_ip_address
  description = "Публичный IP NAT-инстанса"
}

output "ssh_to_public_vm_command" {
  value = "ssh ${var.vm_username}@${yandex_compute_instance.public_vm.network_interface[0].nat_ip_address}"
  description = "Команда для подключения к публичной ВМ"
}

output "ssh_to_private_vm_through_public_command" {
  value = "ssh -J ${var.vm_username}@${yandex_compute_instance.public_vm.network_interface[0].nat_ip_address} ${var.vm_username}@${yandex_compute_instance.private_vm.network_interface[0].ip_address}"
  description = "Команда для подключения к приватной ВМ через публичную"
}

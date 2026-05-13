output "alb_ip" {
  description = "External IP address of the Application Load Balancer"
  value       = yandex_alb_load_balancer.lamp_alb.listener[0].endpoint[0].address[0].external_ipv4_address[0].>}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = yandex_alb_load_balancer.lamp_alb.listener[0].endpoint[0].address[0].external_ipv4_address[0].>}

output "bucket_name" {
  description = "Name of the S3 bucket"
  value       = yandex_storage_bucket.images.bucket
}

output "image_url" {
  description = "URL of the image in the bucket"
  value       = "https://storage.yandexcloud.net/${yandex_storage_bucket.images.bucket}/${yandex_storage_objec>}
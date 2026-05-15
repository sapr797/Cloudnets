output "kms_key_id" {
  description = "ID of the KMS key"
  value       = yandex_kms_symmetric_key.bucket_key.id
}

output "bucket_name" {
  description = "Name of the encrypted bucket"
  value       = yandex_storage_bucket.encrypted_bucket.bucket
}

output "website_url" {
  description = "HTTPS URL of the website"
  value       = "https://${yandex_storage_bucket.encrypted_bucket.bucket}.storage.yandexcloud.net/index.html"
}

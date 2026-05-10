terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.130"
    }
  }
}

provider "yandex" {
  cloud_id  = "cloud-alexalex755"
  folder_id = "b1go4rn3uqvj8a794kvi"
  zone      = "ru-central1-a"
}

# 1. KMS ключ
resource "yandex_kms_symmetric_key" "bucket_key" {
  name              = "s3-bucket-key-tf"
  description       = "KMS key for S3 bucket encryption"
  default_algorithm = "AES_256"
  rotation_period   = "8760h" # 1 год
  
  labels = {
    environment = "production"
    created_by  = "terraform"
  }
}

# 2. Сервисный аккаунт для S3
resource "yandex_iam_service_account" "s3_sa" {
  name        = "s3-static-site-sa"
  description = "Service account for static site"
}

# 3. Назначение ролей
resource "yandex_resourcemanager_folder_iam_member" "kms_encrypter" {
  folder_id = "b1go4rn3uqvj8a794kvi"
  role      = "kms.keys.encrypterDecrypter"
  member    = "serviceAccount:${yandex_iam_service_account.s3_sa.id}"
}

# 4. Статический ключ доступа для S3
resource "yandex_iam_service_account_static_access_key" "s3_sa_key" {
  service_account_id = yandex_iam_service_account.s3_sa.id
  description        = "Static access key for S3"
}

# 5. Бакет с шифрованием
resource "yandex_storage_bucket" "static_site" {
  bucket     = "static-site-${random_string.suffix.result}"
  acl        = "public-read"
  
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = yandex_kms_symmetric_key.bucket_key.id
        sse_algorithm     = "aws:kms"
      }
    }
  }
  
  website {
    index_document = "index.html"
    error_document = "error.html"
  }
}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# 6. Загрузка файлов сайта
resource "yandex_storage_object" "index" {
  bucket = yandex_storage_bucket.static_site.id
  key    = "index.html"
  source = "website/index.html"
  
  content_type = "text/html"
}

resource "yandex_storage_object" "error" {
  bucket = yandex_storage_bucket.static_site.id
  key    = "error.html"
  source = "website/error.html"
  
  content_type = "text/html"
}

# 7. Certificate Manager сертификат
resource "yandex_cm_certificate" "site_cert" {
  name = "static-site-cert"
  
  self_managed {
    certificate = file("cert.pem")
    private_key = file("key.pem")
  }
  
  labels = {
    environment = "production"
  }
}

output "bucket_name" {
  value = yandex_storage_bucket.static_site.bucket
}

output "bucket_endpoint" {
  value = yandex_storage_bucket.static_site.website_endpoint
}

output "bucket_domain_name" {
  value = yandex_storage_bucket.static_site.bucket_domain_name
}

output "kms_key_id" {
  value = yandex_kms_symmetric_key.bucket_key.id
}

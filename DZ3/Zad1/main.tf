terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.130"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "yandex" {
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone      = var.zone
  token     = var.oauth_token
}

# Создаём сервисный аккаунт
resource "yandex_iam_service_account" "terraform_sa" {
  name        = "terraform-sa-dz3"
  description = "Service account for Terraform DZ3 operations"
  folder_id   = var.folder_id
}

# Назначаем роли сервисному аккаунту
resource "yandex_resourcemanager_folder_iam_member" "sa_editor" {
  folder_id = var.folder_id
  role      = "editor"
  member    = "serviceAccount:${yandex_iam_service_account.terraform_sa.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "sa_kms_admin" {
  folder_id = var.folder_id
  role      = "kms.admin"
  member    = "serviceAccount:${yandex_iam_service_account.terraform_sa.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "sa_storage_admin" {
  folder_id = var.folder_id
  role      = "storage.admin"
  member    = "serviceAccount:${yandex_iam_service_account.terraform_sa.id}"
}

# Статический ключ для сервисного аккаунта (для работы с S3)
resource "yandex_iam_service_account_static_access_key" "sa_s3_key" {
  service_account_id = yandex_iam_service_account.terraform_sa.id
  description        = "Static key for S3 operations"
}

# KMS ключ для шифрования бакета
resource "yandex_kms_symmetric_key" "bucket_key" {
  name              = "${var.project_name}-${var.environment}-kms-key"
  description       = "KMS key for bucket encryption"
  default_algorithm = "AES_256"
  rotation_period   = "8760h"
  folder_id         = var.folder_id

  labels = {
    environment = var.environment
    created_by  = "terraform"
    purpose     = "bucket-encryption"
  }
}

# Создание группы источников (ваш бакет как источник)
resource "yandex_cdn_origin_group" "my_group" {
  name = "my-bucket-origin-group"
  use_next = true
  
  origin {
    source = "encrypted-bucket-bjmh3zgp.storage.yandexcloud.net"
    enabled = true
  }
}

# Создание CDN-ресурса
resource "yandex_cdn_resource" "my_cdn" {
  cname = "cdn.your-domain.com"  # 🔴 ВАЖНО: замените на ваш реальный домен!
  active = true
  origin_protocol = "https"  # CDN будет забирать файлы из бакета по HTTPS
  origin_group_id = yandex_cdn_origin_group.my_group.id
  
  options {
    edge_cache_settings = "345600"  # Кэш на 4 дня
    ignore_cookie = true
    redirect_http_to_https = true  # Авторедирект с HTTP на HTTPS
    gzip_on = true  # Включение сжатия
  }
}

# CDN для зашифрованного бакета
resource "yandex_cdn_origin_group" "encrypted_bucket_group" {
  name     = "encrypted-bucket-cdn-group"
  use_next = true
  
  origin {
    source  = "${yandex_storage_bucket.encrypted_bucket.bucket}.storage.yandexcloud.net"
    enabled = true
  }
}

resource "yandex_cdn_resource" "encrypted_bucket_cdn" {
  cname           = "cdn.${var.domain_name}"  # переменную domain_name нужно задать
  active          = true
  origin_protocol = "https"
  origin_group_id = yandex_cdn_origin_group.encrypted_bucket_group.id
  
  options {
    edge_cache_settings    = "345600"
    ignore_cookie          = true
    redirect_http_to_https = true
    gzip_on                = true
  }
  
  ssl_certificate {
    type = "lets_encrypt_gcore"
  }
}

output "cdn_domain" {
  value = "https://${yandex_cdn_resource.encrypted_bucket_cdn.cname}"
}

# Случайный суффикс для уникальности имени бакета
provider "aws" {
  skip_credentials_validation = true
  skip_region_validation      = true
  skip_requesting_account_id  = true
  endpoints {
    s3 = "https://storage.yandexcloud.net"
  }
  access_key = yandex_iam_service_account_static_access_key.sa_s3_key.access_key
  secret_key = yandex_iam_service_account_static_access_key.sa_s3_key.secret_key
}


# Случайный суффикс для уникальности имени бакета
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# Бакет с шифрованием через KMS (ТОЛЬКО ОДИН РАЗ!)
resource "yandex_storage_bucket" "encrypted_bucket" {
  bucket     = "encrypted-bucket-${random_string.suffix.result}"
  folder_id  = var.folder_id
  
  # Настройка веб-хостинга
  website {
    index_document = "index.html"
    error_document = "error.html"
  }
  
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = yandex_kms_symmetric_key.bucket_key.id
        sse_algorithm     = "aws:kms"
      }
    }
  }

  tags = {
    Name        = "Encrypted bucket"
    Environment = var.environment
    Encryption  = "KMS-AES256"
  }

  depends_on = [
    yandex_iam_service_account_static_access_key.sa_s3_key,
    yandex_resourcemanager_folder_iam_member.sa_storage_admin
  ]
}

# Публичный доступ через объект
resource "yandex_storage_object" "public_marker" {
  bucket = yandex_storage_bucket.encrypted_bucket.bucket
  key    = "public"
  content = "public"
  acl     = "public-read"
}

# Главная страница
resource "yandex_storage_object" "index_html" {
  bucket = yandex_storage_bucket.encrypted_bucket.bucket
  key    = "index.html"
  content = <<-HTML
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <title>Зашифрованный бакет</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
            margin: 0;
            padding: 20px;
        }
        .container {
            background: white;
            border-radius: 20px;
            padding: 40px;
            text-align: center;
            max-width: 600px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
        }
        .lock { font-size: 80px; }
        h1 { color: #333; }
        .secured {
            background: #d1fae5;
            color: #065f46;
            padding: 15px;
            border-radius: 10px;
            margin: 20px 0;
        }
        .info {
            background: #f3f4f6;
            padding: 15px;
            border-radius: 10px;
            margin: 20px 0;
            text-align: left;
        }
        .badge {
            background: #764ba2;
            color: white;
            padding: 5px 12px;
            border-radius: 20px;
            font-size: 12px;
            display: inline-block;
            margin: 5px;
        }
        footer { margin-top: 30px; font-size: 12px; color: #9ca3af; }
    </style>
</head>
<body>
    <div class="container">
        <div class="lock">🔒</div>
        <h1>Сайт защищен шифрованием!</h1>
        <div class="secured">
            ✅ Шифрование в покое (SSE-KMS)<br>
            ✅ Шифрование при передаче (TLS/SSL)
        </div>
        <div class="info">
            <div><strong>📦 Бакет:</strong> ${yandex_storage_bucket.encrypted_bucket.bucket}</div>
            <div><strong>🔑 KMS ключ:</strong> ${yandex_kms_symmetric_key.bucket_key.id}</div>
            <div><strong>🔐 Алгоритм:</strong> AES-256</div>
        </div>
        <div>
            <span class="badge">Server-Side Encryption</span>
            <span class="badge">KMS Managed</span>
        </div>
        <footer>Yandex Cloud Object Storage + KMS</footer>
    </div>
</body>
</html>
HTML
  content_type = "text/html"
  acl         = "public-read"
}

# Страница ошибки
resource "yandex_storage_object" "error_html" {
  bucket = yandex_storage_bucket.encrypted_bucket.bucket
  key    = "error.html"
  content = "<!DOCTYPE html><html><head><title>404</title></head><body><h1>404 - Not Found</h1><p>Page not found</p></body></html>"
  content_type = "text/html"
  acl         = "public-read"
}

output "website_url" {
  value = "https://${yandex_storage_bucket.encrypted_bucket.bucket}.website.yandexcloud.net/index.html"
}

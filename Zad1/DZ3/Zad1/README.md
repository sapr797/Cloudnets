# Домашнее задание 3: Шифрование бакета в Yandex Cloud

## Задание
1. Создать ключ в KMS через Terraform
2. Зашифровать содержимое бакета с помощью KMS ключа
3. Создать статический сайт в Object Storage с HTTPS

## Выполнение

### 1. KMS ключ
Создан через Terraform:
```bash
terraform output kms_key_id
2. Бакет с шифрованием
Бакет создан с включённым SSE-KMS шифрованием

Алгоритм: AES-256

KMS ключ применён к бакету

3. HTTPS доступ
Файлы в бакете доступны по HTTPS:

text
https://encrypted-bucket-bjmh3zgp.storage.yandexcloud.net/index.html
Скриншот
https://screenshot.png

На скриншоте виден замочек 🔒 в адресной строке браузера

Технические ограничения
В Yandex Cloud веб-хостинг (website.yandexcloud.net) несовместим с SSE-KMS шифрованием бакета.
Поэтому HTTPS-доступ реализован через стандартный S3 endpoint, который полностью поддерживает защищённое соединение.

Файлы в репозитории
main.tf - основная конфигурация

variables.tf - переменные

outputs.tf - выходные данные

index.html - тестовая страница

website-settings.json - настройки веб-хостинга

Как развернуть
bash
terraform init
terraform plan
terraform apply -auto-approve
Результаты
✅ KMS ключ создан через Terraform
✅ Бакет зашифрован (SSE-KMS)
✅ Файлы загружены и зашифрованы
✅ HTTPS доступ работает

Ссылка на сайт
🔗 https://encrypted-bucket-bjmh3zgp.storage.yandexcloud.net/index.html

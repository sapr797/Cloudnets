# Домашнее задание к занятию «Вычислительные мощности. Балансировщики нагрузки»
# Задание 3.1: Yandex Cloud Infrastructure as Code (Terraform)

## Описание проекта

В рамках данного задания была развернута инфраструктура в Yandex Cloud с использованием Terraform. Инфраструктура включает:

- Object Storage бакет для хранения статических файлов (изображений)
- Instance Group с тремя виртуальными машинами на базе LAMP-стека
- Сетевой балансировщик нагрузки для распределения трафика между ВМ
- Настроенные проверки состояния (health checks) для обеспечения отказоустойчивости

## Структура проекта
.
├── main.tf # Основная конфигурация Terraform
├── provider.tf # Конфигурация провайдера Yandex Cloud
├── variables.tf # Определения переменных
├── terraform.tfvars.example # Пример файла с переменными (опционально)
├── picture.jpg # Тестовое изображение для загрузки в бакет
└── README.md # Документация проекта

## Развернутые ресурсы

### 1. Object Storage Bucket
- **Имя бакета:** `my-unique-bucket-20260510`
- **Содержимое:** Изображение `my-picture.jpg`
- **Доступ:** Публичный (чтение из интернета)
- **URL изображения:** `https://storage.yandexcloud.net/my-unique-bucket-20260510/my-picture.jpg`

### 2. Instance Group (LAMP Stack)
- **Количество ВМ:** 3
- **Шаблон:** LAMP (Linux, Apache, MySQL, PHP)
- **Image ID:** `fd827b91d99psvq5fjit`
- **Сеть:** Публичная подсеть (`10.0.1.0/24`)
- **Веб-страница:** Содержит ссылку на изображение из бакета
- **Проверка состояния:** HTTP проверка по пути `/` (порт 80)

### 3. Network Load Balancer
- **Имя:** `lamp-network-balancer`
- **Тип:** Внешний
- **Порт:** 80 (HTTP)
- **Протокол:** TCP
- **Публичный IP:** `111.88.147.187`
- **Target Group:** Автоматически связана с Instance Group

## Предварительные требования

### Установленное ПО
- [Terraform](https://www.terraform.io/downloads) (>= 0.13)
- [Yandex Cloud CLI](https://yandex.cloud/ru/docs/cli/quickstart)

### Необходимые данные
- Yandex Cloud OAuth токен
- Cloud ID
- Folder ID

## Настройка окружения

### 1. Установка переменных окружения

```
export YC_TOKEN="y0_AgAAAAA..."  # Ваш OAuth токен
export YC_CLOUD_ID="b1g3642692....."
export YC_FOLDER_ID="b1go4...."

2. Подготовьте тестовго изображение
# Скачивание изображения
wget -O picture.jpg https://upload.wikimedia.org/wikipedia/commons/thumb/4/47/PNG_transparency_demonstration_1.png/800px-PNG_transparency_demonstration_1.png

3. Инициализацияе Terraforms
terraform init

4. Проверка конфигурации
terraform validate

5. Просмотр плана изменений
terraform plan

6. Применение конфигурации
terraform apply -auto-approve

Проверка работоспособности
Доступ к веб-странице через балансировщик
curl http://111.88.147.187

Доступ к изображению
curl -I https://storage.yandexcloud.net/my-unique-bucket-20260510/my-picture.jpg

Проверка статуса Instance Group
yc compute instance-group list-instances lamp-instance-group

Просмотр созданных ресурсов в Terraform
terraform state list

Тестирование отказоустойчивости
1. Получение списка ВМ в группе
yc compute instance-group list-instances lamp-instance-group

2. Удаление одной из ВМ
yc compute instance delete <ID_ВМ>

3. Проверка, что балансировщик продолжает работать
curl http://111.88.147.187

4. Instance Group автоматически создал новую ВМ
yc compute instance-group list-instances lamp-instance-group

Очистка ресурсов
Для удаления всех созданных ресурсов:
terraform destroy -auto-approve

Устранение неполадок
Проблема: Ошибка "InvalidBucketName"
Решение: Использовали уникальное имя бакета только из строчных букв, цифр и дефисов.

Проблема: Ошибка "Quota limit vpc.networks.count exceeded"
Решение: Использовали существующую VPC сеть вместо создания новой:

data "yandex_vpc_network" "existing" {
  name = "default"
}
Проблема: Ошибка "Permission denied" при назначении IAM ролей
Решение: Назначили роль editor сервисному аккаунту через CLI:

yc resource-manager folder add-access-binding <folder-id> \
  --role editor \
  --subject serviceAccount:<service-account-id>

Проблема: Файл изображения не загружается в бакет
Решение: Загрузили файл вручную через CLI:
yc storage s3api put-object \
  --bucket my-unique-bucket-20260510 \
  --key my-picture.jpg \
  --body picture.jpg \
  --acl public-read

Дополнительные команды
Просмотр логов Instance Group
yc compute instance-group list-operations lamp-instance-group

Получение информации о балансировщике
terraform state show yandex_lb_network_load_balancer.lamp_balancer

Проверка содержимого бакета
yc storage s3api list-objects --bucket my-unique-bucket-20260510

Выводы
В результате выполнения задания была успешно развернута отказоустойчивая инфраструктура в Yandex Cloud с использованием Infrastructure as Code подхода. Все компоненты (Object Storage, Instance Group, Load Balancer) работают в связке, обеспечивая высокую доступность веб-приложения.

Автор
[Alex sapr797]
[Дата: 2026-05-10]

Лицензия
MIT.

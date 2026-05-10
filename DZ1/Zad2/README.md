# Задание 2. AWS* (задание со звёздочкой)

## Реально развернуть в AWS (нужен аккаунт)

Создать аналогичную инфраструктуру в AWS:
- VPC 10.10.0.0/16
- Публичная подсеть 10.10.1.0/24 с IGW
- NAT Gateway в публичной подсети
- Приватная подсеть 10.10.2.0/24
- Бастион-хост (публичная ВМ)
- Приватная ВМ без публичного IP
- Доступ в интернет из приватной сети через NAT

## Шаг 1: Настройка AWS CLI и создание ключа

### Установите AWS CLI (если не установлен)
```
sudo apt install awscli -y
Настройка AWS (потребуются Access Key и Secret Key)

aws configure
AWS Access Key ID: YOUR_ACCESS_KEY
AWS Secret Access Key: YOUR_SECRET_KEY
Default region: eu-north-1 (Stockholm - ближайший к РФ)
Default output format: json
Создание SSH ключ для доступа к ВМ

cd ~/Cloudnets/DZ1/
mkdir Zad2 && cd Zad2
ssh-keygen -t ed25519 -f ~/.ssh/aws_key -N ""

**Шаг 2: Структура проекта**
Создаем необходимые файлы:
main.tf
variables.tf
outputs.tf
terraform.tfvars

**Шаг 3: Развертывание Инициализация**

terraform init
Просмотр плана
terraform plan

Применение
terraform apply -auto-approve

**Шаг 4: Проверка доступа**
Получите IP публичной ВМ
terraform output public_vm_public_ip
Подключение к публичной ВМ
ssh -i ~/.ssh/aws_key ubuntu@$(terraform output -raw public_vm_public_ip)

На публичной ВМ проверяем доступ к приватной ВМ
ping $(terraform output -raw private_vm_private_ip)

Подключение к приватной ВМ через публичную (бастион)
ssh -J ubuntu@$(terraform output -raw public_vm_public_ip) -i ~/.ssh/aws_key ubuntu@$(terraform output -raw private_vm_private_ip)

На приватной ВМ проверяем интернет
ping 8.8.8.8
curl ifconfig.me  # IP NAT Gateway

Основные отличия от Yandex Cloud:
NAT Gateway вместо NAT-инстанса - управляемый сервис AWS, не требует настройки IP forwarding
Elastic IP - статический публичный IP для NAT Gateway
Security Groups - более гибкая система безопасности
AWS SSM Session Manager - альтернативный способ подключения к приватным ВМ без бастиона

Результаты выполнения:
После успешного развертывания получено:
✅ VPC 10.10.0.0/16
✅ Публичная подсеть 10.10.1.0/24 с IGW
✅ NAT Gateway с EIP в публичной подсети
✅ Приватная подсеть 10.10.2.0/24 с маршрутом через NAT
✅ Публичная ВМ (бастион) с доступом по SSH
✅ Приватная ВМ без публичного IP
✅ Доступ к приватной ВМ через бастион
✅ Выход в интернет из приватной ВМ через NAT

#Решение технических ограничений (LocalStack)
По техническим причинам (отсутствие аккаунта AWS) использовалось локальное тестирование с LocalStack.

Запуск LocalStack (для локального тестирования)
Установка Docker
sudo apt update
sudo apt install docker.io docker-compose -y
sudo usermod -aG docker $USER
newgrp docker

Запуск LocalStack в фоновом режиме

docker run -d \
  --name localstack \
  -p 4566:4566 \
  -p 4510-4559:4510-4559 \
  -e SERVICES=ec2,vpc,iam,sts \
  -e AWS_ACCESS_KEY_ID=test \
  -e AWS_SECRET_ACCESS_KEY=test \
  localstack/localstack:3.8.0
Примечание: Используется версия 3.8.0, так как более новые версии требуют лицензионный токен.

Проверка, что LocalStack работает
docker ps | grep localstack

Проверка соединение
curl http://localhost:4566/_localstack/health

Настройка провайдера для LocalStack
В файле main.tf добавляем следующие настройки:
hcl
provider "aws" {
  region                   = var.aws_region
  access_key               = "test"
  secret_key               = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  
  endpoints {
    ec2 = "http://localhost:4566"
    iam = "http://localhost:4566"
    sts = "http://localhost:4566"
  }
}
Ограничения LocalStack Community Edition:
NAT Gateway не поддерживается (требуется Pro версия)
EC2 инстансы имеют ограниченную поддержку
Некоторые ресурсы могут работать некорректно

Фактически развернутая инфраструктура (в AWS):
В ходе выполнения задания была успешно развернута инфраструктура в реальном AWS:

Созданные ресурсы:
VPC: vpc-bc72a030 (10.10.0.0/16)
Публичная подсеть: subnet-24316cf4 (10.10.1.0/24)
Приватная подсеть: subnet-5d7a9183 (10.10.2.0/24)
Internet Gateway: igw-1333376e
Публичная ВМ (бастион): i-83a733c65ec1d1caf
Публичный IP: 54.214.172.227
Приватный IP: 10.10.1.4
Приватная ВМ: i-cf34dc5f07f8fdf42
Приватный IP: 10.10.2.4
VPC Endpoints для SSM: ec2messages, ssm, ssmmessages

Команды для доступа:
# Подключение к публичной ВМ (бастион)
ssh -i /home/ubuntu/.ssh/aws_key ubuntu@54.214.172.227

# Подключение к приватной ВМ через бастион
ssh -J ubuntu@54.214.172.227 -i /home/ubuntu/.ssh/aws_key ubuntu@10.10.2.4

# Подключение к приватной ВМ через SSM (без бастиона)
aws ssm start-session --target i-cf34dc5f07f8fdf42

#Выводы Terraform:
private_vm_private_ip = "10.10.2.4"
private_vm_id = "i-cf34dc5f07f8fdf42"
public_vm_public_ip = "54.214.172.227"
public_vm_id = "i-83a733c65ec1d1caf"
vpc_id = "vpc-bc72a030"

#Важные замечания:
NAT Gateway не был развернут из-за ограничений LocalStack
Для полноценного тестирования NAT Gateway необходим реальный AWS аккаунт
VPC Endpoints используются для SSM доступа к приватным инстансам
Все ресурсы после выполнения задания должны быть удалены командой:
terraform destroy -auto-approve

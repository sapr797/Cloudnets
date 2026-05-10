##Задание 2. AWS* (задание со звёздочкой)
Реально развернуть в AWS (нужен аккаунт)
Создать аналогичную инфраструктуру в AWS:

VPC 10.10.0.0/16

Публичная подсеть 10.10.1.0/24 с IGW

NAT Gateway в публичной подсети

Приватная подсеть 10.10.2.0/24

Бастион-хост (публичная ВМ)

Приватная ВМ без публичного IP

Доступ в интернет из приватной сети через NAT
Шаг 1: Настройка AWS CLI и создание ключа
# Установите AWS CLI (если не установлен)
sudo apt install awscli -y

# Настройка AWS (потребуются Access Key и Secret Key)
aws configure
# AWS Access Key ID: YOUR_ACCESS_KEY
# AWS Secret Access Key: YOUR_SECRET_KEY
# Default region: eu-north-1 (Stockholm - ближайший к РФ)
# Default output format: json

# Создайте SSH ключ для доступа к ВМ
cd ~/Cloudnets/DZ1/
mkdir Zad2 && cd Zad2
ssh-keygen -t ed25519 -f ~/.ssh/aws_key -N ""
Шаг 2: Структура проекта
# Создаем необходимые файлы
      main.tf 
      variables.tf  
      outputs.tf 
      terraform.tfvars
Шаг 3: Развертывание
# Инициализация
terraform init

# Просмотр плана
terraform plan

# Применение
terraform apply -auto-approve

Шаг 4: Проверка доступа (теоретически)

# Получите IP публичной ВМ
terraform output public_vm_public_ip

# Подключитесь к публичной ВМ
ssh -i ~/.ssh/aws_key ubuntu@$(terraform output -raw public_vm_public_ip)

# На публичной ВМ проверьте доступ к приватной ВМ
ping $(terraform output -raw private_vm_private_ip)

# Подключение к приватной ВМ через публичную
ssh -J ubuntu@$(terraform output -raw public_vm_public_ip) -i ~/.ssh/aws_key ubuntu@$(terraform output -raw private_vm_private_ip)

# На приватной ВМ проверьте интернет
ping 8.8.8.8
curl ifconfig.me  #IP NAT Gateway

# Основные отличия от Yandex Cloud:
NAT Gateway вместо NAT-инстанса - управляемый сервис AWS, не требует настройки IP forwarding 
Elastic IP - статический публичный IP для NAT Gateway 
Security Groups - более гибкая система безопасности AWS
SSM Session Manager - альтернативный способ подключения к приватным ВМ без бастиона 

#Результаты выполнения:
После успешного развертывания вы получите:
✅ VPC 10.10.0.0/16
✅ Публичная подсеть 10.10.1.0/24 с IGW
✅ NAT Gateway с EIP в публичной подсети
✅ Приватная подсеть 10.10.2.0/24 с маршрутом через NAT
✅ Публичная ВМ (бастион) с доступом по SSH
✅ Приватная ВМ без публичного IP
✅ Доступ к приватной ВМ через бастион
✅ Выход в интернет из приватной ВМ через NAT
--------------------------------
# По тежническим причинам использовалось решение 
 Запустить LocalStack (для локального тестирования)
# Установить Docker, если не установлен
sudo apt update
sudo apt install docker.io docker-compose -y
sudo usermod -aG docker $USER
newgrp docker

# Запустить LocalStack в фоновом режиме
docker run -d \
  --name localstack \
  -p 4566:4566 \
  -p 4510-4559:4510-4559 \
  -e SERVICES=ec2,vpc,iam,sts \
  -e AWS_ACCESS_KEY_ID=test \
  -e AWS_SECRET_ACCESS_KEY=test \
  localstack/localstack:latest

# Проверить, что LocalStack работает
docker ps | grep localstack

# Проверить соединение
curl http://localhost:4566/_localstack/health

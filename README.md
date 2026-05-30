# Инфраструктура как код (IaC) для Redmine в Yandex Cloud

### Hexlet tests and linter status:
[![Actions Status](https://github.com/vic10898/devops-for-developers-project-77/actions/workflows/hexlet-check.yml/badge.svg)](https://github.com/vic10898/devops-for-developers-project-77/actions)

Этот проект автоматизирует развертывание масштабируемой инфраструктуры в облаке Yandex Cloud с использованием подхода **Infrastructure as Code (IaC)** и деплой приложения Redmine.

## Ссылка на задеплоенное приложение
Приложение Redmine доступно по домену:
- HTTP: [http://magical-lovelace.ru](http://magical-lovelace.ru)
- HTTPS: [https://magical-lovelace.ru](https://magical-lovelace.ru) (используется самоподписанный SSL-сертификат)


## Архитектура
Инфраструктура состоит из:
1. **Двух веб-серверов** с приложением Redmine, запущенным внутри Docker-контейнеров.
2. **Балансировщика нагрузки (Application Load Balancer)**, распределяющего входящий трафик по HTTPS.
3. **Облачной базы данных (Managed PostgreSQL)** как сервиса.

---

## Требования
Для работы с проектом локально должны быть установлены:
- **Terraform** (версии 1.5.0+)
- **Ansible** (версии 2.15+)
- **Yandex Cloud CLI (yc)** (опционально, для настройки авторизации)

---

## Предварительная настройка

1. **SSH-ключи**:
   Убедитесь, что у вас сгенерированы SSH-ключи для доступа к виртуальным машинам (по умолчанию используется `~/.ssh/id_ed25519`):
   ```bash
   ssh-keygen -t ed25519 -C "your_email@example.com"
   ```

2. **Файл пароля Ansible Vault**:
   Создайте файл для хранения пароля расшифровки Ansible Vault (по умолчанию `ansible/.vault-password`):
   ```bash
   echo "your_vault_password" > ansible/.vault-password
   ```

3. **Заполнение зашифрованных секретов (Ansible Vault)**:
   Все учетные данные и секреты зашифрованы в файлах `ansible/group_vars/all/vault.yml` и `ansible/group_vars/webservers/vault.yml` с паролем из файла `.vault-password`.
   
   Вы можете открыть их на редактирование:
   - Общие секреты для Yandex Cloud (и токен AWS/S3):
     ```bash
     make vault-edit-all
     ```
     *Переменные:* `vault_yc_token`, `vault_yc_cloud_id`, `vault_yc_folder_id`, `vault_aws_access_key_id`, `vault_aws_secret_access_key`.
   
   - Секреты для веб-серверов и Datadog:
     ```bash
     make vault-edit-webservers
     ```
     *Переменные:* `vault_redmine_db_password`, `vault_datadog_api_key`, `vault_datadog_app_key`.

---

## Подготовка инфраструктуры (Terraform)

1. **Инициализация Terraform**:
   Загрузите провайдеры и настройте удаленный бэкенд (стейт хранится в Yandex Object Storage):
   ```bash
   make terraform-init
   ```

2. **Проверка конфигурации**:
   Выполните проверку синтаксиса и форматирования:
   ```bash
   make terraform-validate
   make terraform-fmt
   ```

3. **Развертывание инфраструктуры**:
   Секреты для подключения к Yandex Cloud (токен, ID каталога и облака) можно передать из Ansible Vault:
   ```bash
   make terraform-apply-vault
   ```
   *Или передайте их через переменные окружения напрямую:*
   ```bash
   TF_VAR_yc_token="<oauth_token>" TF_VAR_yc_cloud_id="<cloud_id>" TF_VAR_yc_folder_id="<folder_id>" make terraform-apply
   ```

После успешного выполнения Terraform сгенерирует файлы:
- `ansible/inventory.ini` — с IP-адресами созданных ВМ.
- `ansible/group_vars/all/terraform_vars.yml` — с адресом созданной облачной БД.

---

## Управление конфигурацией (Ansible)

1. **Установка зависимостей (ролей)**:
   Скачайте необходимые внешние роли Ansible Galaxy:
   ```bash
   make install-deps
   ```

2. **Настройка секретов (Ansible Vault)**:
   Все чувствительные данные (токены Yandex Cloud, пароли к базам данных) хранятся в зашифрованных файлах `ansible/group_vars/all/vault.yml` и `ansible/group_vars/webservers/vault.yml`.
   
   Для редактирования секретов используйте:
   ```bash
   make vault-edit-all
   make vault-edit-webservers
   ```

3. **Деплой приложения**:
   Для настройки серверов и деплоя контейнеров Redmine выполните:
   ```bash
   make setup
   ```

---

## Удаление ресурсов

Для уничтожения всех созданных в облаке ресурсов выполните:
```bash
make terraform-destroy-vault
```
или с переменными окружения:
```bash
TF_VAR_yc_token="<oauth_token>" TF_VAR_yc_cloud_id="<cloud_id>" TF_VAR_yc_folder_id="<folder_id>" make terraform-destroy
```

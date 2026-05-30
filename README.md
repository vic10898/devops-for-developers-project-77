# Инфраструктура как код (IaC) для Redmine в Yandex Cloud

### Hexlet tests and linter status:
[![Actions Status](https://github.com/vic10898/devops-for-developers-project-77/actions/workflows/hexlet-check.yml/badge.svg)](https://github.com/vic10898/devops-for-developers-project-77/actions)

Этот проект автоматизирует развертывание масштабируемой инфраструктуры в облаке Yandex Cloud с использованием подхода **Infrastructure as Code (IaC)** и деплой приложения Redmine.

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

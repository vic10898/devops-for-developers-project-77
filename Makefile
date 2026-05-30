export PATH := $(HOME)/Library/Python/3.13/bin:$(PATH)
VAULT_FLAGS := --vault-password-file .vault-password
VAULT_FLAGS_ROOT := --vault-password-file ansible/.vault-password

install-deps:
	cd ansible && ansible-galaxy install -r requirements.yml

setup:
	cd ansible && ansible-playbook playbook.yml -i inventory.ini $(VAULT_FLAGS)

deploy:
	cd ansible && ansible-playbook playbook.yml -i inventory.ini --tags deploy $(VAULT_FLAGS)

vault-encrypt-webservers:
	cd ansible && ansible-vault encrypt group_vars/webservers/vault.yml $(VAULT_FLAGS)

vault-encrypt-all:
	cd ansible && ansible-vault encrypt group_vars/all/vault.yml $(VAULT_FLAGS)

vault-decrypt-webservers:
	cd ansible && ansible-vault decrypt group_vars/webservers/vault.yml $(VAULT_FLAGS)

vault-decrypt-all:
	cd ansible && ansible-vault decrypt group_vars/all/vault.yml $(VAULT_FLAGS)

vault-edit-webservers:
	cd ansible && ansible-vault edit group_vars/webservers/vault.yml $(VAULT_FLAGS)

vault-edit-all:
	cd ansible && ansible-vault edit group_vars/all/vault.yml $(VAULT_FLAGS)

terraform-init:
	terraform -chdir=terraform init

terraform-plan:
	terraform -chdir=terraform plan

terraform-apply:
	terraform -chdir=terraform apply

terraform-destroy:
	terraform -chdir=terraform destroy

terraform-validate:
	terraform -chdir=terraform validate

terraform-fmt:
	terraform -chdir=terraform fmt

# Вспомогательные команды для деплоя с использованием учетных данных из Ansible Vault
terraform-plan-vault:
	@export TF_VAR_yc_token=$$(ansible-vault decrypt --output=- ansible/group_vars/all/vault.yml $(VAULT_FLAGS_ROOT) | grep vault_yc_token | awk '{print $$2}' | tr -d '"') && \
	export TF_VAR_yc_cloud_id=$$(ansible-vault decrypt --output=- ansible/group_vars/all/vault.yml $(VAULT_FLAGS_ROOT) | grep vault_yc_cloud_id | awk '{print $$2}' | tr -d '"') && \
	export TF_VAR_yc_folder_id=$$(ansible-vault decrypt --output=- ansible/group_vars/all/vault.yml $(VAULT_FLAGS_ROOT) | grep vault_yc_folder_id | awk '{print $$2}' | tr -d '"') && \
	export AWS_ACCESS_KEY_ID=$$(ansible-vault decrypt --output=- ansible/group_vars/all/vault.yml $(VAULT_FLAGS_ROOT) | grep vault_aws_access_key_id | awk '{print $$2}' | tr -d '"') && \
	export AWS_SECRET_ACCESS_KEY=$$(ansible-vault decrypt --output=- ansible/group_vars/all/vault.yml $(VAULT_FLAGS_ROOT) | grep vault_aws_secret_access_key | awk '{print $$2}' | tr -d '"') && \
	terraform -chdir=terraform plan

terraform-apply-vault:
	@export TF_VAR_yc_token=$$(ansible-vault decrypt --output=- ansible/group_vars/all/vault.yml $(VAULT_FLAGS_ROOT) | grep vault_yc_token | awk '{print $$2}' | tr -d '"') && \
	export TF_VAR_yc_cloud_id=$$(ansible-vault decrypt --output=- ansible/group_vars/all/vault.yml $(VAULT_FLAGS_ROOT) | grep vault_yc_cloud_id | awk '{print $$2}' | tr -d '"') && \
	export TF_VAR_yc_folder_id=$$(ansible-vault decrypt --output=- ansible/group_vars/all/vault.yml $(VAULT_FLAGS_ROOT) | grep vault_yc_folder_id | awk '{print $$2}' | tr -d '"') && \
	export AWS_ACCESS_KEY_ID=$$(ansible-vault decrypt --output=- ansible/group_vars/all/vault.yml $(VAULT_FLAGS_ROOT) | grep vault_aws_access_key_id | awk '{print $$2}' | tr -d '"') && \
	export AWS_SECRET_ACCESS_KEY=$$(ansible-vault decrypt --output=- ansible/group_vars/all/vault.yml $(VAULT_FLAGS_ROOT) | grep vault_aws_secret_access_key | awk '{print $$2}' | tr -d '"') && \
	terraform -chdir=terraform apply

terraform-destroy-vault:
	@export TF_VAR_yc_token=$$(ansible-vault decrypt --output=- ansible/group_vars/all/vault.yml $(VAULT_FLAGS_ROOT) | grep vault_yc_token | awk '{print $$2}' | tr -d '"') && \
	export TF_VAR_yc_cloud_id=$$(ansible-vault decrypt --output=- ansible/group_vars/all/vault.yml $(VAULT_FLAGS_ROOT) | grep vault_yc_cloud_id | awk '{print $$2}' | tr -d '"') && \
	export TF_VAR_yc_folder_id=$$(ansible-vault decrypt --output=- ansible/group_vars/all/vault.yml $(VAULT_FLAGS_ROOT) | grep vault_yc_folder_id | awk '{print $$2}' | tr -d '"') && \
	export AWS_ACCESS_KEY_ID=$$(ansible-vault decrypt --output=- ansible/group_vars/all/vault.yml $(VAULT_FLAGS_ROOT) | grep vault_aws_access_key_id | awk '{print $$2}' | tr -d '"') && \
	export AWS_SECRET_ACCESS_KEY=$$(ansible-vault decrypt --output=- ansible/group_vars/all/vault.yml $(VAULT_FLAGS_ROOT) | grep vault_aws_secret_access_key | awk '{print $$2}' | tr -d '"') && \
	terraform -chdir=terraform destroy

terraform-import-dns:
	@export TF_VAR_yc_token=$$(ansible-vault decrypt --output=- ansible/group_vars/all/vault.yml $(VAULT_FLAGS_ROOT) | grep vault_yc_token | awk '{print $$2}' | tr -d '"') && \
	export TF_VAR_yc_cloud_id=$$(ansible-vault decrypt --output=- ansible/group_vars/all/vault.yml $(VAULT_FLAGS_ROOT) | grep vault_yc_cloud_id | awk '{print $$2}' | tr -d '"') && \
	export TF_VAR_yc_folder_id=$$(ansible-vault decrypt --output=- ansible/group_vars/all/vault.yml $(VAULT_FLAGS_ROOT) | grep vault_yc_folder_id | awk '{print $$2}' | tr -d '"') && \
	export AWS_ACCESS_KEY_ID=$$(ansible-vault decrypt --output=- ansible/group_vars/all/vault.yml $(VAULT_FLAGS_ROOT) | grep vault_aws_access_key_id | awk '{print $$2}' | tr -d '"') && \
	export AWS_SECRET_ACCESS_KEY=$$(ansible-vault decrypt --output=- ansible/group_vars/all/vault.yml $(VAULT_FLAGS_ROOT) | grep vault_aws_secret_access_key | awk '{print $$2}' | tr -d '"') && \
	terraform -chdir=terraform import yandex_dns_recordset.a_record dnsd98oc0ilc5s1f69bj/magical-lovelace.ru./A && \
	terraform -chdir=terraform import yandex_dns_recordset.www_record dnsd98oc0ilc5s1f69bj/www.magical-lovelace.ru./A


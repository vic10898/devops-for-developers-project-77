export PATH := $(HOME)/Library/Python/3.13/bin:$(PATH)
VAULT_FLAGS := --vault-password-file .vault-password

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

terraform-validate:
	terraform -chdir=terraform validate

terraform-fmt:
	terraform -chdir=terraform fmt

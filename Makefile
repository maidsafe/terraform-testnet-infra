SHELL := /bin/bash

.ONESHELL:
opensearch-dev:
	cd opensearch
	terraform workspace select dev
	terraform init
	terraform apply -auto-approve -var-file=secrets.tfvars

.ONESHELL:
clean-opensearch-dev:
	cd opensearch
	terraform workspace select dev
	terraform init
	terraform destroy -auto-approve -var-file=secrets.tfvars

.ONESHELL:
networking-dev:
	cd networking
	terraform workspace select dev
	terraform init
	terraform apply -auto-approve

.ONESHELL:
clean-networking-dev:
	cd networking
	terraform workspace select dev
	terraform init
	terraform destroy -auto-approve

.ONESHELL:
services-dev:
	cd networking
	data_prepper_config_efs_id=$$(terraform output -raw data_prepper_config_efs_id | xargs)
	data_prepper_target_group_arn=$$(terraform output -raw data_prepper_target_group_arn | xargs)
	public_subnet_ids=$$(terraform output -json public_subnet_ids)
	testnet_infra_security_group_id=$$(terraform output -raw testnet_infra_security_group_id | xargs)
	cd ..
	cd services
	terraform workspace select dev
	terraform init
	terraform apply -auto-approve \
		-var data_prepper_config_efs_id=$$data_prepper_config_efs_id \
		-var data_prepper_target_group_arn=$$data_prepper_target_group_arn \
		-var "public_subnet_ids=$$public_subnet_ids" \
		-var testnet_infra_security_group_id=$$testnet_infra_security_group_id

.ONESHELL:
clean-services-dev:
	cd networking
	data_prepper_config_efs_id=$$(terraform output -raw data_prepper_config_efs_id | xargs)
	data_prepper_target_group_arn=$$(terraform output -raw data_prepper_target_group_arn | xargs)
	public_subnet_ids=$$(terraform output -json public_subnet_ids)
	testnet_infra_security_group_id=$$(terraform output -raw testnet_infra_security_group_id | xargs)
	cd ..
	cd services
	terraform workspace select dev
	terraform init
	terraform destroy -auto-approve \
		-var data_prepper_config_efs_id=$$data_prepper_config_efs_id \
		-var data_prepper_target_group_arn=$$data_prepper_target_group_arn \
		-var "public_subnet_ids=$$public_subnet_ids" \
		-var testnet_infra_security_group_id=$$testnet_infra_security_group_id

.ONESHELL:
clean-dev: clean-services-dev clean-networking-dev clean-opensearch-dev

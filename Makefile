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
	telemetry_collector_config_efs_id=$$(terraform output -raw telemetry_collector_config_efs_id | xargs)
	telemetry_collector_target_group_arn=$$(terraform output -raw telemetry_collector_target_group_arn | xargs)
	public_subnet_ids=$$(terraform output -json public_subnet_ids)
	telemetry_collector_security_group_id=$$(terraform output -raw telemetry_collector_security_group_id | xargs)
	data_prepper_security_group_id=$$(terraform output -raw data_prepper_security_group_id | xargs)
	service_registry_arn=$$(terraform output -raw service_registry_arn | xargs)
	cd ..
	cd services
	terraform workspace select dev
	terraform init
	terraform apply -auto-approve \
		-var data_prepper_config_efs_id=$$data_prepper_config_efs_id \
		-var telemetry_collector_config_efs_id=$$telemetry_collector_config_efs_id \
		-var telemetry_collector_target_group_arn=$$telemetry_collector_target_group_arn \
		-var "public_subnet_ids=$$public_subnet_ids" \
		-var telemetry_collector_security_group_id=$$telemetry_collector_security_group_id \
		-var data_prepper_security_group_id=$$data_prepper_security_group_id \
		-var service_registry_arn=$$service_registry_arn

.ONESHELL:
clean-services-dev:
	cd networking
	data_prepper_config_efs_id=$$(terraform output -raw data_prepper_config_efs_id | xargs)
	telemetry_collector_config_efs_id=$$(terraform output -raw telemetry_collector_config_efs_id | xargs)
	telemetry_collector_target_group_arn=$$(terraform output -raw telemetry_collector_target_group_arn | xargs)
	public_subnet_ids=$$(terraform output -json public_subnet_ids)
	telemetry_collector_security_group_id=$$(terraform output -raw telemetry_collector_security_group_id | xargs)
	data_prepper_security_group_id=$$(terraform output -raw data_prepper_security_group_id | xargs)
	service_registry_arn=$$(terraform output -raw service_registry_arn | xargs)
	cd ..
	cd services
	terraform workspace select dev
	terraform init
	terraform destroy -auto-approve \
		-var data_prepper_config_efs_id=$$data_prepper_config_efs_id \
		-var telemetry_collector_config_efs_id=$$telemetry_collector_config_efs_id \
		-var telemetry_collector_target_group_arn=$$telemetry_collector_target_group_arn \
		-var "public_subnet_ids=$$public_subnet_ids" \
		-var telemetry_collector_security_group_id=$$telemetry_collector_security_group_id \
		-var data_prepper_security_group_id=$$data_prepper_security_group_id \
		-var service_registry_arn=$$service_registry_arn

.ONESHELL:
clean-dev: clean-services-dev clean-networking-dev clean-opensearch-dev

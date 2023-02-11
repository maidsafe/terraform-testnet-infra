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
dns-dev:
	cd networking
	vpc_id=$$(terraform output -raw vpc_id | xargs)
	hosted_zone_id=$$(terraform output -raw hosted_zone_id | xargs)
	cd ..
	echo "Getting name servers for the dev-testnet-infra.local private DNS zone..."
	name_servers=($$(aws route53 list-resource-record-sets \
		--hosted-zone-id $$hosted_zone_id | \
		jq -r '.ResourceRecordSets[] | select(.Type == "NS") | .ResourceRecords[].Value'))
	echo "Looking up name server IPs..."
	ips="AmazonProvidedDNS"
	for i in 0 1 2; do
		ns=$${name_servers[$$i]}
		ip=$$(nslookup $$ns | awk 'NR==6 {print $$2; exit}')
		ips="$$ips $$ip"
	done
	echo "Done"
	ips=$$(echo -n $$ips | tr ' ' ',')
	echo -n "Creating DHCP options set..."
	dhcp_options_set_id=$$(aws ec2 create-dhcp-options \
		--dhcp-configurations "Key=domain-name,Values=dev-testnet-infra.local" "Key=domain-name-servers,Values=$$ips" | \
		jq -r '.DhcpOptions.DhcpOptionsId')
	aws ec2 associate-dhcp-options --dhcp-options-id $$dhcp_options_set_id --vpc-id $$vpc_id
	echo "Done"

.ONESHELL:
services-dev:
	cd networking
	data_prepper_config_efs_id=$$(terraform output -raw data_prepper_config_efs_id | xargs)
	telemetry_collector_config_efs_id=$$(terraform output -raw telemetry_collector_config_efs_id | xargs)
	telemetry_collector_target_group_arn=$$(terraform output -raw telemetry_collector_target_group_arn | xargs)
	public_subnet_ids=$$(terraform output -json public_subnet_ids)
	telemetry_collector_security_group_id=$$(terraform output -raw telemetry_collector_security_group_id | xargs)
	data_prepper_security_group_id=$$(terraform output -raw data_prepper_security_group_id | xargs)
	data_prepper_service_registry_arn=$$(terraform output -raw data_prepper_service_registry_arn | xargs)
	telemetry_collector_service_registry_arn=$$(terraform output -raw telemetry_collector_service_registry_arn | xargs)
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
		-var data_prepper_service_registry_arn=$$data_prepper_service_registry_arn \
		-var telemetry_collector_service_registry_arn=$$telemetry_collector_service_registry_arn

.ONESHELL:
clean-services-dev:
	cd networking
	data_prepper_config_efs_id=$$(terraform output -raw data_prepper_config_efs_id | xargs)
	telemetry_collector_config_efs_id=$$(terraform output -raw telemetry_collector_config_efs_id | xargs)
	telemetry_collector_target_group_arn=$$(terraform output -raw telemetry_collector_target_group_arn | xargs)
	public_subnet_ids=$$(terraform output -json public_subnet_ids)
	telemetry_collector_security_group_id=$$(terraform output -raw telemetry_collector_security_group_id | xargs)
	data_prepper_security_group_id=$$(terraform output -raw data_prepper_security_group_id | xargs)
	data_prepper_service_registry_arn=$$(terraform output -raw data_prepper_service_registry_arn | xargs)
	telemetry_collector_service_registry_arn=$$(terraform output -raw telemetry_collector_service_registry_arn | xargs)
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
		-var data_prepper_service_registry_arn=$$data_prepper_service_registry_arn \
		-var telemetry_collector_service_registry_arn=$$telemetry_collector_service_registry_arn

.ONESHELL:
clean-dev: clean-services-dev clean-networking-dev clean-opensearch-dev

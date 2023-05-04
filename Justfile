#!/usr/bin/env just --justfile
set dotenv-load := true

init env module:
  #!/usr/bin/env bash
  cd {{module}}
  terraform init \
    -backend-config="bucket=$TERRAFORM_STATE_BUCKET_NAME" \
    -backend-config="region=$AWS_DEFAULT_REGION"
  terraform workspace list | grep -q "{{env}}"
  if [ $? -eq 0 ]; then
    echo "Workspace '{{env}}' already exists"
  else
    echo "Creating new Terraform workspace {{env}}"
    terraform workspace new {{env}}
  fi

  key_name="{{env}}-testnet-infra"
  if ! aws ec2 describe-key-pairs --key-names "$key_name" > /dev/null 2>&1; then
    pub_key=$(cat $SSH_PUBLIC_KEY_PATH | base64 -w0 | xargs)
    echo "Creating new key pair for the testnet infra..."
    aws ec2 import-key-pair \
      --key-name $key_name --public-key-material $pub_key
  fi

networking env:
  #!/usr/bin/env bash
  set -e
  just init "{{env}}" "networking"
  cd networking
  terraform workspace select {{env}}
  terraform apply -auto-approve

opensearch env:
  #!/usr/bin/env bash
  set -e
  just init "{{env}}" "opensearch"
  cd opensearch
  terraform workspace select {{env}}
  terraform apply -auto-approve -var-file=secrets.tfvars

opensearch-networking env:
  #!/usr/bin/env bash
  set -e
  just init "{{env}}" "networking"
  cd networking
  terraform workspace select {{env}}
  testnet_infra_vpc_id=$(terraform output -raw vpc_id | xargs)
  testnet_infra_security_group_id=$(terraform output -raw testnet_infra_security_group_id | xargs)
  testnet_infra_public_subnet_ids=$(terraform output -json public_subnet_ids)
  cd ..

  just init "{{env}}" "opensearch-networking"
  cd opensearch-networking
  terraform workspace select {{env}}
  terraform apply -auto-approve \
    -var testnet_infra_vpc_id=$testnet_infra_vpc_id \
    -var testnet_infra_security_group_id=$testnet_infra_security_group_id \
    -var "testnet_infra_public_subnet_ids=$testnet_infra_public_subnet_ids"

opensearch-services env:
  #!/usr/bin/env bash
  set -e
  cd networking
  terraform workspace select {{env}}
  testnet_infra_public_subnet_ids=$(terraform output -json public_subnet_ids)
  cd ..

  cd opensearch-networking
  terraform workspace select {{env}}
  data_prepper_config_efs_id=$(terraform output -raw data_prepper_config_efs_id | xargs)
  data_prepper_security_group_id=$(terraform output -raw data_prepper_security_group_id | xargs)
  data_prepper_service_registry_arn=$(terraform output -raw data_prepper_service_registry_arn | xargs)
  telemetry_collector_config_efs_id=$(terraform output -raw telemetry_collector_config_efs_id | xargs)
  telemetry_collector_target_group_arn=$(terraform output -raw telemetry_collector_target_group_arn | xargs)
  telemetry_collector_security_group_id=$(terraform output -raw telemetry_collector_security_group_id | xargs)
  telemetry_collector_service_registry_arn=$(terraform output -raw telemetry_collector_service_registry_arn | xargs)
  cd ..

  just init "{{env}}" "opensearch-services"
  cd opensearch-services
  terraform workspace select {{env}}
  terraform apply -auto-approve \
    -var data_prepper_config_efs_id=$data_prepper_config_efs_id \
    -var data_prepper_security_group_id=$data_prepper_security_group_id \
    -var data_prepper_service_registry_arn=$data_prepper_service_registry_arn \
    -var telemetry_collector_config_efs_id=$telemetry_collector_config_efs_id \
    -var telemetry_collector_target_group_arn=$telemetry_collector_target_group_arn \
    -var telemetry_collector_security_group_id=$telemetry_collector_security_group_id \
    -var telemetry_collector_service_registry_arn=$telemetry_collector_service_registry_arn \
    -var "public_subnet_ids=$testnet_infra_public_subnet_ids"

opensearch-dns env:
  #!/usr/bin/env bash
  set -e
  cd networking
  vpc_id=$(terraform output -raw vpc_id | xargs)
  cd ..
  cd opensearch-networking
  hosted_zone_id=$(terraform output -raw hosted_zone_id | xargs)
  cd ..

  echo "Getting name servers for the {{env}}-testnet-infra.local private DNS zone..."
  name_servers=($(aws route53 list-resource-record-sets \
    --hosted-zone-id $hosted_zone_id | \
    jq -r '.ResourceRecordSets[] | select(.Type == "NS") | .ResourceRecords[].Value'))
  echo "Looking up name server IPs..."
  ips="AmazonProvidedDNS"
  for i in 0 1 2; do
    ns=${name_servers[$i]}
    ip=$(nslookup $ns | awk 'NR==6 {print $2; exit}')
    ips="$ips $ip"
  done
  echo "Done"

  ips=$(echo -n $ips | tr ' ' ',')
  echo -n "Creating DHCP options set..."
  dhcp_options_set_id=$(aws ec2 create-dhcp-options \
    --dhcp-configurations "Key=domain-name,Values={{env}}-testnet-infra.local" "Key=domain-name-servers,Values=$ips" | \
    jq -r '.DhcpOptions.DhcpOptionsId')
  aws ec2 associate-dhcp-options --dhcp-options-id $dhcp_options_set_id --vpc-id $vpc_id
  echo "Done"

clean-opensearch-services env:
  #!/usr/bin/env bash
  set -e

  cd networking
  terraform workspace select {{env}}
  testnet_infra_public_subnet_ids=$(terraform output -json public_subnet_ids)
  cd ..

  cd opensearch-networking
  terraform workspace select {{env}}
  data_prepper_config_efs_id=$(terraform output -raw data_prepper_config_efs_id | xargs)
  data_prepper_security_group_id=$(terraform output -raw data_prepper_security_group_id | xargs)
  data_prepper_service_registry_arn=$(terraform output -raw data_prepper_service_registry_arn | xargs)
  telemetry_collector_config_efs_id=$(terraform output -raw telemetry_collector_config_efs_id | xargs)
  telemetry_collector_target_group_arn=$(terraform output -raw telemetry_collector_target_group_arn | xargs)
  telemetry_collector_security_group_id=$(terraform output -raw telemetry_collector_security_group_id | xargs)
  telemetry_collector_service_registry_arn=$(terraform output -raw telemetry_collector_service_registry_arn | xargs)
  cd ..

  just init "{{env}}" "opensearch-services"
  cd opensearch-services
  terraform workspace select {{env}}
  terraform destroy -auto-approve \
    -var data_prepper_config_efs_id=$data_prepper_config_efs_id \
    -var data_prepper_security_group_id=$data_prepper_security_group_id \
    -var data_prepper_service_registry_arn=$data_prepper_service_registry_arn \
    -var telemetry_collector_config_efs_id=$telemetry_collector_config_efs_id \
    -var telemetry_collector_target_group_arn=$telemetry_collector_target_group_arn \
    -var telemetry_collector_security_group_id=$telemetry_collector_security_group_id \
    -var telemetry_collector_service_registry_arn=$telemetry_collector_service_registry_arn \
    -var "public_subnet_ids=$testnet_infra_public_subnet_ids"

clean-opensearch-networking env:
  #!/usr/bin/env bash
  set -e

  cd networking
  terraform workspace select {{env}}
  testnet_infra_vpc_id=$(terraform output -raw vpc_id | xargs)
  testnet_infra_security_group_id=$(terraform output -raw testnet_infra_security_group_id | xargs)
  testnet_infra_public_subnet_ids=$(terraform output -json public_subnet_ids)
  cd ..

  just init "{{env}}" "opensearch-networking"
  cd opensearch-networking
  terraform workspace select {{env}}
  terraform destroy -auto-approve \
    -var testnet_infra_vpc_id=$testnet_infra_vpc_id \
    -var testnet_infra_security_group_id=$testnet_infra_security_group_id \
    -var "testnet_infra_public_subnet_ids=$testnet_infra_public_subnet_ids"
  cd ..

clean-opensearch env:
  #!/usr/bin/env bash
  set -e
  just init "{{env}}" "opensearch"
  cd opensearch
  terraform workspace select {{env}}
  terraform destroy -auto-approve -var-file=secrets.tfvars

clean-opensearch-stack env:
  #!/usr/bin/env bash
  set -e
  just clean-opensearch-services "{{env}}"
  just clean-opensearch-networking "{{env}}"
  just clean-opensearch "{{env}}"

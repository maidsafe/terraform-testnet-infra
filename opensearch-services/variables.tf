variable "testnet_infra_ecs_cluster_name" {
  default = "testnet-infra"
  description = "The name of the testnet infra ECS cluster"
}

variable "ecs_testnet_infra_iam_role_arn" {
  default = "arn:aws:iam::389640522532:role/ecs_testnet_infra"
  description = "The ARN of the role for executing the Elastic-related services on ECS"
}

variable "data_prepper_config_efs_id" {
  description = "The ID of the EFS file system for the data prepper service"
}

variable "telemetry_collector_config_efs_id" {
  description = "The ID of the EFS file system for the telemetry collector service"
}

variable "telemetry_collector_target_group_arn" {
  description = "The ARN of the target group for the telemetry collector service"
}

variable "public_subnet_ids" {
  description = "The IDs of the public subnets in the VPC where the services will be deployed"
  type = list
}

variable "telemetry_collector_security_group_id" {
  description = "The ID of the security group for Telemetry Collector service"
}

variable "data_prepper_security_group_id" {
  description = "The ID of the security group for Data Prepper service"
}

variable "data_prepper_service_registry_arn" {
  description = "The ARN of the Data Prepper service registry for DNS usage in the VPC"
}

variable "telemetry_collector_service_registry_arn" {
  description = "The ARN of the Telemetry Collector service registry for DNS usage in the VPC"
}

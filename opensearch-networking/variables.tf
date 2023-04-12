variable "testnet_infra_lb_name" {
  default = "testnet-infra"
  description = "The name of the testnet infra load balancer"
}

variable "testnet_infra_vpc_id" {
  default = ""
  description = "ID of the testnet infra VPC. Should be provided as an output from the networking module."
}

variable "testnet_infra_security_group_id" {
  default = ""
  description = "ID of the testnet infra security group. Should be provided as an output from the networking module."
}

variable "testnet_infra_public_subnet_ids" {
  type = list
  description = "IDs of the testnet infra public subnets. Should be provided as an output from the networking module."
}

variable "telemetry_collector_security_group_name" {
  default = "telemetry_collector"
  description = "The name of the telemetry collector security group"
}

variable "data_prepper_security_group_name" {
  default = "data_prepper"
  description = "The name of the data prepper security group"
}

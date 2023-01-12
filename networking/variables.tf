variable "availability_zones" {
  default = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]
  description = "The availability zones to use"
}

variable "testnet_infra_lb_name" {
  default = "testnet-infra"
  description = "The name of the testnet infra load balancer"
}

variable "testnet_infra_vpc_name" {
  default = "testnet_infra"
  description = "The name of the testnet infra VPC"
}

variable "testnet_infra_security_group_name" {
  default = "testnet_infra"
  description = "The name of the testnet infra security group"
}
